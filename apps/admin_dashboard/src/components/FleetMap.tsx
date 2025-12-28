'use client';

import { useEffect, useRef, useState } from 'react';
import mapboxgl from 'mapbox-gl';
import 'mapbox-gl/dist/mapbox-gl.css';

interface VehicleData {
  id: string;
  plateNumber: string;
  routeId: string;
  routeName: string;
  status: 'active' | 'full' | 'out_of_service' | 'offline';
  latitude: number;
  longitude: number;
  speed: number;
  heading: number;
  driverName: string;
  currentStop: string;
  nextStop: string;
  lastUpdate: Date;
}

interface FleetMapProps {
  vehicles: VehicleData[];
}

// BVI stops data
const stops = [
  { id: 'stop-001', name: 'Festival Grounds Parking Lot', lat: 18.4285, lng: -64.6189 },
  { id: 'stop-002', name: 'CCT / Eureka Parking', lat: 18.4278, lng: -64.6201 },
  { id: 'stop-003', name: "Bobby's Supermarket", lat: 18.4290, lng: -64.6175 },
  { id: 'stop-004', name: 'Mill Mall', lat: 18.4275, lng: -64.6165 },
  { id: 'stop-005', name: 'Banco Popular', lat: 18.4268, lng: -64.6155 },
  { id: 'stop-006', name: 'Tortola Pier Park', lat: 18.4255, lng: -64.6145 },
  { id: 'stop-007', name: 'Ferry Terminal', lat: 18.4248, lng: -64.6135 },
  { id: 'stop-008', name: 'RiteWay Road Reef', lat: 18.4295, lng: -64.6220 },
  { id: 'stop-009', name: 'Slaney Hill Roundabout', lat: 18.4310, lng: -64.6245 },
  { id: 'stop-010', name: 'Dr. D. Orlando Smith Hospital', lat: 18.4325, lng: -64.6260 },
];

const statusColors: Record<string, string> = {
  active: '#22c55e',
  full: '#f97316',
  out_of_service: '#ef4444',
  offline: '#6b7280',
};

export default function FleetMap({ vehicles }: FleetMapProps) {
  const mapContainer = useRef<HTMLDivElement>(null);
  const map = useRef<mapboxgl.Map | null>(null);
  const markersRef = useRef<Map<string, mapboxgl.Marker>>(new Map());
  const [mapLoaded, setMapLoaded] = useState(false);

  // Initialize map
  useEffect(() => {
    if (!mapContainer.current || map.current) return;

    // Use public token or placeholder
    mapboxgl.accessToken = process.env.NEXT_PUBLIC_MAPBOX_TOKEN || 'pk.placeholder';

    try {
      map.current = new mapboxgl.Map({
        container: mapContainer.current,
        style: 'mapbox://styles/mapbox/dark-v11',
        center: [-64.6185, 18.4286], // Road Town, Tortola
        zoom: 14,
      });

      map.current.on('load', () => {
        setMapLoaded(true);

        // Add stop markers
        stops.forEach(stop => {
          const el = document.createElement('div');
          el.className = 'stop-marker';
          el.style.cssText = `
            width: 12px;
            height: 12px;
            background-color: #60a5fa;
            border: 2px solid white;
            border-radius: 50%;
          `;

          new mapboxgl.Marker(el)
            .setLngLat([stop.lng, stop.lat])
            .setPopup(new mapboxgl.Popup().setHTML(`<strong>${stop.name}</strong>`))
            .addTo(map.current!);
        });
      });

      map.current.addControl(new mapboxgl.NavigationControl(), 'top-right');
    } catch (error) {
      console.error('Error initializing map:', error);
    }

    return () => {
      if (map.current) {
        map.current.remove();
        map.current = null;
      }
    };
  }, []);

  // Update vehicle markers
  useEffect(() => {
    if (!map.current || !mapLoaded) return;

    // Update or create markers for each vehicle
    vehicles.forEach(vehicle => {
      const existingMarker = markersRef.current.get(vehicle.id);

      if (existingMarker) {
        // Update existing marker position
        existingMarker.setLngLat([vehicle.longitude, vehicle.latitude]);

        // Update marker color based on status
        const el = existingMarker.getElement();
        const innerEl = el.querySelector('.vehicle-inner') as HTMLElement;
        if (innerEl) {
          innerEl.style.backgroundColor = statusColors[vehicle.status];
        }
      } else {
        // Create new marker
        const el = document.createElement('div');
        el.className = 'vehicle-marker';
        el.style.cssText = `
          width: 32px;
          height: 32px;
          display: flex;
          align-items: center;
          justify-content: center;
        `;

        const inner = document.createElement('div');
        inner.className = 'vehicle-inner';
        inner.style.cssText = `
          width: 24px;
          height: 24px;
          background-color: ${statusColors[vehicle.status]};
          border: 3px solid white;
          border-radius: 50%;
          box-shadow: 0 2px 4px rgba(0,0,0,0.3);
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 12px;
          color: white;
        `;
        inner.innerHTML = '🚐';
        el.appendChild(inner);

        const popup = new mapboxgl.Popup({ offset: 25 }).setHTML(`
          <div style="color: #1f2937;">
            <strong>${vehicle.plateNumber}</strong><br>
            <span style="color: #6b7280;">${vehicle.routeName}</span><br>
            <span style="color: #6b7280;">Driver: ${vehicle.driverName}</span><br>
            <span style="color: #6b7280;">Speed: ${vehicle.speed} km/h</span>
          </div>
        `);

        const marker = new mapboxgl.Marker(el)
          .setLngLat([vehicle.longitude, vehicle.latitude])
          .setPopup(popup)
          .addTo(map.current!);

        markersRef.current.set(vehicle.id, marker);
      }
    });

    // Remove markers for vehicles no longer in the list
    markersRef.current.forEach((marker, id) => {
      if (!vehicles.find(v => v.id === id)) {
        marker.remove();
        markersRef.current.delete(id);
      }
    });
  }, [vehicles, mapLoaded]);

  return (
    <div ref={mapContainer} className="w-full h-full">
      {!mapLoaded && (
        <div className="absolute inset-0 flex items-center justify-center bg-gray-800">
          <div className="text-gray-400">Loading map...</div>
        </div>
      )}
    </div>
  );
}
