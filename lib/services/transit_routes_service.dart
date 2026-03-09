import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/location_model.dart';
import '../models/route_model.dart';
import '../utils/constants.dart';
import 'transit_service.dart';

/// TransitRoutesService
///
/// Fetches one or more public‑transit routes between an origin and
/// destination using the Google Directions API (with alternatives).
class TransitRoutesService {
  final String _apiKey = AppConstants.googleMapsApiKey;
  final String _baseUrl = AppConstants.directionsApiBaseUrl;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 15),
  ));
  final TransitService _transitService = TransitService();

  /// Get transit routes between two points.
  ///
  /// Returns a list of `RouteModel` objects, one per suggested route
  /// from the Directions API. This is what powers the \"Suggested Routes\"
  /// list when the user taps **View Routes** for public transit.
  Future<List<RouteModel>> getTransitRoutes({
    required LocationModel origin,
    required LocationModel destination,
  }) async {
    try {
      final originStr = '${origin.latitude},${origin.longitude}';
      final destStr = '${destination.latitude},${destination.longitude}';

      final params = <String, dynamic>{
        'origin': originStr,
        'destination': destStr,
        'mode': 'transit',
        'key': _apiKey,
        'alternatives': 'true', // ask Google for multiple routes
      };

      // For web, use proxy if configured, otherwise direct call
      final url = _buildUrl('$_baseUrl/json');
      
      final response = await _dio.get(
        url,
        queryParameters: params,
        options: Options(
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.statusCode != 200) {
        if (!kIsWeb) {
          // ignore: avoid_print
          print('Transit routes HTTP error: ${response.statusCode}');
        }
        return [];
      }

      final data = response.data;
      if (data['status'] != 'OK' || (data['routes'] as List).isEmpty) {
        if (!kIsWeb) {
          // ignore: avoid_print
          print('Transit routes API error: ${data['status']}');
        }
        return [];
      }

      final routesJson = List<Map<String, dynamic>>.from(data['routes']);
      final routes = <RouteModel>[];

      for (final routeJson in routesJson) {
        if (routeJson['legs'] == null ||
            (routeJson['legs'] as List).isEmpty) continue;

        final leg = routeJson['legs'][0];

        // Parse transit details per route
        final transitDetails = <Map<String, dynamic>>[];
        for (final step in leg['steps'] ?? []) {
          if (step is Map &&
              step['travel_mode'] == 'TRANSIT' &&
              step['transit_details'] != null) {
            final transitDetail =
                step['transit_details'] as Map<String, dynamic>;
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
        for (final step in leg['steps'] ?? []) {
          steps.add(
            RouteStep.fromJson({
              'instructions': step['html_instructions'],
              'start_location': step['start_location'],
              'end_location': step['end_location'],
              'distance': step['distance'],
              'duration': step['duration'],
              'travel_mode': step['travel_mode'],
            }),
          );
        }

        routes.add(
          RouteModel(
            origin: origin,
            destination: destination,
            steps: steps,
            totalDistance: (leg['distance']?['value'] ?? 0).toDouble(),
            totalDuration: leg['duration']?['value'] ?? 0,
            summary: routeJson['summary'],
            polyline: routeJson['overview_polyline']?['points'],
            transportMode: 'public_transit',
            transitDetails: transitDetails,
          ),
        );
      }

      return routes;
    } catch (e) {
      // Log and return empty so the UI can fail gracefully
      // instead of crashing.
      // ignore: avoid_print
      if (kIsWeb) {
        print('Error getting transit routes (Web CORS issue): $e');
        if (AppConstants.corsProxyUrl == null) {
          print('Note: Google Maps Directions API REST doesn\'t support CORS from browsers.');
          print('To fix: Set AppConstants.corsProxyUrl to your backend proxy URL.');
        }
      } else {
        print('Error getting transit routes: $e');
      }
      return [];
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

  /// Optional helper for live arrivals using `TransitService`.
  Future<Map<String, dynamic>?> getRealtimeArrivals() async {
    try {
      return await _transitService.getLAMetroUpdates();
    } catch (e) {
      // ignore: avoid_print
      print('Error getting real-time arrivals: $e');
      return null;
    }
  }
}

