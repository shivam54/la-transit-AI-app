import { useState, useEffect } from 'react';
import { MetroRoute, Station, TransitInfo } from '../types';
import { metroRoutes, metroStations } from '../data/metroRoutes';
import MetroApiService from '../services/api';

interface UseTransitDataReturn {
  routes: MetroRoute[];
  stations: Station[];
  loading: boolean;
  error: string | null;
  refreshData: () => void;
  getRouteById: (id: string) => MetroRoute | undefined;
  getStationById: (id: string) => Station | undefined;
  getTransitInfo: (routeId: string, stationId: string) => Promise<TransitInfo[]>;
}

export const useTransitData = (): UseTransitDataReturn => {
  const [routes, setRoutes] = useState<MetroRoute[]>(metroRoutes);
  const [stations, setStations] = useState<Station[]>(metroStations);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Load data from API (with fallback to static data)
  const loadData = async () => {
    setLoading(true);
    setError(null);
    
    try {
      // Try to fetch from API first
      const apiRoutes = await MetroApiService.getRoutes();
      const apiStations = await MetroApiService.getStations();
      
      setRoutes(apiRoutes);
      setStations(apiStations);
    } catch (apiError) {
      console.warn('API not available, using static data:', apiError);
      // Fallback to static data
      setRoutes(metroRoutes);
      setStations(metroStations);
    } finally {
      setLoading(false);
    }
  };

  // Get route by ID
  const getRouteById = (id: string): MetroRoute | undefined => {
    return routes.find(route => route.id === id);
  };

  // Get station by ID
  const getStationById = (id: string): Station | undefined => {
    return stations.find(station => station.id === id);
  };

  // Get transit info for a route/station combination
  const getTransitInfo = async (routeId: string, stationId: string): Promise<TransitInfo[]> => {
    try {
      return await MetroApiService.getTransitInfo(routeId, stationId);
    } catch (error) {
      console.warn('Failed to fetch transit info:', error);
      // Return mock data as fallback
      return [
        {
          routeId,
          stationId,
          direction: 'northbound' as const,
          nextArrival: '5 min',
          status: 'on_time' as const
        },
        {
          routeId,
          stationId,
          direction: 'southbound' as const,
          nextArrival: '12 min',
          status: 'on_time' as const
        }
      ];
    }
  };

  // Refresh data
  const refreshData = () => {
    loadData();
  };

  // Load data on mount
  useEffect(() => {
    loadData();
  }, []);

  return {
    routes,
    stations,
    loading,
    error,
    refreshData,
    getRouteById,
    getStationById,
    getTransitInfo
  };
}; 