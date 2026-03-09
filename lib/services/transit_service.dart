import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../utils/constants.dart';

/// Transit Service - LA Metro and Metrolink API integration
class TransitService {
  final String laMetroApiKey = AppConstants.laMetroApiKey;
  final String metrolinkApiKey = AppConstants.metrolinkApiKey;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 15),
  ));

  /// After calling getArrivalsFromTripUpdates with backend: true if backend said route had no predictions in feed.
  bool? lastRouteFoundInCache;

  /// True if route is LADOT DASH (A, B, D, E, F). Swiftly lametro does not support DASH — do not call goswift.ly for these.
  static bool _isDASHRoute(String routeId) {
    if (routeId.isEmpty) return false;
    final r = routeId.trim().toUpperCase();
    if (const ['A', 'B', 'D', 'E', 'F'].contains(r)) return true;
    final rl = r.toLowerCase();
    if (rl.startsWith('dash') || rl.startsWith('route')) {
      final letter = rl.replaceAll(RegExp(r'^(dash|route)\s*'), '').trim();
      return const ['a', 'b', 'd', 'e', 'f'].contains(letter);
    }
    return false;
  }

  /// Test API key validity using Swiftly test-key endpoint
  Future<bool> testApiKey() async {
    try {
      final response = await _dio.get(
        'https://api.goswift.ly/test-key',
        options: Options(
          headers: {
            'Authorization': laMetroApiKey,
            'Accept': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final success = data is Map && data['success'] == true;
        // ignore: avoid_print
        print('🔑 API Key test: ${success ? "✅ Valid" : "❌ Invalid"} - ${response.data}');
        return success;
      }
      // ignore: avoid_print
      print('🔑 API Key test: ❌ Failed with status ${response.statusCode}');
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('❌ API Key test failed: $e');
      return false;
    }
  }

  /// Get real-time transit updates from LA Metro.
  /// When [transitApiBaseUrl] is set, uses backend to avoid CORS (browser cannot call api.goswift.ly directly).
  Future<Map<String, dynamic>?> getLAMetroUpdates({
    String? stopId,
    String? routeId,
  }) async {
    final baseUrl = AppConstants.transitApiBaseUrl;
    if (baseUrl != null && baseUrl.isNotEmpty) {
      try {
        final uri = Uri.parse('$baseUrl/health');
        final response = await _dio.get(
          uri.toString(),
          options: Options(validateStatus: (status) => status! < 500),
        );
        if (response.statusCode == 200) {
          return {'status': 'success', 'data': response.data};
        }
      } catch (e) {
        print('Transit backend health check failed: $e');
      }
      return null;
    }
    try {
      final url = Uri.parse('https://api.goswift.ly/realtime/gtfs-rt/tripupdates');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $laMetroApiKey',
        },
      );
      if (response.statusCode == 200) {
        return {'status': 'success', 'data': response.body};
      }
      return null;
    } catch (e) {
      print('Error getting LA Metro updates: $e');
      return null;
    }
  }

  /// Get Metrolink updates
  Future<Map<String, dynamic>?> getMetrolinkUpdates() async {
    try {
      final url = Uri.parse('https://api.metrolinktrains.com/gtfs-rt/tripupdates');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $metrolinkApiKey',
        },
      );

      if (response.statusCode == 200) {
        return {'status': 'success', 'data': response.body};
      }
      
      return null;
    } catch (e) {
      print('Error getting Metrolink updates: $e');
      return null;
    }
  }

  /// Get stop information
  Future<Map<String, dynamic>?> getStopInfo(String stopId) async {
    try {
      // This would typically use the GTFS static data
      // For now, return a placeholder
      return {
        'stopId': stopId,
        'name': 'Stop $stopId',
        'routes': [],
      };
    } catch (e) {
      print('Error getting stop info: $e');
      return null;
    }
  }

  /// Get real-time arrivals for a stop using Swiftly API
  /// 
  /// Parameters:
  /// - stopId: The GTFS stop ID (optional, can use location if not available)
  /// - routeId: The route number (e.g., "4", "81")
  /// - latitude: Stop latitude (if stopId not available)
  /// - longitude: Stop longitude (if stopId not available)
  Future<List<Map<String, dynamic>>> getRealtimeArrivals({
    String? stopId,
    String? routeId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Swiftly API endpoint for stop times (arrivals)
      // Format: https://api.goswift.ly/realtime/lametro/gtfs-rt-stop-times?format=json
      String url = 'https://api.goswift.ly/realtime/lametro/gtfs-rt-stop-times?format=json';
      
      // Add query parameters if available
      final queryParams = <String, String>{};
      if (stopId != null && stopId.isNotEmpty) {
        queryParams['stop_id'] = stopId;
      }
      if (routeId != null && routeId.isNotEmpty) {
        queryParams['route_id'] = routeId;
      }
      if (latitude != null && longitude != null) {
        queryParams['lat'] = latitude.toString();
        queryParams['lon'] = longitude.toString();
      }

      if (queryParams.isNotEmpty) {
        url += '&${Uri(queryParameters: queryParams).query}';
      }

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': laMetroApiKey,
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Parse Swiftly response format
        // The response structure may vary, but typically contains stop_time_updates
        if (data is Map) {
          final entities = data['entity'] as List<dynamic>? ?? [];
          final arrivals = <Map<String, dynamic>>[];
          
          for (final entity in entities) {
            if (entity is Map) {
              final tripUpdate = entity['trip_update'];
              if (tripUpdate != null && tripUpdate is Map) {
                final trip = tripUpdate['trip'] as Map?;
                final stopTimeUpdates = tripUpdate['stop_time_update'] as List<dynamic>? ?? [];
                
                for (final stopTimeUpdate in stopTimeUpdates) {
                  if (stopTimeUpdate is Map) {
                    final arrival = stopTimeUpdate['arrival'];
                    final departure = stopTimeUpdate['departure'];
                    final stopId = stopTimeUpdate['stop_id']?.toString();
                    
                    if (arrival != null || departure != null) {
                      final time = arrival?['time'] ?? departure?['time'];
                      final delay = arrival?['delay'] ?? departure?['delay'] ?? 0;
                      
                      if (time != null) {
                        final routeIdFromTrip = trip?['route_id']?.toString() ?? routeId ?? 'Unknown';
                        final tripId = trip?['trip_id']?.toString() ?? '';
                        final headsign = trip?['trip_headsign']?.toString() ?? '';
                        
                        arrivals.add({
                          'stop_id': stopId,
                          'route_id': routeIdFromTrip,
                          'trip_id': tripId,
                          'headsign': headsign,
                          'arrival_time': DateTime.fromMillisecondsSinceEpoch(time * 1000).toLocal(),
                          'delay': delay,
                          'minutes_until_arrival': _calculateMinutesUntilArrival(time),
                        });
                      }
                    }
                  }
                }
              }
            }
          }
          
          // Sort by arrival time
          arrivals.sort((a, b) {
            final timeA = a['arrival_time'] as DateTime;
            final timeB = b['arrival_time'] as DateTime;
            return timeA.compareTo(timeB);
          });
          
          return arrivals.take(10).toList(); // Return next 10 arrivals
        }
      }
      
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('Error getting real-time arrivals: $e');
      return [];
    }
  }

  /// Resolve departure stop to stop_id using backend GTFS lookup (by name or lat/lon).
  /// Use when Google Directions does not provide stop_id so we can filter arrivals by your stop.
  Future<String?> resolveStopId({
    String? stopName,
    double? latitude,
    double? longitude,
  }) async {
    final baseUrl = AppConstants.transitApiBaseUrl;
    if (baseUrl == null || baseUrl.isEmpty) return null;
    try {
      final queryParams = <String, String>{};
      if (stopName != null && stopName.trim().isNotEmpty) queryParams['name'] = stopName.trim();
      if (latitude != null) queryParams['lat'] = latitude.toString();
      if (longitude != null) queryParams['lon'] = longitude.toString();
      if (queryParams.isEmpty) return null;
      final uri = Uri.parse('$baseUrl/api/transit/stops').replace(queryParameters: queryParams);
      final response = await _dio.get(uri.toString(), options: Options(validateStatus: (status) => status! < 500));
      if (response.statusCode != 200) return null;
      final data = response.data;
      if (data is! Map || data['success'] != true) return null;
      final list = data['data'] as List<dynamic>?;
      final first = list != null && list.isNotEmpty && list.first is Map ? list.first as Map : null;
      final id = first?['stop_id']?.toString();
      return id != null && id.isNotEmpty ? id : null;
    } catch (e) {
      return null;
    }
  }

  /// Calculate minutes until arrival
  int _calculateMinutesUntilArrival(int timestampSeconds) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diff = timestampSeconds - now;
    return (diff / 60).round();
  }

  /// Fetch arrivals from our transit backend (GTFS-RT cache). Returns empty list on error.
  /// [stopName] is used for DASH so the backend can resolve LADOT stop_id from name (departure stop).
  Future<List<Map<String, dynamic>>> _getArrivalsFromBackend({
    required String routeId,
    double? latitude,
    double? longitude,
    String? stopId,
    String? stopName,
    required String baseUrl,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/transit/predictions').replace(
        queryParameters: <String, String>{
          if (routeId.isNotEmpty) 'route': routeId,
          if (stopId != null && stopId.isNotEmpty) 'stop_id': stopId,
          if (stopName != null && stopName.isNotEmpty) 'stop_name': stopName,
          if (latitude != null) 'lat': latitude.toString(),
          if (longitude != null) 'lon': longitude.toString(),
          'limit': '15',
        },
      );
      // ignore: avoid_print
      print('🔍 Transit backend request: $uri');
      final response = await _dio.get(
        uri.toString(),
        options: Options(validateStatus: (status) => status! < 500),
      );
      if (response.statusCode != 200) return [];
      final data = response.data;
      if (data is! Map || data['success'] != true) return [];
      lastRouteFoundInCache = data['routeFoundInCache'] as bool?;
      final list = data['data'] as List<dynamic>?;
      if (list == null) return [];
      final arrivals = <Map<String, dynamic>>[];
      for (final e in list) {
        if (e is! Map) continue;
        final arrivalTimeStr = e['arrival_time']?.toString();
        DateTime? arrivalTime;
        if (arrivalTimeStr != null) {
          try {
            // Backend sends ISO UTC (e.g. ...Z); convert to local for display
            arrivalTime = DateTime.parse(arrivalTimeStr).toLocal();
          } catch (_) {}
        }
        if (arrivalTime == null) continue;
        final stopName = e['stop_name']?.toString()?.trim() ?? '';
        arrivals.add({
          'route_id': e['route_id']?.toString() ?? '',
          'trip_id': e['trip_id']?.toString() ?? '',
          'vehicle_id': e['vehicle_id']?.toString() ?? '',
          'headsign': e['headsign']?.toString() ?? '',
          'stop_id': e['stop_id']?.toString(),
          'stop_name': stopName.isNotEmpty ? stopName : null,
          'arrival_time': arrivalTime,
          'minutes_until_arrival': (e['minutes_until_arrival'] is int)
              ? e['minutes_until_arrival'] as int
              : ((e['minutes_until_arrival'] is num) ? (e['minutes_until_arrival'] as num).round() : 0),
          'delay': (e['delay'] is int) ? e['delay'] as int : 0,
        });
      }
      // ignore: avoid_print
      print('✅ Transit backend: ${arrivals.length} arrivals for route $routeId');
      return arrivals;
    } catch (e) {
      // ignore: avoid_print
      print('Transit backend predictions error: $e');
      return [];
    }
  }

  /// Get arrivals using predictions endpoint or transit backend (GTFS-RT cache).
  /// When [AppConstants.transitApiBaseUrl] is set, uses backend /api/transit/predictions to avoid 403.
  /// For DASH routes, passing [stopName] (e.g. departure stop "Jefferson / Vermont") lets the backend resolve LADOT stop_id so arrivals at your stop are shown.
  Future<List<Map<String, dynamic>>> getArrivalsFromTripUpdates({
    required String routeId,
    double? latitude,
    double? longitude,
    String? stopId,
    String? stopName,
  }) async {
    lastRouteFoundInCache = null;
    // Use transit backend when configured (GTFS-RT cache; works on mobile + web, no 403)
    final baseUrl = AppConstants.transitApiBaseUrl;
    if (baseUrl != null && baseUrl.isNotEmpty) {
      final list = await _getArrivalsFromBackend(
        routeId: routeId,
        latitude: latitude,
        longitude: longitude,
        stopId: stopId,
        stopName: stopName,
        baseUrl: baseUrl,
      );
      if (list.isNotEmpty) return list;
      // Do not fall back to Swiftly for DASH routes — Swiftly lametro does not support LADOT DASH (403).
      if (_isDASHRoute(routeId)) return list;
      // Fallback to Swiftly if backend returned empty (e.g. cache not ready yet)
    }

    try {
      // Use the working predictions endpoint
      String url;
      
      // Build route parameter - Swiftly supports comma-separated routes like "35,38"
      String? routeParam;
      if (routeId.isNotEmpty) {
        if (routeId.contains('/')) {
          routeParam = routeId.split('/').map((r) => r.trim()).where((r) => r.isNotEmpty).join(',');
        } else {
          routeParam = routeId;
        }
      }
      
      // Based on Swiftly docs:
      // - /real-time/{agencyKey}/predictions?stop={stopId}&route={route}
      // - /real-time/{agencyKey}/predictions-near-location?lat={lat}&lon={lon}&route={route}
      if (stopId != null && stopId.isNotEmpty) {
        url = 'https://api.goswift.ly/real-time/lametro/predictions?stop=$stopId';
        if (routeParam != null && routeParam.isNotEmpty) {
          url += '&route=$routeParam';
        }
      } else if (latitude != null && longitude != null) {
        url = 'https://api.goswift.ly/real-time/lametro/predictions-near-location?lat=$latitude&lon=$longitude';
        if (routeParam != null && routeParam.isNotEmpty) {
          url += '&route=$routeParam';
        }
      } else {
        // Need location for predictions-near-location, use provided lat/lng or skip
        if (latitude != null && longitude != null) {
          url = 'https://api.goswift.ly/real-time/lametro/predictions-near-location?lat=$latitude&lon=$longitude';
          if (routeParam != null && routeParam.isNotEmpty) {
            url += '&route=$routeParam';
          }
        } else {
          // Can't make predictions call without stop or location
          return [];
        }
      }
      
      // ignore: avoid_print
      print('🔍 Swiftly API Request: $url (filtering for route: $routeId)');
      
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': laMetroApiKey, // API key in Authorization header
            'Accept': 'application/json',
          },
          validateStatus: (status) => status! < 500, // Don't throw on 4xx
        ),
      );

      // ignore: avoid_print
      print('📡 Swiftly API Response: Status ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        final arrivals = <Map<String, dynamic>>[];
        
        // Swiftly Predictions API response format:
        // { "success": true, "data": [{ "route": {...}, "predictions": [...] }] }
        // OR for predictions-near-location:
        // { "success": true, "data": { "predictionsData": [...] } }
        List<dynamic>? predictionsList;
        
        if (data is Map && data['success'] == true) {
          final dataObj = data['data'];
          
          if (dataObj is List) {
            // Format: data is array of route predictions
            for (final routeData in dataObj) {
              if (routeData is Map) {
                final routeInfo = routeData['route'] as Map?;
                final routeName = routeInfo?['routeShortName']?.toString() ?? 
                                routeInfo?['routeId']?.toString() ?? '';
                final predictions = routeData['predictions'] as List<dynamic>?;
                
                if (predictions != null) {
                  for (final pred in predictions) {
                    if (pred is Map) {
                      final sec = pred['sec'] as int?;
                      final time = pred['time'] as int?; // Unix timestamp
                      final vehicleId = pred['vehicleId']?.toString() ?? '';
                      final tripId = pred['tripId']?.toString() ?? '';
                      
                      if (sec != null && sec >= 0) {
                        final arrivalTime = DateTime.now().add(Duration(seconds: sec));
                        arrivals.add({
                          'route_id': routeName,
                          'trip_id': tripId,
                          'headsign': routeData['destinations']?[0]?['headsign']?.toString() ?? '',
                          'stop_id': routeInfo?['stopId']?.toString() ?? '',
                          'arrival_time': arrivalTime,
                          'delay': 0,
                          'minutes_until_arrival': (sec / 60).round(),
                        });
                      } else if (time != null) {
                        final arrivalTime = DateTime.fromMillisecondsSinceEpoch(time * 1000);
                        final minutes = _calculateMinutesUntilArrival(time);
                        if (minutes >= 0) {
                          arrivals.add({
                            'route_id': routeName,
                            'trip_id': tripId,
                            'headsign': routeData['destinations']?[0]?['headsign']?.toString() ?? '',
                            'stop_id': routeInfo?['stopId']?.toString() ?? '',
                            'arrival_time': arrivalTime,
                            'delay': 0,
                            'minutes_until_arrival': minutes,
                          });
                        }
                      }
                    }
                  }
                }
              }
            }
          } else if (dataObj is Map) {
            // Format: predictions-near-location returns predictionsData array
            final predictionsData = dataObj['predictionsData'] as List<dynamic>?;
            if (predictionsData != null) {
              for (final stopData in predictionsData) {
                if (stopData is Map) {
                  final destinations = stopData['destinations'] as List<dynamic>?;
                  if (destinations != null) {
                    for (final dest in destinations) {
                      if (dest is Map) {
                        final predictions = dest['predictions'] as List<dynamic>?;
                        if (predictions != null) {
                          for (final pred in predictions) {
                            if (pred is Map) {
                              final sec = pred['sec'] as int?;
                              final time = pred['time'] as int?;
                              final vehicleId = pred['vehicleId']?.toString() ?? '';
                              final tripId = pred['tripId']?.toString() ?? '';
                              
                              if (sec != null && sec >= 0) {
                                final arrivalTime = DateTime.now().add(Duration(seconds: sec));
                                arrivals.add({
                                  'route_id': stopData['routeShortName']?.toString() ?? '',
                                  'trip_id': tripId,
                                  'headsign': dest['headsign']?.toString() ?? '',
                                  'stop_id': stopData['stopId']?.toString() ?? '',
                                  'arrival_time': arrivalTime,
                                  'delay': 0,
                                  'minutes_until_arrival': (sec / 60).round(),
                                });
                              } else if (time != null) {
                                final arrivalTime = DateTime.fromMillisecondsSinceEpoch(time * 1000);
                                final minutes = _calculateMinutesUntilArrival(time);
                                if (minutes >= 0) {
                                  arrivals.add({
                                    'route_id': stopData['routeShortName']?.toString() ?? '',
                                    'trip_id': tripId,
                                    'headsign': dest['headsign']?.toString() ?? '',
                                    'stop_id': stopData['stopId']?.toString() ?? '',
                                    'arrival_time': arrivalTime,
                                    'delay': 0,
                                    'minutes_until_arrival': minutes,
                                  });
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        
        // ignore: avoid_print
        print('✅ Parsed ${arrivals.length} arrivals for route $routeId');
        
        // Sort by arrival time
        arrivals.sort((a, b) {
          final timeA = a['arrival_time'] as DateTime;
          final timeB = b['arrival_time'] as DateTime;
          return timeA.compareTo(timeB);
        });
        
        return arrivals.take(10).toList();
      } else if (response.statusCode == 404) {
        // ignore: avoid_print
        print('⚠️ Swiftly API endpoint not found (404). Response: ${response.data}');
        // ignore: avoid_print
        print('🔄 Trying alternative endpoint format...');
        // Try alternative endpoint format
        return await _tryAlternativeEndpoint(routeId, latitude, longitude, stopId);
      } else {
        // ignore: avoid_print
        print('❌ Swiftly API error: Status ${response.statusCode}, Response: ${response.data}');
      }
      
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('Error getting arrivals from trip updates: $e');
      return [];
    }
  }

  /// Try alternative Swiftly API endpoint format
  Future<List<Map<String, dynamic>>> _tryAlternativeEndpoint(
    String routeId,
    double? latitude,
    double? longitude,
    String? stopId,
  ) async {
    try {
      // Try the /realtime endpoint format (without hyphen)
      String url;
      
      if (stopId != null && stopId.isNotEmpty) {
        url = 'https://api.goswift.ly/realtime/lametro/predictions?stop=$stopId';
      } else if (latitude != null && longitude != null) {
        url = 'https://api.goswift.ly/realtime/lametro/predictions?lat=$latitude&lon=$longitude';
      } else {
        url = 'https://api.goswift.ly/realtime/lametro/predictions?route=$routeId';
      }
      
      // ignore: avoid_print
      print('🔄 Trying alternative endpoint: $url');
      
      // Try different authentication formats for vehicles endpoint
      var response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': laMetroApiKey,
            'Accept': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );
      
      // If 403, try with Bearer prefix
      if (response.statusCode == 403) {
        // ignore: avoid_print
        print('⚠️ Vehicles API: Got 403 with direct key, trying Bearer format...');
        response = await _dio.get(
          url,
          options: Options(
            headers: {
              'Authorization': 'Bearer $laMetroApiKey',
              'Accept': 'application/json',
            },
            validateStatus: (status) => status! < 500,
          ),
        );
      }
      
      // If still 403, try X-API-Key header
      if (response.statusCode == 403) {
        // ignore: avoid_print
        print('⚠️ Vehicles API: Got 403 with Bearer, trying X-API-Key header...');
        response = await _dio.get(
          url,
          options: Options(
            headers: {
              'X-API-Key': laMetroApiKey,
              'Accept': 'application/json',
            },
            validateStatus: (status) => status! < 500,
          ),
        );
      }

      if (response.statusCode == 200) {
        // Parse the same way as main method
        return await _parsePredictionsResponse(response.data, routeId);
      }
      
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('Error trying alternative endpoint: $e');
      return [];
    }
  }

  /// Parse predictions response from Swiftly API
  Future<List<Map<String, dynamic>>> _parsePredictionsResponse(
    dynamic data,
    String routeId,
  ) async {
    final arrivals = <Map<String, dynamic>>[];
    
    if (data is Map) {
      final predictions = data['predictions'] as List<dynamic>? ?? 
                         data['data'] as List<dynamic>? ?? 
                         (data is List ? data : null);
      
      if (predictions != null && predictions is List) {
        for (final prediction in predictions) {
          if (prediction is Map) {
            final predRouteId = prediction['routeId']?.toString() ?? 
                               prediction['route_id']?.toString() ?? '';
            
            if (routeId.isEmpty || predRouteId == routeId || predRouteId.contains(routeId)) {
              final minutesUntil = prediction['minutesUntil'] as int? ?? 
                                  prediction['minutes_until'] as int?;
              final arrivalTimeStr = prediction['arrivalTime']?.toString() ?? 
                                    prediction['arrival_time']?.toString();
              
              if (minutesUntil != null || arrivalTimeStr != null) {
                DateTime? arrivalTime;
                int? minutes;
                
                if (minutesUntil != null) {
                  arrivalTime = DateTime.now().add(Duration(minutes: minutesUntil));
                  minutes = minutesUntil;
                } else if (arrivalTimeStr != null) {
                  try {
                    arrivalTime = DateTime.parse(arrivalTimeStr).toLocal();
                    minutes = _calculateMinutesUntilArrival(arrivalTime.millisecondsSinceEpoch ~/ 1000);
                  } catch (e) {
                    continue;
                  }
                }
                
                if (arrivalTime != null && minutes != null && minutes >= 0) {
                  arrivals.add({
                    'route_id': predRouteId,
                    'trip_id': prediction['tripId']?.toString() ?? '',
                    'headsign': prediction['headsign']?.toString() ?? 
                               prediction['destination']?.toString() ?? '',
                    'stop_id': prediction['stopId']?.toString() ?? 
                              prediction['stop_id']?.toString(),
                    'arrival_time': arrivalTime,
                    'delay': prediction['delay'] as int? ?? 0,
                    'minutes_until_arrival': minutes,
                  });
                }
              }
            }
          }
        }
      }
    }
    
    arrivals.sort((a, b) {
      final timeA = a['arrival_time'] as DateTime;
      final timeB = b['arrival_time'] as DateTime;
      return timeA.compareTo(timeB);
    });
    
    return arrivals.take(10).toList();
  }

  /// Fetch vehicle positions from our transit backend.
  /// Uses same Swiftly REST /vehicles API as Metro.net when source=swiftly (fewer, filtered vehicles).
  Future<List<Map<String, dynamic>>> _getVehiclesFromBackend({
    String? routeId,
    required String baseUrl,
    bool useSwiftlyRest = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/transit/vehicles').replace(
        queryParameters: <String, String>{
          if (routeId != null && routeId.isNotEmpty) 'route': routeId,
          if (useSwiftlyRest) 'source': 'swiftly',
        },
      );
      // ignore: avoid_print
      print('🚌 Transit backend vehicles: $uri');
      final response = await _dio.get(
        uri.toString(),
        options: Options(validateStatus: (status) => status! < 500),
      );
      if (response.statusCode != 200) return [];
      final data = response.data;
      if (data is! Map || data['success'] != true) return [];
      final list = data['data'] as List<dynamic>?;
      if (list == null) return [];
      final vehicles = <Map<String, dynamic>>[];
      for (final v in list) {
        if (v is! Map) continue;
        final lat = v['latitude'];
        final lon = v['longitude'];
        if (lat == null || lon == null) continue;
        final stopName = v['stop_name']?.toString()?.trim() ?? '';
        final nextStopName = v['next_stop_name']?.toString()?.trim() ?? '';
        final minutesUntilNext = v['minutes_until_next_stop'];
        vehicles.add({
          'vehicle_id': v['vehicle_id']?.toString() ?? '',
          'route_id': v['route_id']?.toString() ?? '',
          'latitude': (lat is num) ? lat.toDouble() : double.tryParse(lat.toString()) ?? 0.0,
          'longitude': (lon is num) ? lon.toDouble() : double.tryParse(lon.toString()) ?? 0.0,
          'bearing': (v['bearing'] is num) ? (v['bearing'] as num).toDouble() : 0.0,
          'speed': (v['speed'] is num) ? (v['speed'] as num).toDouble() : 0.0,
          'headsign': v['headsign']?.toString() ?? '',
          'next_stop': nextStopName.isNotEmpty ? nextStopName : (stopName.isNotEmpty ? stopName : (v['stop_id']?.toString() ?? '')),
          'minutes_until_next_stop': minutesUntilNext is int ? minutesUntilNext : (minutesUntilNext is num ? (minutesUntilNext as num).round() : null),
          'last_update': v['last_update']?.toString() ?? '',
        });
      }
      // ignore: avoid_print
      print('✅ Transit backend: ${vehicles.length} vehicles');
      return vehicles;
    } catch (e) {
      // ignore: avoid_print
      print('Transit backend vehicles error: $e');
      return [];
    }
  }

  /// Get real-time vehicle positions for a route
  /// Returns list of vehicles with their current positions
  /// When [AppConstants.transitApiBaseUrl] is set, uses backend /api/transit/vehicles (GTFS-RT cache) to avoid 403.
  /// DASH routes (A, B, D, E, F) are only supported via backend; Swiftly lametro returns 403 for them.
  Future<List<Map<String, dynamic>>> getVehiclePositions({
    String? routeId,
    double? latitude,
    double? longitude,
  }) async {
    final baseUrl = AppConstants.transitApiBaseUrl;
    final isDASH = routeId != null && _isDASHRoute(routeId);

    if (baseUrl != null && baseUrl.isNotEmpty) {
      // DASH routes: use backend cache only (no Swiftly); backend returns DASH vehicles from GTFS-RT
      final useCacheOnly = isDASH;
      var list = await _getVehiclesFromBackend(
        routeId: routeId,
        baseUrl: baseUrl,
        useSwiftlyRest: !useCacheOnly,
      );
      if (list.isEmpty && !useCacheOnly) {
        list = await _getVehiclesFromBackend(routeId: routeId, baseUrl: baseUrl, useSwiftlyRest: false);
      }
      if (list.isNotEmpty) return list;
      return list;
    }

    // No backend: DASH is not available from Swiftly (403). Avoid calling goswift.ly for DASH.
    if (isDASH) {
      print('DASH route $routeId requires backend (transitApiBaseUrl). Swiftly does not support DASH.');
      return [];
    }

    try {
      final allVehicles = <Map<String, dynamic>>[];
      
      // Build route parameter - Swiftly supports comma-separated routes like "35,38"
      String? routeParam;
      if (routeId != null && routeId.isNotEmpty) {
        if (routeId.contains('/')) {
          // Convert "35/38" to "35,38" for Swiftly API
          routeParam = routeId.split('/').map((r) => r.trim()).where((r) => r.isNotEmpty).join(',');
        } else {
          routeParam = routeId;
        }
      }
      
      // Try the Vehicles endpoint first (simpler format)
      // Endpoint: /real-time/{agencyKey}/vehicles
      // Supports route parameter as comma-separated: route=35,38
      String url = 'https://api.goswift.ly/real-time/lametro/vehicles';
      if (routeParam != null && routeParam.isNotEmpty) {
        url += '?route=$routeParam';
      }
      
      // ignore: avoid_print
      print('🚌 Fetching vehicle positions: $url');
      
      // Try different authentication formats
      // Format 1: Direct API key (as shown in docs)
      var response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': laMetroApiKey,
            'Accept': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );
      
      // If 403, try with Bearer prefix
      if (response.statusCode == 403) {
        // ignore: avoid_print
        print('⚠️ Got 403 with direct key, trying Bearer format...');
        response = await _dio.get(
          url,
          options: Options(
            headers: {
              'Authorization': 'Bearer $laMetroApiKey',
              'Accept': 'application/json',
            },
            validateStatus: (status) => status! < 500,
          ),
        );
      }
      
      // If still 403, try X-API-Key header
      if (response.statusCode == 403) {
        // ignore: avoid_print
        print('⚠️ Got 403 with Bearer, trying X-API-Key header...');
        response = await _dio.get(
          url,
          options: Options(
            headers: {
              'X-API-Key': laMetroApiKey,
              'Accept': 'application/json',
            },
            validateStatus: (status) => status! < 500,
          ),
        );
      }

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Swiftly Vehicles API response format:
        // { "data": { "vehicles": [...], "agencyKey": "...", "route": "...", "success": true } }
        if (data is Map) {
          final dataObj = data['data'] as Map?;
          if (dataObj != null) {
            final vehicles = dataObj['vehicles'] as List<dynamic>?;
            
            if (vehicles != null) {
              for (final vehicle in vehicles) {
                if (vehicle is Map) {
                  final loc = vehicle['loc'] as Map?;
                  if (loc != null) {
                    final lat = loc['lat'];
                    final lng = loc['lon'];
                    
                    if (lat != null && lng != null) {
                      allVehicles.add({
                        'vehicle_id': vehicle['id']?.toString() ?? '',
                        'route_id': vehicle['routeId']?.toString() ?? 
                                   vehicle['routeShortName']?.toString() ?? 
                                   routeParam ?? '',
                        'latitude': (lat as num).toDouble(),
                        'longitude': (lng as num).toDouble(),
                        'bearing': (loc['heading'] as num?)?.toDouble() ?? 0.0,
                        'speed': (loc['speed'] as num?)?.toDouble() ?? 0.0,
                        'headsign': vehicle['headsign']?.toString() ?? '',
                        'next_stop': vehicle['stopId']?.toString() ?? '',
                        'last_update': loc['time']?.toString() ?? 
                                      vehicle['timestamp']?.toString() ?? '',
                      });
                    }
                  }
                }
              }
            }
          }
        }
        
        // ignore: avoid_print
        print('✅ Found ${allVehicles.length} vehicles from Vehicles API');
        
        // If we got vehicles, return them
        if (allVehicles.isNotEmpty) {
          return allVehicles;
        }
      } else if (response.statusCode == 403) {
        // ignore: avoid_print
        print('❌ Vehicles API returned 403 Permission Denied');
        // ignore: avoid_print
        print('   This usually means your API key does not have access to the vehicles endpoint.');
        // ignore: avoid_print
        print('   Please check your Swiftly dashboard to ensure your API key has real-time vehicle access.');
      } else {
        // ignore: avoid_print
        print('⚠️ Vehicles API returned status ${response.statusCode}: ${response.data}');
      }
      
      // Fallback: Try GTFS-RT vehicle positions endpoint
      // Endpoint: /real-time/{agencyKey}/gtfs-rt-vehicle-positions?format=json
      final gtfsUrl = 'https://api.goswift.ly/real-time/lametro/gtfs-rt-vehicle-positions?format=json';
      
      // ignore: avoid_print
      print('🔄 Trying GTFS-RT vehicle positions endpoint...');
      
      try {
        final gtfsResponse = await _dio.get(
          gtfsUrl,
          options: Options(
            headers: {
              'Authorization': laMetroApiKey,
              'Accept': 'application/json',
            },
            validateStatus: (status) => status! < 500,
          ),
        );

        if (gtfsResponse.statusCode == 200) {
          final gtfsData = gtfsResponse.data;
          
          // GTFS-RT format: { "entity": [...] }
          if (gtfsData is Map) {
            final entities = gtfsData['entity'] as List<dynamic>?;
            
            if (entities != null) {
              for (final entity in entities) {
                if (entity is Map) {
                  final vehicle = entity['vehicle'] as Map?;
                  if (vehicle != null) {
                    final position = vehicle['position'] as Map?;
                    final trip = vehicle['trip'] as Map?;
                    
                    if (position != null) {
                      final lat = position['latitude'];
                      final lng = position['longitude'];
                      final routeIdFromTrip = trip?['route_id']?.toString() ?? '';
                      
                      // Filter by route if specified
                      if (routeParam == null || routeParam.isEmpty || 
                          routeParam.split(',').any((r) => routeIdFromTrip.contains(r.trim()))) {
                        if (lat != null && lng != null) {
                          allVehicles.add({
                            'vehicle_id': vehicle['vehicle']?['id']?.toString() ?? 
                                        entity['id']?.toString() ?? '',
                            'route_id': routeIdFromTrip.isNotEmpty ? routeIdFromTrip : routeParam ?? '',
                            'latitude': (lat as num).toDouble(),
                            'longitude': (lng as num).toDouble(),
                            'bearing': (position['bearing'] as num?)?.toDouble() ?? 0.0,
                            'speed': (position['speed'] as num?)?.toDouble() ?? 0.0,
                            'headsign': trip?['tripHeadsign']?.toString() ?? '',
                            'next_stop': vehicle['stop_id']?.toString() ?? '',
                            'last_update': vehicle['timestamp']?.toString() ?? 
                                          entity['timestamp']?.toString() ?? '',
                          });
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          
          // ignore: avoid_print
          print('✅ Found ${allVehicles.length} vehicles from GTFS-RT API');
        }
      } catch (e) {
        // ignore: avoid_print
        print('⚠️ GTFS-RT endpoint failed: $e');
      }
      
      return allVehicles;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error getting vehicle positions: $e');
      return [];
    }
  }
}

