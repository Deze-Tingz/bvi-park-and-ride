'use client';

import { useState, useEffect, useCallback } from 'react';
import { io, Socket } from 'socket.io-client';

interface VehicleUpdate {
  vehicleId: string;
  routeId: string;
  latitude: number;
  longitude: number;
  speed: number;
  heading: number;
  status: string;
  timestamp: string;
}

const SOCKET_URL = process.env.NEXT_PUBLIC_WS_URL || 'http://localhost:3000';

export function useSocket() {
  const [socket, setSocket] = useState<Socket | null>(null);
  const [isConnected, setIsConnected] = useState(false);
  const [vehicleUpdates, setVehicleUpdates] = useState<VehicleUpdate | null>(null);

  useEffect(() => {
    const socketInstance = io(`${SOCKET_URL}/tracking`, {
      transports: ['websocket'],
      autoConnect: true,
    });

    socketInstance.on('connect', () => {
      console.log('Admin socket connected');
      setIsConnected(true);

      // Subscribe to all routes as admin
      socketInstance.emit('admin:subscribe', { role: 'admin' });
    });

    socketInstance.on('disconnect', () => {
      console.log('Admin socket disconnected');
      setIsConnected(false);
    });

    socketInstance.on('connect_error', (error) => {
      console.error('Socket connection error:', error);
      setIsConnected(false);
    });

    // Listen for vehicle updates
    socketInstance.on('vehicle:update', (data: VehicleUpdate) => {
      setVehicleUpdates(data);
    });

    setSocket(socketInstance);

    return () => {
      socketInstance.disconnect();
    };
  }, []);

  const sendBroadcast = useCallback((message: {
    type: 'info' | 'warning' | 'emergency';
    title: string;
    message: string;
  }) => {
    if (socket && isConnected) {
      socket.emit('admin:broadcast', message);
    }
  }, [socket, isConnected]);

  return {
    socket,
    isConnected,
    vehicleUpdates,
    sendBroadcast,
  };
}
