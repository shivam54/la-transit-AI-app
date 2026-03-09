import '../services/places_service.dart';
import '../models/location_model.dart';

/// AI Summary Service - Gemini AI summaries via Google Places API
class AISummaryService {
  final PlacesService _placesService = PlacesService();

  /// Get AI summary for a destination
  Future<Map<String, dynamic>?> getDestinationSummary({
    required String placeId,
    required LocationModel location,
    String? originalDestination,
  }) async {
    try {
      // Try to find summary with fallback logic
      final summary = await _placesService.findSummaryWithFallback(
        placeId: placeId,
        latitude: location.latitude,
        longitude: location.longitude,
        originalDestination: originalDestination,
      );

      return summary;
    } catch (e) {
      print('Error getting AI summary: $e');
      return null;
    }
  }

  /// Get place details with summary
  Future<Map<String, dynamic>?> getPlaceDetailsWithSummary(String placeId) async {
    try {
      return await _placesService.getPlaceWithSummary(placeId);
    } catch (e) {
      print('Error getting place details: $e');
      return null;
    }
  }
}

