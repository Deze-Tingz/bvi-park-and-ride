/**
 * BVI Park & Ride Shuttle - NestJS API Entry Point
 *
 * This is the main entry point for the backend API.
 * It bootstraps the NestJS application with:
 * - Swagger API documentation
 * - CORS configuration
 * - Validation pipes
 * - WebSocket support
 */

import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  // Create the NestJS application
  const app = await NestFactory.create(AppModule);

  // Enable CORS for mobile apps and admin dashboard
  app.enableCors({
    origin: process.env.CORS_ORIGIN || '*',
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    credentials: true,
  });

  // Global validation pipe - validates all incoming requests
  // This ensures all DTOs are validated before reaching controllers
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,        // Strip properties not in DTO
      forbidNonWhitelisted: true, // Throw error for unknown properties
      transform: true,        // Transform payloads to DTO instances
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // Swagger API Documentation
  // Access at: http://localhost:3000/api/docs
  const config = new DocumentBuilder()
    .setTitle('BVI Park & Ride API')
    .setDescription('Backend API for the BVI Park & Ride Shuttle Service')
    .setVersion('1.0')
    .addBearerAuth()
    .addTag('auth', 'Authentication endpoints')
    .addTag('vehicles', 'Vehicle management')
    .addTag('routes', 'Route management')
    .addTag('stops', 'Stop management')
    .addTag('tracking', 'Real-time tracking')
    .addTag('eta', 'ETA calculations')
    .addTag('admin', 'Admin operations')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  // Start the server
  const port = process.env.PORT || 3000;
  await app.listen(port);

  console.log(`
  ====================================
   BVI Park & Ride API
  ====================================
   Server running on: http://localhost:${port}
   API Docs: http://localhost:${port}/api/docs
   WebSocket: ws://localhost:${port}/tracking
  ====================================
  `);
}

bootstrap();
