/**
 * User Entity
 *
 * Represents a user account (rider, driver, or admin).
 * This entity maps to the 'users' table in PostgreSQL.
 *
 * LEARNING NOTE:
 * TypeORM entities define your database schema. Each property
 * with a @Column decorator becomes a column in the database.
 */

import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  email: string;

  @Column({ name: 'password_hash' })
  passwordHash: string;

  @Column({ default: 'rider' })
  role: string; // 'rider' | 'driver' | 'admin'

  @Column({ name: 'fcm_token', nullable: true })
  fcmToken: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
