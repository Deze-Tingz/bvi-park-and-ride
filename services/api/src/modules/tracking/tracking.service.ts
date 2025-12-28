/**
 * Tracking Service
 *
 * Business logic for real-time tracking:
 * - Store and validate GPS updates
 * - Calculate ETAs
 * - Manage driver connections
 */

import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { Vehicle } from '../../database/entities/vehicle.entity';
import { LocationUpdateDto } from './dto/location-update.dto';

// In-memory store for active driver connections
// Maps socket ID to vehicle ID
const activeDrivers = new Map<string, { vehicleId: string; routeId: string }>();

@Injectable()
export class TrackingService {
  private readonly logger = new Logger('TrackingService');

  constructor(
    @InjectRepository(Vehicle)
    private readonly vehicleRepository: Repository<Vehicle>,
  ) {}

  /**
   * Register a driver's WebSocket connection
   */
  async registerDriver(
    socketId: string,
    vehicleId: string,
    routeId: string,
  ) {
    activeDrivers.set(socketId, { vehicleId, routeId });

    // Update vehicle status
    await this.vehicleRepository.update(vehicleId, {
      status: 'in_service',
      currentRouteId: routeId,
    });
  }

  /**
   * Handle driver disconnection
   */
  async handleDriverDisconnect(socketId: string) {
    const driver = activeDrivers.get(socketId);

    if (driver) {
      // Mark vehicle as offline
      await this.vehicleRepository.update(driver.vehicleId, {
        status: 'available',
      });

      activeDrivers.delete(socketId);
      this.logger.log(`Driver disconnected: vehicle=${driver.vehicleId}`);
    }
  }

  /**
   * Update vehicle location
   */
  async updateLocation(socketId: string, data: LocationUpdateDto) {
    const driver = activeDrivers.get(socketId);

    if (!driver) {
      throw new Error('Driver not registered');
    }

    // Validate GPS data (basic validation)
    if (!this.isValidGps(data.latitude, data.longitude)) {
      throw new Error('Invalid GPS coordinates');
    }

    // Update vehicle location in database
    await this.vehicleRepository.update(data.vehicleId, {
      latitude: data.latitude,
      longitude: data.longitude,
      speed: data.speed,
      heading: data.heading,
      lastLocationUpdate: new Date(),
    });

    // Calculate ETA to next stop (simplified)
    // In a real app, you'd use road network distance
    const nextStopEta = this.calculateNextStopEta(data);

    return {
      success: true,
      routeId: driver.routeId,
      status: 'on_route',
      nextStopId: 'stop-003', // TODO: Calculate actual next stop
      nextStopEta: nextStopEta,
    };
  }

  /**
   * Handle stop arrival
   */
  async handleStopArrival(vehicleId: string, stopId: string) {
    // Find the vehicle to get route info
    const vehicle = await this.vehicleRepository.findOne({
      where: { id: vehicleId },
    });

    if (!vehicle) {
      return { routeId: null };
    }

    // TODO: Log stop event to database for analytics

    return {
      routeId: vehicle.currentRouteId,
      stopName: 'Stop Name', // TODO: Look up actual stop name
    };
  }

  /**
   * Validate GPS coordinates
   */
  private isValidGps(lat: number, lng: number): boolean {
    return (
      typeof lat === 'number' &&
      typeof lng === 'number' &&
      lat >= -90 &&
      lat <= 90 &&
      lng >= -180 &&
      lng <= 180
    );
  }

  /**
   * Calculate ETA to next stop (simplified)
   * Returns seconds until arrival
   */
  private calculateNextStopEta(data: LocationUpdateDto): number {
    // Simplified calculation based on speed
    // In a real app, use road network routing
    const averageDistanceToNextStop = 500; // meters (placeholder)
    const speedMps = (data.speed || 20) * 0.277778; // km/h to m/s

    if (speedMps < 1) {
      return 300; // 5 minutes if stopped
    }

    return Math.round(averageDistanceToNextStop / speedMps);
  }

  /**
   * Get all active vehicles
   */
  async getActiveVehicles() {
    return this.vehicleRepository.find({
      where: { status: 'in_service' },
    });
  }
}
