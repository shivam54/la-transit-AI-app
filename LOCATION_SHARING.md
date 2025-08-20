# Location Sharing Feature

## Overview

The LA Transit App now includes a comprehensive location sharing feature that allows users to share their live location with family and friends. This feature is designed to provide peace of mind and safety for transit users.

## Features

### 🎯 Real-time Location Tracking
- Get your current location with high accuracy
- Automatic address resolution using reverse geocoding
- Real-time location updates during sharing sessions

### 👥 Contact Management
- Add and manage contacts (family, friends)
- Support for phone numbers and email addresses
- Toggle contacts on/off for sharing

### 📱 Multiple Sharing Methods
- **SMS**: Share location via text message (mobile devices)
- **Email**: Share location via email
- **WhatsApp**: Share location via WhatsApp Web API
- **Live Sharing**: Continuous location updates to selected contacts

### ⚙️ Customizable Settings
- **Update Interval**: Control how often location is updated (default: 30 seconds)
- **Auto-stop**: Automatically stop sharing after a specified time (default: 60 minutes)
- **Accuracy**: High-accuracy GPS positioning

### 🗺️ Map Integration
- Your current location is displayed on the transit map
- Custom blue marker with accuracy circle
- Location information in map legend

## How to Use

### 1. Access Location Sharing
- Click the "Share Location" button in the app header
- The location sharing panel will slide in from the right

### 2. Set Up Contacts
- Add family and friends as contacts
- Provide their phone number and/or email address
- Toggle contacts on/off to control who receives your location

### 3. Configure Settings
- Set update interval (how often location is shared)
- Set auto-stop timer (when to automatically stop sharing)
- Review current location and accuracy

### 4. Start Sharing
- Click "Start Sharing Location" to begin live sharing
- The app will request location permissions if needed
- Your location will be continuously updated and shared

### 5. Quick Share Options
- **SMS**: Instantly share current location via text
- **Email**: Send location details via email
- **WhatsApp**: Share via WhatsApp (if available)

## Privacy & Security

### 🔒 Privacy Features
- Location sharing is opt-in only
- Users control who receives their location
- Automatic session timeout
- No location data is stored permanently on servers

### 🛡️ Security Measures
- HTTPS encryption for all location data
- Local storage only - no cloud storage of location history
- User consent required for location access
- Clear indicators when location sharing is active

## Technical Implementation

### Location Service (`src/services/locationService.ts`)
- Handles geolocation API calls
- Manages location sharing sessions
- Provides reverse geocoding for address resolution
- Implements sharing via SMS, email, and WhatsApp

### Location Sharing Component (`src/components/LocationShare.tsx`)
- User interface for location sharing
- Contact management
- Settings configuration
- Real-time status display

### Custom Hook (`src/hooks/useLocationSharing.ts`)
- Manages location sharing state
- Provides clean API for components
- Handles errors and loading states

### Map Integration (`src/components/TransitMap.tsx`)
- Displays user location on the map
- Custom location marker with accuracy circle
- Location information in map legend

## Browser Compatibility

### ✅ Supported Browsers
- Chrome (desktop & mobile)
- Firefox (desktop & mobile)
- Safari (desktop & mobile)
- Edge (desktop & mobile)

### 📱 Mobile Features
- Native SMS integration
- WhatsApp sharing
- High-accuracy GPS
- Background location updates

### ⚠️ Requirements
- HTTPS connection required for geolocation
- User permission for location access
- Modern browser with geolocation support

## API Dependencies

### External Services
- **OpenStreetMap Nominatim**: Reverse geocoding for address resolution
- **Browser Geolocation API**: Native location services

### No External APIs Required
- All location sharing is done through native browser capabilities
- No third-party location tracking services
- No cloud storage of location data

## Error Handling

### Common Issues
1. **Location Permission Denied**: User must allow location access
2. **No GPS Signal**: App will show last known location
3. **Network Issues**: Offline mode supported for basic location
4. **Browser Compatibility**: Fallback for older browsers

### User Feedback
- Clear error messages
- Loading indicators
- Status updates
- Permission request dialogs

## Future Enhancements

### Planned Features
- Location history tracking
- Geofencing alerts
- Emergency contact integration
- Route-based sharing
- Battery optimization
- Offline location caching

### Potential Integrations
- Emergency services integration
- Social media sharing
- Calendar integration
- Weather-based alerts

## Support

For issues or questions about the location sharing feature:
1. Check browser permissions
2. Ensure HTTPS connection
3. Verify GPS is enabled (mobile devices)
4. Contact support with error details

---

**Note**: This feature respects user privacy and only shares location when explicitly enabled by the user. 