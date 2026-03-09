import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../models/landmark_model.dart';
import '../models/location_model.dart';
import '../utils/constants.dart';

/// EventsService - fetches nearby events (e.g., from Ticketmaster).
///
/// NOTE: This uses the Ticketmaster Discovery API. Make sure you set
/// `ticketmasterApiKey` in `AppConstants` with your own key.
class EventsService {
  final Dio _dio = Dio();
  final String _apiKey = AppConstants.ticketmasterApiKey;
  final String _baseUrl = 'https://app.ticketmaster.com/discovery/v2';

  Future<List<LandmarkModel>> getNearbyEvents({
    required double latitude,
    required double longitude,
    int radiusMiles = 5,
  }) async {
    if (_apiKey.isEmpty || _apiKey.trim().isEmpty) {
      // ignore: avoid_print
      print('⚠️ Ticketmaster API key is not set. Please add your API key in lib/utils/constants.dart');
      return [];
    }

    try {
      // Get today's date in ISO 8601 format (YYYY-MM-DDTHH:mm:ssZ)
      // Ticketmaster API expects startDateTime in ISO format
      final now = DateTime.now();
      final startDateTime = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(
        DateTime(now.year, now.month, now.day, 0, 0, 0).toUtc(),
      );

      final url = Uri.parse('$_baseUrl/events.json');
      final response = await _dio.get(
        url.toString(),
        queryParameters: {
          'apikey': _apiKey,
          'latlong': '$latitude,$longitude',
          'radius': radiusMiles.toString(),
          'unit': 'miles',
          'size': '20',
          'sort': 'date,asc',
          'startDateTime': startDateTime, // Only show events from today onwards
        },
        options: Options(
          validateStatus: (status) => status! < 500, // Accept 4xx as valid responses
        ),
      );

      // Check for API errors
      if (response.statusCode == 401 || response.statusCode == 403) {
        // ignore: avoid_print
        print('❌ Ticketmaster API authentication failed. Check your API key.');
        return [];
      }

      if (response.statusCode != 200) {
        // ignore: avoid_print
        print('⚠️ Ticketmaster API returned status ${response.statusCode}: ${response.data}');
        return [];
      }

      final data = response.data;
      if (data == null) {
        // ignore: avoid_print
        print('⚠️ Ticketmaster API returned null data');
        return [];
      }

      // Check for error messages in response
      if (data['errors'] != null) {
        // ignore: avoid_print
        print('❌ Ticketmaster API errors: ${data['errors']}');
        return [];
      }

      // Check if _embedded exists
      if (data['_embedded'] == null) {
        // ignore: avoid_print
        print('ℹ️ No events found near this location (empty _embedded)');
        return [];
      }

      final eventsList = data['_embedded']['events'];
      if (eventsList == null || (eventsList is List && eventsList.isEmpty)) {
        // ignore: avoid_print
        print('ℹ️ No events found near this location');
        return [];
      }

      final allEvents = List<Map<String, dynamic>>.from(eventsList as List);
      
      // Filter to only show events happening TODAY (client-side filtering)
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      
      final todayEvents = allEvents.where((event) {
        final eventDateStr = event['dates']?['start']?['localDate']?.toString() ?? '';
        if (eventDateStr.isEmpty) return false;
        
        try {
          // Parse event date (format: YYYY-MM-DD)
          final eventDate = DateTime.parse(eventDateStr);
          final eventDateStart = DateTime(eventDate.year, eventDate.month, eventDate.day);
          
          // Only include events happening TODAY
          return eventDateStart.isAtSameMomentAs(todayStart);
        } catch (e) {
          // If date parsing fails, exclude the event
          return false;
        }
      }).toList();
      
      // ignore: avoid_print
      print('✅ Found ${todayEvents.length} events for today (filtered from ${allEvents.length} total)');
      return todayEvents.map(_mapEventToLandmark).toList();
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error fetching events from Ticketmaster: $e');
      if (e is DioException) {
        // ignore: avoid_print
        print('   Response: ${e.response?.data}');
        // ignore: avoid_print
        print('   Status: ${e.response?.statusCode}');
      }
      return [];
    }
  }

  LandmarkModel _mapEventToLandmark(Map<String, dynamic> event) {
    final name = event['name']?.toString() ?? 'Event';
    final venues = event['_embedded']?['venues'] as List<dynamic>? ?? [];
    final venue = venues.isNotEmpty ? venues.first as Map<String, dynamic> : {};
    final addressObj = venue['address'] ?? {};
    final addressLine = addressObj['line1'] ?? '';
    final city = venue['city']?['name'] ?? '';
    final state = venue['state']?['stateCode'] ?? '';
    final postal = venue['postalCode'] ?? '';

    final fullAddress = [
      addressLine,
      if (city.toString().isNotEmpty || state.toString().isNotEmpty)
        '$city, $state',
      if (postal.toString().isNotEmpty) postal,
    ].where((p) => p.toString().trim().isNotEmpty).join(', ');

    final loc = venue['location'] ?? {};
    final lat = (loc['latitude'] != null)
        ? double.tryParse(loc['latitude'].toString()) ?? 0
        : 0.0;
    final lng = (loc['longitude'] != null)
        ? double.tryParse(loc['longitude'].toString()) ?? 0
        : 0.0;

    final location = LocationModel(
      latitude: lat,
      longitude: lng,
      address: fullAddress.isNotEmpty ? fullAddress : null,
      name: venue['name']?.toString(),
    );

    final startDate = event['dates']?['start']?['localDate'] ?? '';
    final startTime = event['dates']?['start']?['localTime'] ?? '';

    // Format date/time for display
    String? eventDateTime;
    if (startDate.isNotEmpty) {
      try {
        // Parse date and format it nicely (e.g., "Jan 15, 2024")
        final date = DateTime.parse(startDate);
        final formattedDate = DateFormat('MMM d, yyyy').format(date);
        
        if (startTime.isNotEmpty) {
          // Parse time and format it (e.g., "7:30 PM")
          try {
            final timeParts = startTime.split(':');
            if (timeParts.length >= 2) {
              final hour = int.parse(timeParts[0]);
              final minute = int.parse(timeParts[1]);
              final period = hour >= 12 ? 'PM' : 'AM';
              final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
              eventDateTime = '$formattedDate at $displayHour:${minute.toString().padLeft(2, '0')} $period';
            } else {
              eventDateTime = '$formattedDate at $startTime';
            }
          } catch (e) {
            eventDateTime = '$formattedDate at $startTime';
          }
        } else {
          eventDateTime = formattedDate;
        }
      } catch (e) {
        // Fallback to raw date if parsing fails
        eventDateTime = startDate;
        if (startTime.isNotEmpty) {
          eventDateTime = '$startDate at $startTime';
        }
      }
    }

    // Combine address with event date/time
    final displayAddress = fullAddress.isNotEmpty 
        ? (eventDateTime != null ? '$fullAddress • $eventDateTime' : fullAddress)
        : eventDateTime;

    final types = <String>['event'];

    return LandmarkModel(
      id: event['id']?.toString() ?? '',
      name: name,
      address: displayAddress,
      location: location,
      types: types,
      isAccessible: false,
      accessibilityOptions: null,
      distance: null,
      rating: null,
      priceLevel: null,
    );
  }
}


