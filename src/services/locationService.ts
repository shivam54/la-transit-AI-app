import { UserLocation, LocationShareSettings, Contact, LocationShareSession } from '../types';

class LocationService {
  private watchId: number | null = null;
  private currentSession: LocationShareSession | null = null;
  private onLocationUpdate: ((location: UserLocation) => void) | null = null;

  // Get current location
  async getCurrentLocation(): Promise<UserLocation> {
    return new Promise((resolve, reject) => {
      if (!navigator.geolocation) {
        reject(new Error('Geolocation is not supported by this browser'));
        return;
      }

      navigator.geolocation.getCurrentPosition(
        (position) => {
          const location: UserLocation = {
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
            accuracy: position.coords.accuracy,
            timestamp: position.timestamp,
          };

          // Get address from coordinates
          this.getAddressFromCoordinates(location.latitude, location.longitude)
            .then(address => {
              location.address = address;
              resolve(location);
            })
            .catch(() => resolve(location)); // Resolve without address if geocoding fails
        },
        (error) => {
          reject(new Error(`Error getting location: ${error.message}`));
        },
        {
          enableHighAccuracy: true,
          timeout: 10000,
          maximumAge: 60000,
        }
      );
    });
  }

  // Start location sharing
  async startLocationSharing(
    settings: LocationShareSettings,
    onUpdate?: (location: UserLocation) => void
  ): Promise<LocationShareSession> {
    if (this.watchId) {
      this.stopLocationSharing();
    }

    this.onLocationUpdate = onUpdate || null;

    const session: LocationShareSession = {
      id: this.generateSessionId(),
      startTime: Date.now(),
      sharedWith: settings.shareWith,
      locations: [],
    };

    this.currentSession = session;

    return new Promise((resolve, reject) => {
      if (!navigator.geolocation) {
        reject(new Error('Geolocation is not supported by this browser'));
        return;
      }

      this.watchId = navigator.geolocation.watchPosition(
        (position) => {
          const location: UserLocation = {
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
            accuracy: position.coords.accuracy,
            timestamp: position.timestamp,
          };

          // Get address from coordinates
          this.getAddressFromCoordinates(location.latitude, location.longitude)
            .then(address => {
              location.address = address;
              this.handleLocationUpdate(location);
            })
            .catch(() => this.handleLocationUpdate(location));
        },
        (error) => {
          reject(new Error(`Error watching location: ${error.message}`));
        },
        {
          enableHighAccuracy: true,
          timeout: 10000,
          maximumAge: settings.updateInterval * 1000,
        }
      );

      resolve(session);
    });
  }

  // Stop location sharing
  stopLocationSharing(): void {
    if (this.watchId) {
      navigator.geolocation.clearWatch(this.watchId);
      this.watchId = null;
    }

    if (this.currentSession) {
      this.currentSession.endTime = Date.now();
      this.currentSession = null;
    }

    this.onLocationUpdate = null;
  }

  // Get address from coordinates using reverse geocoding
  private async getAddressFromCoordinates(latitude: number, longitude: number): Promise<string> {
    try {
      const response = await fetch(
        `https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}&zoom=18&addressdetails=1`
      );
      
      if (!response.ok) {
        throw new Error('Geocoding request failed');
      }

      const data = await response.json();
      return data.display_name || `${latitude.toFixed(6)}, ${longitude.toFixed(6)}`;
    } catch (error) {
      console.warn('Failed to get address from coordinates:', error);
      return `${latitude.toFixed(6)}, ${longitude.toFixed(6)}`;
    }
  }

  // Handle location updates
  private handleLocationUpdate(location: UserLocation): void {
    if (this.currentSession) {
      this.currentSession.locations.push(location);
    }

    if (this.onLocationUpdate) {
      this.onLocationUpdate(location);
    }
  }

  // Generate unique session ID
  private generateSessionId(): string {
    return `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  // Get current session
  getCurrentSession(): LocationShareSession | null {
    return this.currentSession;
  }

  // Share location via SMS (for mobile devices)
  async shareViaSMS(location: UserLocation, contacts: Contact[]): Promise<void> {
    const phoneNumbers = contacts
      .filter(contact => contact.phone)
      .map(contact => contact.phone)
      .join(',');

    if (phoneNumbers) {
      const message = `I'm sharing my location with you: ${location.address || `${location.latitude}, ${location.longitude}`}`;
      const smsUrl = `sms:${phoneNumbers}?body=${encodeURIComponent(message)}`;
      
      window.open(smsUrl, '_blank');
    }
  }

  // Share location via email
  async shareViaEmail(location: UserLocation, contacts: Contact[]): Promise<void> {
    const emails = contacts
      .filter(contact => contact.email)
      .map(contact => contact.email)
      .join(',');

    if (emails) {
      const subject = 'Location Share';
      const body = `I'm sharing my location with you: ${location.address || `${location.latitude}, ${location.longitude}`}`;
      const mailtoUrl = `mailto:${emails}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
      
      window.open(mailtoUrl, '_blank');
    }
  }

  // Share location via WhatsApp (if available)
  async shareViaWhatsApp(location: UserLocation, contacts: Contact[]): Promise<void> {
    const phoneNumbers = contacts
      .filter(contact => contact.phone)
      .map(contact => contact.phone?.replace(/\D/g, ''))
      .join(',');

    if (phoneNumbers) {
      const message = `I'm sharing my location with you: ${location.address || `${location.latitude}, ${location.longitude}`}`;
      const whatsappUrl = `https://wa.me/${phoneNumbers}?text=${encodeURIComponent(message)}`;
      
      window.open(whatsappUrl, '_blank');
    }
  }
}

export const locationService = new LocationService();
export default locationService; 