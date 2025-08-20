import axios from 'axios';
import { MetroRoute, Station, TransitInfo } from '../types';

// Base API configuration
const API_BASE_URL = process.env.REACT_APP_API_BASE_URL || 'https://api.metro.net';

// Create axios instance with default config
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// API response types
interface ApiResponse<T> {
  data: T;
  status: number;
  message?: string;
}

// Metro API Service
export class MetroApiService {
  // Get all metro routes
  static async getRoutes(): Promise<MetroRoute[]> {
    try {
      const response = await apiClient.get<ApiResponse<MetroRoute[]>>('/routes');
      return response.data.data;
    } catch (error) {
      console.error('Error fetching routes:', error);
      throw new Error('Failed to fetch metro routes');
    }
  }

  // Get route by ID
  static async getRouteById(routeId: string): Promise<MetroRoute> {
    try {
      const response = await apiClient.get<ApiResponse<MetroRoute>>(`/routes/${routeId}`);
      return response.data.data;
    } catch (error) {
      console.error('Error fetching route:', error);
      throw new Error('Failed to fetch route details');
    }
  }

  // Get all stations
  static async getStations(): Promise<Station[]> {
    try {
      const response = await apiClient.get<ApiResponse<Station[]>>('/stations');
      return response.data.data;
    } catch (error) {
      console.error('Error fetching stations:', error);
      throw new Error('Failed to fetch stations');
    }
  }

  // Get station by ID
  static async getStationById(stationId: string): Promise<Station> {
    try {
      const response = await apiClient.get<ApiResponse<Station>>(`/stations/${stationId}`);
      return response.data.data;
    } catch (error) {
      console.error('Error fetching station:', error);
      throw new Error('Failed to fetch station details');
    }
  }

  // Get real-time transit information
  static async getTransitInfo(routeId: string, stationId: string): Promise<TransitInfo[]> {
    try {
      const response = await apiClient.get<ApiResponse<TransitInfo[]>>(
        `/transit-info?routeId=${routeId}&stationId=${stationId}`
      );
      return response.data.data;
    } catch (error) {
      console.error('Error fetching transit info:', error);
      throw new Error('Failed to fetch transit information');
    }
  }

  // Get route schedule
  static async getRouteSchedule(routeId: string, date?: string): Promise<any> {
    try {
      const params = date ? { date } : {};
      const response = await apiClient.get<ApiResponse<any>>(`/routes/${routeId}/schedule`, { params });
      return response.data.data;
    } catch (error) {
      console.error('Error fetching schedule:', error);
      throw new Error('Failed to fetch route schedule');
    }
  }

  // Search routes between stations
  static async searchRoutes(origin: string, destination: string, time?: string): Promise<any[]> {
    try {
      const params: any = { origin, destination };
      if (time) params.time = time;
      
      const response = await apiClient.get<ApiResponse<any[]>>('/routes/search', { params });
      return response.data.data;
    } catch (error) {
      console.error('Error searching routes:', error);
      throw new Error('Failed to search routes');
    }
  }
}

// GTFS API Service (for real transit data)
export class GTFSApiService {
  private static gtfsBaseUrl = 'https://api.transit.land/v2';

  // Get agencies
  static async getAgencies(): Promise<any[]> {
    try {
      const response = await axios.get(`${this.gtfsBaseUrl}/agencies`);
      return response.data.agencies;
    } catch (error) {
      console.error('Error fetching agencies:', error);
      throw new Error('Failed to fetch transit agencies');
    }
  }

  // Get routes for an agency
  static async getAgencyRoutes(agencyId: string): Promise<any[]> {
    try {
      const response = await axios.get(`${this.gtfsBaseUrl}/agencies/${agencyId}/routes`);
      return response.data.routes;
    } catch (error) {
      console.error('Error fetching agency routes:', error);
      throw new Error('Failed to fetch agency routes');
    }
  }

  // Get stops for a route
  static async getRouteStops(routeId: string): Promise<any[]> {
    try {
      const response = await axios.get(`${this.gtfsBaseUrl}/routes/${routeId}/stops`);
      return response.data.stops;
    } catch (error) {
      console.error('Error fetching route stops:', error);
      throw new Error('Failed to fetch route stops');
    }
  }
}

// LA Metro Specific API Service
export class LAMetroApiService {
  private static metroApiUrl = 'https://api.metro.net/agencies/lametro';

  // Get LA Metro routes
  static async getLAMetroRoutes(): Promise<any[]> {
    try {
      const response = await axios.get(`${this.metroApiUrl}/routes`);
      return response.data.routes;
    } catch (error) {
      console.error('Error fetching LA Metro routes:', error);
      throw new Error('Failed to fetch LA Metro routes');
    }
  }

  // Get LA Metro stops
  static async getLAMetroStops(): Promise<any[]> {
    try {
      const response = await axios.get(`${this.metroApiUrl}/stops`);
      return response.data.stops;
    } catch (error) {
      console.error('Error fetching LA Metro stops:', error);
      throw new Error('Failed to fetch LA Metro stops');
    }
  }

  // Get real-time arrivals
  static async getRealTimeArrivals(stopId: string): Promise<any[]> {
    try {
      const response = await axios.get(`${this.metroApiUrl}/stops/${stopId}/arrivals`);
      return response.data.arrivals;
    } catch (error) {
      console.error('Error fetching real-time arrivals:', error);
      throw new Error('Failed to fetch real-time arrivals');
    }
  }
}

// Export default API service
export default MetroApiService; 