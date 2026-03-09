import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/constants.dart';
import '../models/route_model.dart';
import '../models/location_model.dart';

/// Directions Service - Google Directions API integration
class DirectionsService {
  final String apiKey = AppConstants.googleMapsApiKey;
  final String baseUrl = AppConstants.directionsApiBaseUrl;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 15),
  ));

  /// Get directions between two points
  Future<RouteModel?> getDirections({
    required LocationModel origin,
    required LocationModel destination,
    required String transportMode, // 'driving', 'walking', 'bicycling', 'transit'
    String? avoid, // 'tolls', 'highways', 'ferries', 'indoor'
  }) async {
    try {
      final originStr = '${origin.latitude},${origin.longitude}';
      final destStr = '${destination.latitude},${destination.longitude}';
      
      final mode = _mapTransportMode(transportMode);
      
      final params = {
        'origin': originStr,
        'destination': destStr,
        'mode': mode,
        'key': apiKey,
        if (avoid != null) 'avoid': avoid,
        'alternatives': 'false',
      };

      // For web, use proxy if configured, otherwise direct call
      final url = _buildUrl('$baseUrl/json');
      
      final response = await _dio.get(
        url,
        queryParameters: params,
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          // Parse steps
          final steps = <RouteStep>[];
          for (var step in leg['steps']) {
            steps.add(RouteStep.fromJson({
              'instructions': step['html_instructions'],
              'start_location': step['start_location'],
              'end_location': step['end_location'],
              'distance': step['distance'],
              'duration': step['duration'],
              'travel_mode': step['travel_mode'],
            }));
          }

          return RouteModel(
            origin: origin,
            destination: destination,
            steps: steps,
            totalDistance: leg['distance']['value'].toDouble(),
            totalDuration: leg['duration']['value'],
            summary: route['summary'],
            polyline: route['overview_polyline']['points'],
            transportMode: transportMode,
          );
        } else {
          print('Directions API error: ${data['status']}');
          return null;
        }
      } else {
        print('Directions API HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      if (kIsWeb) {
        print('Error getting directions (Web CORS issue): $e');
        if (AppConstants.corsProxyUrl == null) {
          print('Note: Google Maps Directions API REST doesn\'t support CORS from browsers.');
          print('To fix: Set AppConstants.corsProxyUrl to your backend proxy URL.');
          print('Or deploy a backend proxy that forwards requests to Google Maps API.');
        }
      } else {
        print('Error getting directions: $e');
      }
      return null;
    }
  }

  /// Get transit directions (public transit)
  Future<RouteModel?> getTransitDirections({
    required LocationModel origin,
    required LocationModel destination,
    DateTime? departureTime,
    bool alternatives = true,
  }) async {
    try {
      final originStr = '${origin.latitude},${origin.longitude}';
      final destStr = '${destination.latitude},${destination.longitude}';
      
      final params = <String, dynamic>{
        'origin': originStr,
        'destination': destStr,
        'mode': 'transit',
        'key': apiKey,
        'alternatives': alternatives ? 'true' : 'false',
      };

      if (departureTime != null) {
        params['departure_time'] = departureTime.millisecondsSinceEpoch.toString();
      }

      // For web, use proxy if configured, otherwise direct call
      final url = _buildUrl('$baseUrl/json');
      
      final response = await _dio.get(
        url,
        queryParameters: params,
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          // Parse transit details
          final transitDetails = <Map<String, dynamic>>[];
          for (var step in leg['steps']) {
            if (step is Map && step['travel_mode'] == 'TRANSIT' && step['transit_details'] != null) {
              final transitDetail = step['transit_details'] as Map<String, dynamic>;
              transitDetails.add({
                'line': transitDetail['line'],
                'departure_stop': transitDetail['departure_stop'],
                'arrival_stop': transitDetail['arrival_stop'],
                'departure_time': transitDetail['departure_time'],
                'arrival_time': transitDetail['arrival_time'],
                'num_stops': transitDetail['num_stops'],
              });
            }
          }
          
          // Parse steps
          final steps = <RouteStep>[];
          for (var step in leg['steps']) {
            steps.add(RouteStep.fromJson({
              'instructions': step['html_instructions'],
              'start_location': step['start_location'],
              'end_location': step['end_location'],
              'distance': step['distance'],
              'duration': step['duration'],
              'travel_mode': step['travel_mode'],
            }));
          }

          return RouteModel(
            origin: origin,
            destination: destination,
            steps: steps,
            totalDistance: leg['distance']['value'].toDouble(),
            totalDuration: leg['duration']['value'],
            summary: route['summary'],
            polyline: route['overview_polyline']['points'],
            transportMode: 'public_transit',
            transitDetails: transitDetails,
          );
        } else {
          print('Transit Directions API error: ${data['status']}');
          return null;
        }
      } else {
        print('Transit Directions API HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      if (kIsWeb) {
        print('Error getting transit directions (Web CORS issue): $e');
        print('Note: Google Maps Directions API REST doesn\'t support CORS from browsers.');
        print('For web, consider using Google Maps JavaScript API or a backend proxy.');
      } else {
        print('Error getting transit directions: $e');
      }
      return null;
    }
  }

  /// Get multiple driving routes (alternatives) between two points
  /// Similar to TransitRoutesService but for driving mode
  Future<List<RouteModel>> getDrivingRoutes({
    required LocationModel origin,
    required LocationModel destination,
    String? avoid, // 'tolls', 'highways', 'ferries', 'indoor'
  }) async {
    try {
      final originStr = '${origin.latitude},${origin.longitude}';
      final destStr = '${destination.latitude},${destination.longitude}';
      
      final params = <String, dynamic>{
        'origin': originStr,
        'destination': destStr,
        'mode': 'driving',
        'key': apiKey,
        'alternatives': 'true', // Request multiple routes
        if (avoid != null) 'avoid': avoid,
      };

      // For web, use proxy if configured, otherwise direct call
      final url = _buildUrl('$baseUrl/json');
      
      final response = await _dio.get(
        url,
        queryParameters: params,
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final routesJson = List<Map<String, dynamic>>.from(data['routes']);
          final routes = <RouteModel>[];

          for (final routeJson in routesJson) {
            if (routeJson['legs'] == null || (routeJson['legs'] as List).isEmpty) {
              continue;
            }

            final leg = routeJson['legs'][0];
            
            // Parse steps for turn-by-turn directions
            final steps = <RouteStep>[];
            for (var step in leg['steps'] ?? []) {
              steps.add(RouteStep.fromJson({
                'instructions': step['html_instructions'],
                'start_location': step['start_location'],
                'end_location': step['end_location'],
                'distance': step['distance'],
                'duration': step['duration'],
                'travel_mode': step['travel_mode'],
              }));
            }

            routes.add(
              RouteModel(
                origin: origin,
                destination: destination,
                steps: steps,
                totalDistance: (leg['distance']?['value'] ?? 0).toDouble(),
                totalDuration: leg['duration']?['value'] ?? 0,
                summary: routeJson['summary'] ?? '',
                polyline: routeJson['overview_polyline']?['points'],
                transportMode: 'driving',
              ),
            );
          }

          return routes;
        } else {
          print('Driving routes API error: ${data['status']}');
          return [];
        }
      } else {
        print('Driving routes HTTP error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      if (kIsWeb) {
        print('Error getting driving routes (Web CORS issue): $e');
      } else {
        print('Error getting driving routes: $e');
      }
      return [];
    }
  }

  /// Map transport mode to Google Directions API format
  String _mapTransportMode(String mode) {
    switch (mode) {
      case 'drive':
      case 'driving':
        return 'driving';
      case 'walk':
      case 'walking':
        return 'walking';
      case 'bike':
      case 'bicycling':
        return 'bicycling';
      case 'public_transit':
      case 'transit':
        return 'transit';
      default:
        return 'driving';
    }
  }
  
  /// Build URL with CORS proxy for web if configured
  String _buildUrl(String originalUrl) {
    if (kIsWeb && AppConstants.corsProxyUrl != null && AppConstants.corsProxyUrl!.isNotEmpty) {
      // Use proxy for web
      return '${AppConstants.corsProxyUrl}?url=${Uri.encodeComponent(originalUrl)}';
    }
    return originalUrl;
  }
}

