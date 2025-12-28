/**
 * Tracking WebSocket Gateway
 *
 * This is the WebSocket server for real-time tracking.
 * It handles:
 * - Driver location updates
 * - Rider subscriptions to routes
 * - Broadcasting vehicle positions to riders
 *
 * LEARNING NOTE:
 * WebSocket gateways in NestJS use decorators similar to controllers.
 * @SubscribeMessage() handles incoming messages from clients.
 * The server can emit messages to specific rooms or all clients.
 *
 * HOW IT WORKS:
 * 1. Driver connects and sends location updates every 1-3 seconds
 * 2. Server validates and stores the location
 * 3. Server broadcasts the update to all riders subscribed to that route
 * 4. Rider app receives update and animates the vehicle marker
 */

import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';

import { TrackingService } from './tracking.service';
import { LocationUpdateDto } from './dto/location-update.dto';

@WebSocketGateway({
  namespace: '/tracking',
  cors: {
    origin: '*', // In production, restrict to your domains
  },
})
export class TrackingGateway
  implements OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger('TrackingGateway');

  constructor(private readonly trackingService: TrackingService) {}

  /**
   * Called when a client connects
   */
  handleConnection(client: Socket) {
    this.logger.log(`Client connected: ${client.id}`);
  }

  /**
   * Called when a client disconnects
   */
  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
    // If this was a driver, mark them as offline
    this.trackingService.handleDriverDisconnect(client.id);
  }

  /**
   * Driver sends location update
   * Called every 1-3 seconds when driver is moving
   *
   * Payload: { vehicleId, latitude, longitude, speed, heading, accuracy, timestamp }
   */
  @SubscribeMessage('driver:location')
  async handleLocationUpdate(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: LocationUpdateDto,
  ) {
    try {
      // Validate and store the location
      const result = await this.trackingService.updateLocation(client.id, data);

      if (result.success) {
        // Broadcast to all riders subscribed to this route
        const roomName = `route:${result.routeId}`;

        this.server.to(roomName).emit('vehicle:update', {
          vehicleId: data.vehicleId,
          routeId: result.routeId,
          latitude: data.latitude,
          longitude: data.longitude,
          speed: data.speed,
          heading: data.heading,
          status: result.status,
          nextStopId: result.nextStopId,
          nextStopEta: result.nextStopEta,
          timestamp: new Date().toISOString(),
        });
      }

      return { success: true };
    } catch (error) {
      this.logger.error(`Location update error: ${error.message}`);
      return { success: false, error: error.message };
    }
  }

  /**
   * Rider subscribes to a route
   * They will receive vehicle updates for that route
   */
  @SubscribeMessage('subscribe:route')
  handleSubscribeToRoute(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { routeId: string },
  ) {
    const roomName = `route:${data.routeId}`;
    client.join(roomName);
    this.logger.log(`Client ${client.id} subscribed to ${roomName}`);

    return { success: true, subscribed: data.routeId };
  }

  /**
   * Rider unsubscribes from a route
   */
  @SubscribeMessage('unsubscribe:route')
  handleUnsubscribeFromRoute(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { routeId: string },
  ) {
    const roomName = `route:${data.routeId}`;
    client.leave(roomName);
    this.logger.log(`Client ${client.id} unsubscribed from ${roomName}`);

    return { success: true, unsubscribed: data.routeId };
  }

  /**
   * Driver registers their connection
   * Links socket ID to vehicle for tracking
   */
  @SubscribeMessage('driver:register')
  async handleDriverRegister(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { vehicleId: string; routeId: string },
  ) {
    await this.trackingService.registerDriver(
      client.id,
      data.vehicleId,
      data.routeId,
    );

    this.logger.log(
      `Driver registered: socket=${client.id}, vehicle=${data.vehicleId}`,
    );

    return { success: true };
  }

  /**
   * Driver marks arrival at a stop
   */
  @SubscribeMessage('stop:arrived')
  async handleStopArrival(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { vehicleId: string; stopId: string },
  ) {
    const result = await this.trackingService.handleStopArrival(
      data.vehicleId,
      data.stopId,
    );

    if (result.routeId) {
      // Broadcast arrival to all riders on this route
      this.server.to(`route:${result.routeId}`).emit('stop:arrival', {
        vehicleId: data.vehicleId,
        stopId: data.stopId,
        stopName: result.stopName,
        timestamp: new Date().toISOString(),
      });
    }

    return { success: true };
  }

  /**
   * Broadcast an alert to all riders on a route
   * Used by admins for service announcements
   */
  broadcastAlert(
    routeId: string,
    type: 'info' | 'warning' | 'emergency',
    title: string,
    message: string,
  ) {
    this.server.to(`route:${routeId}`).emit('alert:broadcast', {
      type,
      title,
      message,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Broadcast alert to ALL connected riders
   */
  broadcastGlobalAlert(
    type: 'info' | 'warning' | 'emergency',
    title: string,
    message: string,
  ) {
    this.server.emit('alert:broadcast', {
      type,
      title,
      message,
      timestamp: new Date().toISOString(),
    });
  }
}
