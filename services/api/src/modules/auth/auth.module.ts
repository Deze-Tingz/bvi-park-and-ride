/**
 * Auth Module
 *
 * Handles all authentication and authorization:
 * - User registration (riders, drivers, admins)
 * - Login with email/password
 * - JWT token generation and validation
 * - Role-based access control
 *
 * WHY THIS MODULE EXISTS:
 * Security is critical for a government service. This module ensures
 * only authorized users can access the system, and drivers can only
 * perform driver actions, admins can only perform admin actions, etc.
 */

import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtStrategy } from './strategies/jwt.strategy';
import { User } from '../../database/entities/user.entity';
import { Driver } from '../../database/entities/driver.entity';

@Module({
  imports: [
    // Import TypeORM entities this module needs
    TypeOrmModule.forFeature([User, Driver]),

    // Passport for authentication strategies
    PassportModule.register({ defaultStrategy: 'jwt' }),

    // JWT configuration
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        secret: configService.get<string>('JWT_SECRET'),
        signOptions: {
          expiresIn: configService.get<string>('JWT_EXPIRES_IN') || '1d',
        },
      }),
      inject: [ConfigService],
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy],
  exports: [AuthService, JwtStrategy, PassportModule],
})
export class AuthModule {}
