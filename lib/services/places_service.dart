import 'dart:convert';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import '../utils/constants.dart';
import '../models/landmark_model.dart';
import '../models/location_model.dart';

/// Places Service - Google Places API integration with accessibility support
class PlacesService {
  final String apiKey = AppConstants.googleMapsApiKey;
  final String baseUrl = AppConstants.placesApiBaseUrl;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 15),
  ));

  /// Search nearby landmarks with accessibility options
  Future<List<LandmarkModel>> searchNearbyLandmarks({
    required double latitude,
    required double longitude,
    required int radius,
    List<String>? includedTypes,
    bool includeAccessibility = true,
    bool accessibleOnly = false,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/places:searchNearby');
      
      // Default included types if not specified
      final types = includedTypes ?? [
        'restaurant',
        'cafe',
        'parking',
        'shopping_mall',
        'department_store',
        'supermarket',
        'grocery_store',
        'convenience_store',
        'clothing_store',
        'lodging',
        'transit_station',
        'bus_station',
        'train_station',
        'subway_station',
        'tourist_attraction',
        'movie_theater',
        'night_club',
        'stadium',
        'convention_center',
        'performing_arts_theater',
        'amusement_park',
        'zoo',
        'art_gallery',
        'sports_complex',
        'gas_station',
        'pharmacy',
        'hospital',
        'bank',
        'atm',
      ];

      final body = {
        'maxResultCount': AppConstants.maxLandmarkResults,
        'rankPreference': 'POPULARITY',
        'includedTypes': types,
        'locationRestriction': {
          'circle': {
            'center': {
              'latitude': latitude,
              'longitude': longitude,
            },
            'radius': radius,
          }
        }
      };

      // Field mask includes accessibility options
      final fieldMask = includeAccessibility
          ? 'places.id,places.displayName,places.formattedAddress,places.types,places.location,places.accessibilityOptions,places.rating,places.priceLevel'
          : 'places.id,places.displayName,places.formattedAddress,places.types,places.location,places.rating,places.priceLevel';

      final response = await _dio.post(
        url.toString(),
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': apiKey,
            'X-Goog-FieldMask': fieldMask,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final places = List<Map<String, dynamic>>.from(data['places'] ?? []);
        
        var landmarks = places
            .map((p) => LandmarkModel.fromPlacesApi(p))
            .toList();

        // Filter by accessibility if requested
        if (accessibleOnly) {
          landmarks = landmarks.where((l) => l.isAccessible).toList();
        }

        // Calculate distances
        landmarks = landmarks.map((landmark) {
          return _calculateDistance(
            landmark,
            latitude,
            longitude,
          );
        }).toList();

        return landmarks;
      } else {
        print('Places API error: ${response.statusCode} - ${response.data}');
        return [];
      }
    } catch (e) {
      print('Error searching nearby landmarks: $e');
      return [];
    }
  }

  /// Get place details with neighborhood summary (Gemini AI)
  Future<Map<String, dynamic>?> getPlaceWithSummary(String placeId) async {
    try {
      final url = Uri.parse('$baseUrl/places/$placeId');
      
      final response = await _dio.get(
        url.toString(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': apiKey,
            'X-Goog-FieldMask': 'id,displayName,neighborhoodSummary,formattedAddress,types,location,accessibilityOptions',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Error getting place details: $e');
      return null;
    }
  }

  /// Autocomplete places (for search)
  Future<List<Map<String, dynamic>>> autocompletePlaces(String query, {double? lat, double? lng}) async {
    try {
      final url = Uri.parse('$baseUrl/places:autocomplete');
      
      final body = {
        'input': query,
        if (lat != null && lng != null)
          'locationBias': {
            'circle': {
              'center': {
                'latitude': lat,
                'longitude': lng,
              },
              'radius': AppConstants.laSearchRadius,
            }
          }
      };

      final response = await _dio.post(
        url.toString(),
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': apiKey,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return List<Map<String, dynamic>>.from(data['suggestions'] ?? []);
      }
      return [];
    } catch (e) {
      if (e is DioException && e.response != null) {
        print('Error autocompleting places: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        print('Error autocompleting places: $e');
      }
      return [];
    }
  }

  /// Find summary with fallback logic (same as web app)
  Future<Map<String, dynamic>?> findSummaryWithFallback({
    required String placeId,
    required double latitude,
    required double longitude,
    String? originalDestination,
  }) async {
    // Try direct summary first
    final details = await getPlaceWithSummary(placeId);
    if (details != null && details['neighborhoodSummary'] != null) {
      return _normalizeNeighborhoodSummary(details['neighborhoodSummary']);
    }

    // Try nearby places with priority types
    final nearbyPlaces = await searchNearbyLandmarks(
      latitude: latitude,
      longitude: longitude,
      radius: 1000,
      includedTypes: ['lodging', 'shopping_mall', 'tourist_attraction'],
    );

    if (nearbyPlaces.isNotEmpty) {
      final firstPlace = nearbyPlaces.first;
      final placeDetails = await getPlaceWithSummary(firstPlace.id);
      if (placeDetails != null && placeDetails['neighborhoodSummary'] != null) {
        return _normalizeNeighborhoodSummary(placeDetails['neighborhoodSummary']);
      }
    }

    return null;
  }

  /// Normalize the neighborhoodSummary field so the UI can always treat it
  /// as a map with a simple `content.text` field. Sometimes the API returns
  /// a structured map, other times a serialized string representation.
  Map<String, dynamic> _normalizeNeighborhoodSummary(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }

    if (raw is String) {
      final cleaned = raw.trim();
      // Try to extract everything between "text:" and ", languageCode"
      final regex = RegExp(r'text:\s*(.*?),\s*languageCode', dotAll: true);
      final match = regex.firstMatch(cleaned);
      String text;
      if (match != null && match.groupCount >= 1) {
        text = match.group(1)?.trim() ?? cleaned;
      } else {
        text = cleaned;
      }
      return {
        'content': {'text': text},
      };
    }

    return {
      'content': {'text': raw.toString()},
    };
  }

  /// Calculate distance between landmark and location
  LandmarkModel _calculateDistance(LandmarkModel landmark, double lat, double lng) {
    final distance = _haversineDistance(
      lat,
      lng,
      landmark.location.latitude,
      landmark.location.longitude,
    );
    return LandmarkModel(
      id: landmark.id,
      name: landmark.name,
      address: landmark.address,
      location: landmark.location,
      types: landmark.types,
      isAccessible: landmark.isAccessible,
      accessibilityOptions: landmark.accessibilityOptions,
      distance: distance,
      rating: landmark.rating,
      priceLevel: landmark.priceLevel,
    );
  }

  /// Haversine distance formula
  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000; // Earth radius in meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);
}

