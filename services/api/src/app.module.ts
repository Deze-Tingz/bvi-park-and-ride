/**
 * BVI Park & Ride - Root Application Module
 *
 * This is the root module that imports all feature modules.
 * NestJS uses a modular architecture where each feature has its own module.
 *
 * MODULES OVERVIEW:
 * - AuthModule: Handles user registration, login, JWT tokens
 * - VehiclesModule: CRUD operations for shuttle vehicles
 * - RoutesModule: Manage Green/Yellow line routes
 * - StopsModule: Manage bus stops
 * - TrackingModule: Real-time GPS tracking via WebSockets
 * - EtaModule: Calculate estimated arrival times
 * - NotificationsModule: Push notifications to mobile apps
 * - AdminModule: Admin-only operations
 */

import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';

// Feature modules
import { AuthModule } from './modules/auth/auth.module';
import { VehiclesModule } from './modules/vehicles/vehicles.module';
import { RoutesModule } from './modules/routes/routes.module';
import { StopsModule } from './modules/stops/stops.module';
import { TrackingModule } from './modules/tracking/tracking.module';
import { EtaModule } from './modules/eta/eta.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { AdminModule } from './modules/admin/admin.module';

@Module({
  imports: [
    // Configuration Module
    // Loads environment variables from .env file
    ConfigModule.forRoot({
      isGlobal: true,  // Makes config available everywhere without importing
      envFilePath: ['.env', '.env.local'],
    }),

    // TypeORM Database Connection
    // Connects to PostgreSQL and manages all entities
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        url: configService.get<string>('DATABASE_URL'),
        entities: [__dirname + '/**/*.entity{.ts,.js}'],
        synchronize: configService.get<string>('NODE_ENV') !== 'production',
        logging: configService.get<string>('NODE_ENV') === 'development',
      }),
      inject: [ConfigService],
    }),

    // Feature Modules
    AuthModule,
    VehiclesModule,
    RoutesModule,
    StopsModule,
    TrackingModule,
    EtaModule,
    NotificationsModule,
    AdminModule,
  ],
})
export class AppModule {}
