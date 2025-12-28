import { Bus, Navigation, MapPin, User } from 'lucide-react';

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

interface VehicleCardProps {
  vehicle: VehicleData;
}

const statusColors = {
  active: 'bg-green-500',
  full: 'bg-orange-500',
  out_of_service: 'bg-red-500',
  offline: 'bg-gray-500',
};

const statusLabels = {
  active: 'Active',
  full: 'Full',
  out_of_service: 'Out of Service',
  offline: 'Offline',
};

const routeColors: Record<string, string> = {
  green: 'text-green-400 bg-green-500/20',
  yellow: 'text-yellow-400 bg-yellow-500/20',
};

export default function VehicleCard({ vehicle }: VehicleCardProps) {
  const timeSinceUpdate = getTimeSince(vehicle.lastUpdate);

  return (
    <div className="p-4 border-b border-gray-700 hover:bg-gray-700/50 transition-colors">
      <div className="flex items-start justify-between mb-2">
        <div className="flex items-center space-x-3">
          <div className="relative">
            <Bus className="h-8 w-8 text-blue-400" />
            <span className={`absolute -bottom-1 -right-1 w-3 h-3 rounded-full border-2 border-gray-800 ${statusColors[vehicle.status]}`} />
          </div>
          <div>
            <h3 className="font-semibold text-white">{vehicle.plateNumber}</h3>
            <span className={`text-xs px-2 py-0.5 rounded-full ${routeColors[vehicle.routeId] || 'text-gray-400 bg-gray-500/20'}`}>
              {vehicle.routeName}
            </span>
          </div>
        </div>
        <span className={`text-xs px-2 py-1 rounded-full ${
          vehicle.status === 'active' ? 'bg-green-500/20 text-green-400' :
          vehicle.status === 'full' ? 'bg-orange-500/20 text-orange-400' :
          'bg-red-500/20 text-red-400'
        }`}>
          {statusLabels[vehicle.status]}
        </span>
      </div>

      <div className="space-y-1 text-sm">
        <div className="flex items-center text-gray-400">
          <User className="h-3 w-3 mr-2" />
          <span>{vehicle.driverName}</span>
        </div>
        <div className="flex items-center text-gray-400">
          <MapPin className="h-3 w-3 mr-2" />
          <span>{vehicle.currentStop}</span>
        </div>
        <div className="flex items-center justify-between text-gray-500 text-xs">
          <div className="flex items-center">
            <Navigation className="h-3 w-3 mr-1" />
            <span>{vehicle.speed} km/h</span>
          </div>
          <span>Updated {timeSinceUpdate}</span>
        </div>
      </div>
    </div>
  );
}

function getTimeSince(date: Date): string {
  const seconds = Math.floor((new Date().getTime() - date.getTime()) / 1000);

  if (seconds < 60) return 'just now';
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
  return `${Math.floor(seconds / 86400)}d ago`;
}
