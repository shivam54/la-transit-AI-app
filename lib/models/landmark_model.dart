import 'location_model.dart';

/// Landmark Model with Accessibility Support
class LandmarkModel {
  final String id;
  final String name;
  final String? address;
  final LocationModel location;
  final List<String> types;
  final bool isAccessible;
  final Map<String, dynamic>? accessibilityOptions;
  final double? distance; // in meters
  final double? rating;
  final String? priceLevel;

  LandmarkModel({
    required this.id,
    required this.name,
    this.address,
    required this.location,
    required this.types,
    this.isAccessible = false,
    this.accessibilityOptions,
    this.distance,
    this.rating,
    this.priceLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'location': location.toJson(),
      'types': types,
      'isAccessible': isAccessible,
      'accessibilityOptions': accessibilityOptions,
      'distance': distance,
      'rating': rating,
      'priceLevel': priceLevel,
    };
  }

  factory LandmarkModel.fromJson(Map<String, dynamic> json) {
    return LandmarkModel(
      id: json['id'] ?? '',
      name: json['name'] ?? json['displayName'] ?? '',
      address: json['address'] ?? json['formattedAddress'],
      location: LocationModel.fromJson(json['location'] ?? {}),
      types: List<String>.from(json['types'] ?? []),
      isAccessible: json['isAccessible'] ?? false,
      accessibilityOptions: json['accessibilityOptions'],
      distance: json['distance']?.toDouble(),
      rating: json['rating']?.toDouble(),
      priceLevel: json['priceLevel'],
    );
  }

  factory LandmarkModel.fromPlacesApi(Map<String, dynamic> json) {
    final location = LocationModel.fromPlacesApi(json);
    final accessibilityOptions = json['accessibilityOptions'];
    final isAccessible = accessibilityOptions != null &&
        (accessibilityOptions['wheelchairAccessibleEntrance'] == true ||
            accessibilityOptions['wheelchairAccessibleParking'] == true ||
            accessibilityOptions['wheelchairAccessibleRestroom'] == true ||
            accessibilityOptions['wheelchairAccessibleSeating'] == true);

    return LandmarkModel(
      id: json['id'] ?? '',
      name: json['displayName']?['text'] ?? json['displayName'] ?? '',
      address: json['formattedAddress'],
      location: location,
      types: List<String>.from(json['types'] ?? []),
      isAccessible: isAccessible,
      accessibilityOptions: accessibilityOptions,
      rating: json['rating']?.toDouble(),
      priceLevel: json['priceLevel'],
    );
  }

  /// Check if landmark matches a category
  bool matchesCategory(String category) {
    if (category == 'accessibility') {
      return isAccessible;
    }
    return types.contains(category);
  }

  /// Get primary category from types
  String get primaryCategory {
    final mainTypes = [
      'restaurant',
      'cafe',
      'gas_station',
      'parking',
      'lodging',
      'shopping_mall',
      'store',
      'pharmacy',
      'hospital',
      'bank',
      'atm',
      'tourist_attraction',
      'museum',
      'park',
      'gym',
    ];
    
    for (final type in types) {
      if (mainTypes.contains(type)) {
        return type;
      }
    }
    return types.isNotEmpty ? types.first : 'establishment';
  }
}

