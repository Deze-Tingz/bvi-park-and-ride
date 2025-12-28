/**
 * Vehicles Module
 * CRUD operations for shuttle vehicles
 */
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Vehicle } from '../../database/entities/vehicle.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Vehicle])],
  controllers: [],
  providers: [],
  exports: [],
})
export class VehiclesModule {}
