/**
 * Vehicle Entity
 *
 * Represents a shuttle vehicle in the fleet.
 */

import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('vehicles')
export class Vehicle {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column({ name: 'plate_number', unique: true })
  plateNumber: string;

  @Column({ name: 'vehicle_type', default: 'shuttle' })
  vehicleType: string; // 'shuttle' | 'bus'

  @Column({ default: 15 })
  capacity: number;

  @Column({ default: 'available' })
  status: string; // 'available' | 'in_service' | 'maintenance' | 'out_of_service'

  @Column({ name: 'current_driver_id', nullable: true })
  currentDriverId: string;

  @Column({ name: 'current_route_id', nullable: true })
  currentRouteId: string;

  // Current location (updated in real-time)
  @Column({ type: 'decimal', precision: 10, scale: 8, nullable: true })
  latitude: number;

  @Column({ type: 'decimal', precision: 11, scale: 8, nullable: true })
  longitude: number;

  @Column({ type: 'decimal', precision: 5, scale: 2, nullable: true })
  speed: number;

  @Column({ type: 'decimal', precision: 5, scale: 2, nullable: true })
  heading: number;

  @Column({ name: 'last_location_update', nullable: true })
  lastLocationUpdate: Date;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
