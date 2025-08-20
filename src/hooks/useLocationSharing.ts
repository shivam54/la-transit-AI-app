import { useState, useEffect, useCallback } from 'react';
import { UserLocation, LocationShareSettings, Contact, LocationShareSession } from '../types';
import locationService from '../services/locationService';

export const useLocationSharing = () => {
  const [currentLocation, setCurrentLocation] = useState<UserLocation | null>(null);
  const [isSharing, setIsSharing] = useState(false);
  const [currentSession, setCurrentSession] = useState<LocationShareSession | null>(null);
  const [error, setError] = useState<string | null>(null);

  // Get current location
  const getCurrentLocation = useCallback(async () => {
    try {
      setError(null);
      const location = await locationService.getCurrentLocation();
      setCurrentLocation(location);
      return location;
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to get location';
      setError(errorMessage);
      throw err;
    }
  }, []);

  // Start location sharing
  const startSharing = useCallback(async (settings: LocationShareSettings) => {
    try {
      setError(null);
      const session = await locationService.startLocationSharing(settings, (location) => {
        setCurrentLocation(location);
      });
      
      setIsSharing(true);
      setCurrentSession(session);
      return session;
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to start location sharing';
      setError(errorMessage);
      throw err;
    }
  }, []);

  // Stop location sharing
  const stopSharing = useCallback(() => {
    locationService.stopLocationSharing();
    setIsSharing(false);
    setCurrentSession(null);
  }, []);

  // Share location via different methods
  const shareViaSMS = useCallback(async (contacts: Contact[]) => {
    if (!currentLocation) {
      throw new Error('No current location available');
    }
    await locationService.shareViaSMS(currentLocation, contacts);
  }, [currentLocation]);

  const shareViaEmail = useCallback(async (contacts: Contact[]) => {
    if (!currentLocation) {
      throw new Error('No current location available');
    }
    await locationService.shareViaEmail(currentLocation, contacts);
  }, [currentLocation]);

  const shareViaWhatsApp = useCallback(async (contacts: Contact[]) => {
    if (!currentLocation) {
      throw new Error('No current location available');
    }
    await locationService.shareViaWhatsApp(currentLocation, contacts);
  }, [currentLocation]);

  // Get current session
  const getCurrentSession = useCallback(() => {
    return locationService.getCurrentSession();
  }, []);

  // Initialize location on mount
  useEffect(() => {
    getCurrentLocation().catch(() => {
      // Silently fail on initial load
    });
  }, [getCurrentLocation]);

  return {
    currentLocation,
    isSharing,
    currentSession,
    error,
    getCurrentLocation,
    startSharing,
    stopSharing,
    shareViaSMS,
    shareViaEmail,
    shareViaWhatsApp,
    getCurrentSession,
  };
}; 