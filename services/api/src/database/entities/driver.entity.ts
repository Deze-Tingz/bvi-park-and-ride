/**
 * Driver Entity
 *
 * Represents a shuttle driver.
 * Linked to a User account via userId.
 */

import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('drivers')
export class Driver {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @Column()
  name: string;

  @Column({ unique: true })
  email: string;

  @Column({ nullable: true })
  phone: string;

  @Column({ name: 'license_number', nullable: true })
  licenseNumber: string;

  @Column({ default: 'offline' })
  status: string; // 'offline' | 'online' | 'on_route'

  @Column({ name: 'assigned_vehicle_id', nullable: true })
  assignedVehicleId: string;

  @Column({ name: 'assigned_route_id', nullable: true })
  assignedRouteId: string;

  @Column({ name: 'fcm_token', nullable: true })
  fcmToken: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
