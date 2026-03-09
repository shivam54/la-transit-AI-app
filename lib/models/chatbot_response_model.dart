import '../models/location_model.dart';

/// Chatbot response model - can contain text, actions, or structured data
class ChatbotResponse {
  final String text;
  final ChatbotAction? action;
  final List<LocationModel>? locations; // For nearby amenities
  final String? category; // For amenities category

  ChatbotResponse({
    required this.text,
    this.action,
    this.locations,
    this.category,
  });

  bool get hasAction => action != null;
  bool get hasLocations => locations != null && locations!.isNotEmpty;
}

/// Chatbot action types
enum ChatbotAction {
  planRoute, // Navigate to route planning with locations
  showAmenities, // Show nearby amenities list
  showWeather, // Show weather info
  none, // No action, just text response
}

/// Extracted location information from user message
class ExtractedLocation {
  String? originText;
  String? destinationText;
  LocationModel? origin;
  LocationModel? destination;

  ExtractedLocation({
    this.originText,
    this.destinationText,
    this.origin,
    this.destination,
  });

  bool get hasOrigin => origin != null || (originText != null && originText!.isNotEmpty);
  bool get hasDestination => destination != null || (destinationText != null && destinationText!.isNotEmpty);
  bool get isComplete => hasOrigin && hasDestination;
}

