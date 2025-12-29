/**
 * BVI Park & Ride Stop Geocoding Pipeline
 *
 * This script:
 * 1. Reads stop names from data/stops.json
 * 2. Geocodes each stop using Mapbox API (with Nominatim fallback)
 * 3. Assigns line colors based on routes.geojson
 * 4. Outputs data/stops.geojson and scripts/needs_manual_review.json
 *
 * Usage: node scripts/geocode-stops.js
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

// Configuration
const MAPBOX_TOKEN = 'pk.eyJ1IjoiZGV6ZXRpbmd6IiwiYSI6ImNtaW42anV4azIwM3ozY3B3eGpxdWlxenYifQ.Y5YI-07V6nwBUCPxF7qH3w';
const ROAD_TOWN_CENTER = { lng: -64.6180, lat: 18.4280 }; // Proximity bias
const CONFIDENCE_THRESHOLD = 0.6;
const CACHE_FILE = path.join(__dirname, 'geocode-cache.json');

// Load or initialize cache
let geocodeCache = {};
if (fs.existsSync(CACHE_FILE)) {
  try {
    geocodeCache = JSON.parse(fs.readFileSync(CACHE_FILE, 'utf8'));
    console.log(`Loaded ${Object.keys(geocodeCache).length} cached geocode results`);
  } catch (e) {
    console.log('Starting with empty cache');
  }
}

function saveCache() {
  fs.writeFileSync(CACHE_FILE, JSON.stringify(geocodeCache, null, 2));
}

// HTTP GET helper
function httpGet(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(new Error(`Failed to parse response: ${data.substring(0, 200)}`));
        }
      });
    }).on('error', reject);
  });
}

// Mapbox Geocoding API
async function geocodeWithMapbox(stopName) {
  const query = encodeURIComponent(`${stopName}, Road Town, Tortola, British Virgin Islands`);
  const url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${query}.json?` +
    `access_token=${MAPBOX_TOKEN}&` +
    `proximity=${ROAD_TOWN_CENTER.lng},${ROAD_TOWN_CENTER.lat}&` +
    `types=poi,address,place&` +
    `limit=1`;

  try {
    const data = await httpGet(url);

    if (data.features && data.features.length > 0) {
      const feature = data.features[0];
      const [lng, lat] = feature.center;

      // Calculate confidence based on relevance and distance from Road Town
      const relevance = feature.relevance || 0;
      const distance = Math.sqrt(
        Math.pow(lng - ROAD_TOWN_CENTER.lng, 2) +
        Math.pow(lat - ROAD_TOWN_CENTER.lat, 2)
      );
      // Penalize if too far from Road Town (> 0.05 degrees ~ 5km)
      const distancePenalty = distance > 0.05 ? 0.3 : 0;
      const confidence = Math.max(0, relevance - distancePenalty);

      return {
        source: 'mapbox',
        lng,
        lat,
        confidence,
        placeName: feature.place_name,
        matchType: feature.place_type?.[0] || 'unknown'
      };
    }
    return null;
  } catch (e) {
    console.error(`Mapbox geocoding failed for "${stopName}": ${e.message}`);
    return null;
  }
}

// Nominatim (OpenStreetMap) fallback
async function geocodeWithNominatim(stopName) {
  const query = encodeURIComponent(`${stopName}, Road Town, Tortola`);
  const url = `https://nominatim.openstreetmap.org/search?q=${query}&format=json&limit=1&countrycodes=vg`;

  try {
    // Add delay to respect Nominatim rate limits
    await new Promise(r => setTimeout(r, 1100));

    const data = await httpGet(url);

    if (data && data.length > 0) {
      const result = data[0];
      const lat = parseFloat(result.lat);
      const lng = parseFloat(result.lon);

      // Calculate confidence based on importance and distance
      const importance = parseFloat(result.importance) || 0;
      const distance = Math.sqrt(
        Math.pow(lng - ROAD_TOWN_CENTER.lng, 2) +
        Math.pow(lat - ROAD_TOWN_CENTER.lat, 2)
      );
      const distancePenalty = distance > 0.05 ? 0.3 : 0;
      const confidence = Math.max(0, importance - distancePenalty);

      return {
        source: 'nominatim',
        lng,
        lat,
        confidence,
        placeName: result.display_name,
        matchType: result.type || 'unknown'
      };
    }
    return null;
  } catch (e) {
    console.error(`Nominatim geocoding failed for "${stopName}": ${e.message}`);
    return null;
  }
}

// Main geocoding function with tiered fallback
async function geocodeStop(stopName, existingCoords) {
  // Check cache first
  const cacheKey = stopName.toLowerCase().trim();
  if (geocodeCache[cacheKey] && geocodeCache[cacheKey].confidence >= CONFIDENCE_THRESHOLD) {
    console.log(`  [CACHE] ${stopName}`);
    return geocodeCache[cacheKey];
  }

  // Try Mapbox first
  console.log(`  [MAPBOX] Geocoding: ${stopName}`);
  let result = await geocodeWithMapbox(stopName);

  if (result && result.confidence >= CONFIDENCE_THRESHOLD) {
    geocodeCache[cacheKey] = result;
    saveCache();
    return result;
  }

  // Try Nominatim as fallback
  console.log(`  [NOMINATIM] Fallback for: ${stopName}`);
  const nominatimResult = await geocodeWithNominatim(stopName);

  if (nominatimResult) {
    if (!result || nominatimResult.confidence > result.confidence) {
      result = nominatimResult;
    }
  }

  // If still no good result, use existing coordinates with low confidence
  if (!result || result.confidence < CONFIDENCE_THRESHOLD) {
    if (existingCoords) {
      result = {
        source: 'existing',
        lng: existingCoords.longitude,
        lat: existingCoords.latitude,
        confidence: 0.3,
        placeName: `${stopName} (existing coords)`,
        matchType: 'fallback',
        needsReview: true
      };
    }
  }

  if (result) {
    geocodeCache[cacheKey] = result;
    saveCache();
  }

  return result;
}

// Main execution
async function main() {
  console.log('=== BVI Park & Ride Stop Geocoding Pipeline ===\n');

  // Load source data
  const stopsPath = path.join(__dirname, '..', 'data', 'stops.json');
  const routesPath = path.join(__dirname, '..', 'data', 'routes.geojson');

  const stopsData = JSON.parse(fs.readFileSync(stopsPath, 'utf8'));
  const routesData = JSON.parse(fs.readFileSync(routesPath, 'utf8'));

  // Build stop-to-line mapping
  const stopLineMap = {};
  for (const route of routesData.features) {
    const lineName = route.properties.shortName; // "Green" or "Yellow"
    const color = route.properties.color;
    for (const stopId of route.properties.stopIds) {
      if (!stopLineMap[stopId]) {
        stopLineMap[stopId] = [];
      }
      stopLineMap[stopId].push({ name: lineName, color });
    }
  }

  // Process stops
  const features = [];
  const needsReview = [];
  let geocodedOk = 0;

  console.log(`Processing ${stopsData.stops.length} stops...\n`);

  for (const stop of stopsData.stops) {
    const geocodeResult = await geocodeStop(stop.name, {
      latitude: stop.latitude,
      longitude: stop.longitude
    });

    if (!geocodeResult) {
      console.log(`  [FAILED] ${stop.name}`);
      needsReview.push({
        stop_id: stop.id,
        name: stop.name,
        reason: 'Geocoding completely failed'
      });
      continue;
    }

    // Determine line assignment
    const lines = stopLineMap[stop.id] || [];
    let lineAssignment = 'Unknown';
    let lineColor = '#888888';

    if (lines.length === 1) {
      lineAssignment = lines[0].name;
      lineColor = lines[0].color;
    } else if (lines.length > 1) {
      // Stop is on multiple lines - use first one but mark as "Both"
      lineAssignment = 'Both';
      lineColor = '#6366f1'; // Purple for both
    }

    // Create GeoJSON feature
    const feature = {
      type: 'Feature',
      properties: {
        stop_id: stop.id,
        name: stop.name,
        shortName: stop.shortName,
        line: lineAssignment,
        lineColor: lineColor,
        type: stop.type,
        amenities: stop.amenities,
        isActive: stop.isActive,
        geocode_source: geocodeResult.source,
        geocode_confidence: Math.round(geocodeResult.confidence * 100) / 100
      },
      geometry: {
        type: 'Point',
        coordinates: [geocodeResult.lng, geocodeResult.lat]
      }
    };

    features.push(feature);

    if (geocodeResult.needsReview || geocodeResult.confidence < CONFIDENCE_THRESHOLD) {
      needsReview.push({
        stop_id: stop.id,
        name: stop.name,
        coordinates: [geocodeResult.lng, geocodeResult.lat],
        confidence: geocodeResult.confidence,
        source: geocodeResult.source,
        reason: 'Low confidence score'
      });
    } else {
      geocodedOk++;
    }

    const status = geocodeResult.confidence >= CONFIDENCE_THRESHOLD ? 'OK' : 'REVIEW';
    console.log(`  [${status}] ${stop.name} -> ${geocodeResult.source} (${Math.round(geocodeResult.confidence * 100)}%)`);
  }

  // Create GeoJSON output
  const geojson = {
    type: 'FeatureCollection',
    metadata: {
      version: '1.0.0',
      generatedAt: new Date().toISOString(),
      source: 'BVI Government Park & Ride Official Stop List',
      region: 'Road Town, Tortola, British Virgin Islands',
      totalStops: features.length,
      geocodedOk: geocodedOk,
      needsReview: needsReview.length
    },
    features: features
  };

  // Write outputs
  const outputPath = path.join(__dirname, '..', 'data', 'stops.geojson');
  fs.writeFileSync(outputPath, JSON.stringify(geojson, null, 2));
  console.log(`\nWrote ${outputPath}`);

  const reviewPath = path.join(__dirname, 'needs_manual_review.json');
  fs.writeFileSync(reviewPath, JSON.stringify(needsReview, null, 2));
  console.log(`Wrote ${reviewPath}`);

  // Print summary
  console.log('\n=== SUMMARY ===');
  console.log(`Total stops: ${stopsData.stops.length}`);
  console.log(`Geocoded OK: ${geocodedOk}`);
  console.log(`Needs review: ${needsReview.length}`);

  if (needsReview.length > 0) {
    console.log('\nStops needing manual review:');
    for (const item of needsReview) {
      console.log(`  - ${item.name}: ${item.reason}`);
    }
  }
}

main().catch(console.error);
