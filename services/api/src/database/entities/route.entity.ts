/**
 * Route Entity
 *
 * Represents a shuttle route (Green Line, Yellow Line).
 */

import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('routes')
export class Route {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string; // 'Green Line', 'Yellow Line'

  @Column()
  color: string; // '#22c55e', '#eab308'

  @Column({ nullable: true })
  description: string;

  @Column({ type: 'jsonb', nullable: true })
  geojson: object; // Full route polyline as GeoJSON

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
