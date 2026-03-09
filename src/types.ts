export interface Station {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  lines: string[];
  address?: string;
  facilities?: string[];
}

export interface MetroRoute {
  id: string;
  name: string;
  color: string;
  stations: Station[];
  coordinates: [number, number][];
  frequency: string;
  operatingHours: string;
  description: string;
}

export interface TransitInfo {
  routeId: string;
  stationId: string;
  direction: 'northbound' | 'southbound' | 'eastbound' | 'westbound';
  nextArrival: string;
  status: 'on_time' | 'delayed' | 'cancelled';
}

export interface RouteSearchParams {
  origin: Station;
  destination: Station;
  departureTime?: Date;
  arrivalTime?: Date;
}

// Location sharing types
export interface UserLocation {
  latitude: number;
  longitude: number;
  accuracy?: number;
  timestamp: number;
  address?: string;
}

export interface LocationShareSettings {
  isSharing: boolean;
  shareWith: Contact[];
  updateInterval: number; // in seconds
  autoStopAfter?: number; // in minutes, undefined means no auto-stop
}

export interface Contact {
  id: string;
  name: string;
  phone?: string;
  email?: string;
  isActive: boolean;
}

export interface LocationShareSession {
  id: string;
  startTime: number;
  endTime?: number;
  sharedWith: Contact[];
  locations: UserLocation[];
} 