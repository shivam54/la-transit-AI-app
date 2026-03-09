import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_model.dart';

/// Location Provider for managing user location
class LocationProvider extends ChangeNotifier {
  LocationModel? _currentLocation;
  bool _isLoading = false;
  String? _error;

  LocationModel? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLocation => _currentLocation != null;

  /// Request location permission and get current location
  Future<void> getCurrentLocation() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Silently fail - location is optional
        _error = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Silently fail - location is optional
          _error = null;
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Silently fail - location is optional
        _error = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get current position with shorter timeout and lower accuracy for faster response
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low, // Use low accuracy for faster response
          timeLimit: const Duration(seconds: 5), // Shorter timeout
        ).timeout(
          const Duration(seconds: 5),
        );
      } catch (timeoutError) {
        // Silently fail on timeout - location is optional
        _error = null;
        _currentLocation = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      _currentLocation = LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      _error = null;
    } catch (e) {
      // Silently handle all errors - location is optional
      // Don't show any errors to the user
      _error = null;
      _currentLocation = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update current location manually
  void updateLocation(LocationModel location) {
    _currentLocation = location;
    _error = null;
    notifyListeners();
  }

  /// Clear location
  void clearLocation() {
    _currentLocation = null;
    _error = null;
    notifyListeners();
  }
}

