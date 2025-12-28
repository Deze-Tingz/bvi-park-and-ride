/**
 * Routes Module
 * Manages Green/Yellow line routes
 */
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Route } from '../../database/entities/route.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Route])],
  controllers: [],
  providers: [],
  exports: [],
})
export class RoutesModule {}
