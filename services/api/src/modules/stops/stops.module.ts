/**
 * Stops Module
 * Manages shuttle stop locations
 */
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Stop } from '../../database/entities/stop.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Stop])],
  controllers: [],
  providers: [],
  exports: [],
})
export class StopsModule {}
