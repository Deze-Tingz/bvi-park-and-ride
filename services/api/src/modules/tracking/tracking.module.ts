/**
 * Tracking Module
 *
 * Handles real-time GPS tracking via WebSockets.
 * This is the CORE of the Uber-like experience.
 *
 * WHY THIS MODULE EXISTS:
 * Real-time tracking is what makes this app feel like Uber.
 * Drivers broadcast their GPS position, and riders see smooth
 * vehicle animations on the map. This module manages all
 * WebSocket connections and message routing.
 */

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { TrackingGateway } from './tracking.gateway';
import { TrackingService } from './tracking.service';
import { Vehicle } from '../../database/entities/vehicle.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Vehicle])],
  providers: [TrackingGateway, TrackingService],
  exports: [TrackingService],
})
export class TrackingModule {}
