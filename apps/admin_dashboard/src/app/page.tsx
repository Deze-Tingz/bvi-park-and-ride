'use client';

import { useState, useEffect } from 'react';
import { Bus, Users, MapPin, Clock, AlertTriangle, CheckCircle, XCircle } from 'lucide-react';
import FleetMap from '@/components/FleetMap';
import VehicleCard from '@/components/VehicleCard';
import StatsCard from '@/components/StatsCard';
import { useSocket } from '@/hooks/useSocket';

interface VehicleData {
  id: string;
  plateNumber: string;
  routeId: string;
  routeName: string;
  status: 'active' | 'full' | 'out_of_service' | 'offline';
  latitude: number;
  longitude: number;
  speed: number;
  heading: number;
  driverName: string;
  currentStop: string;
  nextStop: string;
  lastUpdate: Date;
}

export default function Dashboard() {
  const [vehicles, setVehicles] = useState<VehicleData[]>([]);
  const { isConnected, vehicleUpdates } = useSocket();

  // Update vehicles when receiving socket updates
  useEffect(() => {
    if (vehicleUpdates) {
      setVehicles(prev => {
        const existing = prev.find(v => v.id === vehicleUpdates.vehicleId);
        if (existing) {
          return prev.map(v =>
            v.id === vehicleUpdates.vehicleId
              ? { ...v, ...vehicleUpdates, lastUpdate: new Date() }
              : v
          );
        }
        return prev;
      });
    }
  }, [vehicleUpdates]);

  // Load initial data (mock data for now)
  useEffect(() => {
    // Mock initial vehicles
    setVehicles([
      {
        id: 'v001',
        plateNumber: 'BVI-001',
        routeId: 'green',
        routeName: 'Green Line',
        status: 'active',
        latitude: 18.4285,
        longitude: -64.6189,
        speed: 25,
        heading: 90,
        driverName: 'John Smith',
        currentStop: 'Festival Grounds',
        nextStop: 'CCT Parking',
        lastUpdate: new Date(),
      },
      {
        id: 'v002',
        plateNumber: 'BVI-002',
        routeId: 'yellow',
        routeName: 'Yellow Line',
        status: 'active',
        latitude: 18.4310,
        longitude: -64.6245,
        speed: 18,
        heading: 180,
        driverName: 'Jane Doe',
        currentStop: 'Hospital',
        nextStop: 'High School',
        lastUpdate: new Date(),
      },
      {
        id: 'v003',
        plateNumber: 'BVI-003',
        routeId: 'green',
        routeName: 'Green Line',
        status: 'full',
        latitude: 18.4255,
        longitude: -64.6145,
        speed: 0,
        heading: 270,
        driverName: 'Mike Johnson',
        currentStop: 'Tortola Pier Park',
        nextStop: 'Ferry Terminal',
        lastUpdate: new Date(),
      },
    ]);
  }, []);

  const stats = {
    totalVehicles: vehicles.length,
    activeVehicles: vehicles.filter(v => v.status === 'active' || v.status === 'full').length,
    fullVehicles: vehicles.filter(v => v.status === 'full').length,
    offlineVehicles: vehicles.filter(v => v.status === 'offline' || v.status === 'out_of_service').length,
  };

  return (
    <div className="min-h-screen bg-gray-900">
      {/* Header */}
      <header className="bg-gray-800 border-b border-gray-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <Bus className="h-8 w-8 text-blue-500" />
              <div>
                <h1 className="text-xl font-bold text-white">BVI Park & Ride</h1>
                <p className="text-sm text-gray-400">Fleet Management Dashboard</p>
              </div>
            </div>
            <div className="flex items-center space-x-4">
              <div className={`flex items-center space-x-2 px-3 py-1 rounded-full ${
                isConnected ? 'bg-green-500/20 text-green-400' : 'bg-orange-500/20 text-orange-400'
              }`}>
                <span className={`w-2 h-2 rounded-full ${isConnected ? 'bg-green-500' : 'bg-orange-500'}`} />
                <span className="text-sm font-medium">
                  {isConnected ? 'Live' : 'Connecting...'}
                </span>
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <StatsCard
            title="Total Fleet"
            value={stats.totalVehicles}
            icon={<Bus className="h-6 w-6" />}
            color="blue"
          />
          <StatsCard
            title="Active Now"
            value={stats.activeVehicles}
            icon={<CheckCircle className="h-6 w-6" />}
            color="green"
          />
          <StatsCard
            title="At Capacity"
            value={stats.fullVehicles}
            icon={<Users className="h-6 w-6" />}
            color="orange"
          />
          <StatsCard
            title="Offline"
            value={stats.offlineVehicles}
            icon={<XCircle className="h-6 w-6" />}
            color="red"
          />
        </div>

        {/* Map and Vehicle List */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Fleet Map */}
          <div className="lg:col-span-2">
            <div className="bg-gray-800 rounded-lg overflow-hidden">
              <div className="px-4 py-3 border-b border-gray-700">
                <h2 className="text-lg font-semibold text-white flex items-center">
                  <MapPin className="h-5 w-5 mr-2 text-blue-500" />
                  Live Fleet Map
                </h2>
              </div>
              <div className="h-[500px]">
                <FleetMap vehicles={vehicles} />
              </div>
            </div>
          </div>

          {/* Vehicle List */}
          <div className="lg:col-span-1">
            <div className="bg-gray-800 rounded-lg">
              <div className="px-4 py-3 border-b border-gray-700">
                <h2 className="text-lg font-semibold text-white flex items-center">
                  <Bus className="h-5 w-5 mr-2 text-blue-500" />
                  Vehicles ({vehicles.length})
                </h2>
              </div>
              <div className="max-h-[500px] overflow-y-auto">
                {vehicles.map(vehicle => (
                  <VehicleCard key={vehicle.id} vehicle={vehicle} />
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* Recent Activity */}
        <div className="mt-6">
          <div className="bg-gray-800 rounded-lg">
            <div className="px-4 py-3 border-b border-gray-700">
              <h2 className="text-lg font-semibold text-white flex items-center">
                <Clock className="h-5 w-5 mr-2 text-blue-500" />
                Recent Activity
              </h2>
            </div>
            <div className="p-4">
              <div className="space-y-3">
                <ActivityItem
                  type="arrival"
                  vehicle="BVI-001"
                  message="Arrived at Festival Grounds"
                  time="2 min ago"
                />
                <ActivityItem
                  type="departure"
                  vehicle="BVI-002"
                  message="Departed from Hospital"
                  time="5 min ago"
                />
                <ActivityItem
                  type="status"
                  vehicle="BVI-003"
                  message="Status changed to Full"
                  time="8 min ago"
                />
                <ActivityItem
                  type="start"
                  vehicle="BVI-001"
                  message="Started shift on Green Line"
                  time="1 hour ago"
                />
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}

function ActivityItem({ type, vehicle, message, time }: {
  type: 'arrival' | 'departure' | 'status' | 'start' | 'end' | 'alert';
  vehicle: string;
  message: string;
  time: string;
}) {
  const icons = {
    arrival: <MapPin className="h-4 w-4 text-green-500" />,
    departure: <MapPin className="h-4 w-4 text-blue-500" />,
    status: <AlertTriangle className="h-4 w-4 text-orange-500" />,
    start: <CheckCircle className="h-4 w-4 text-green-500" />,
    end: <XCircle className="h-4 w-4 text-red-500" />,
    alert: <AlertTriangle className="h-4 w-4 text-red-500" />,
  };

  return (
    <div className="flex items-center space-x-3 text-sm">
      <div className="flex-shrink-0">{icons[type]}</div>
      <div className="flex-1">
        <span className="font-medium text-white">{vehicle}</span>
        <span className="text-gray-400"> - {message}</span>
      </div>
      <div className="text-gray-500 text-xs">{time}</div>
    </div>
  );
}
