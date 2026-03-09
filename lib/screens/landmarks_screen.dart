import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../providers/route_provider.dart';
import '../providers/language_provider.dart';
import '../services/places_service.dart';
import '../models/landmark_model.dart';
import '../models/location_model.dart';
import '../utils/constants.dart';
import '../screens/map_screen.dart';

/// Landmarks Screen with filtering and accessibility support
class LandmarksScreen extends StatefulWidget {
  final LocationModel? location;
  final String? category; // Pre-select category if provided
  
  const LandmarksScreen({super.key, this.location, this.category});

  @override
  State<LandmarksScreen> createState() => _LandmarksScreenState();
}

class _LandmarksScreenState extends State<LandmarksScreen> {
  final PlacesService _placesService = PlacesService();
  List<LandmarkModel> _landmarks = [];
  List<LandmarkModel> _filteredLandmarks = [];
  String? _selectedCategory;
  bool _accessibleOnly = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _selectedCategory = widget.category;
    }
    _loadLandmarks();
  }

  Future<void> _loadLandmarks() async {
    final locationProvider = context.read<LocationProvider>();
    final location = widget.location ?? locationProvider.currentLocation;

    if (location == null) {
      setState(() {
        _error = 'Location not available';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final landmarks = await _placesService.searchNearbyLandmarks(
        latitude: location.latitude,
        longitude: location.longitude,
        radius: AppConstants.defaultSearchRadius,
        accessibleOnly: _accessibleOnly,
      );

      setState(() {
        _landmarks = landmarks;
        _applyFilters();
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading landmarks: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredLandmarks = _landmarks.where((landmark) {
        if (_selectedCategory == null) return false;
        if (_selectedCategory == 'accessibility') {
          return landmark.isAccessible;
        }
        return landmark.matchesCategory(_selectedCategory!);
      }).toList();
    });
  }

  void _navigateToLandmark(LandmarkModel landmark) {
    final routeProvider = context.read<RouteProvider>();
    final locationProvider = context.read<LocationProvider>();
    
    if (routeProvider.selectedTransportMode == 'drive' && locationProvider.hasLocation) {
      // Create a detour route to the landmark
      // This will be handled by the route provider
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MapScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final routeProvider = context.watch<RouteProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('landmarks')),
      ),
      body: Column(
        children: [
          // Category filter dropdown
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: languageProvider.translate('select_type'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(languageProvider.translate('select_type')),
                    ),
                    ...AppConstants.landmarkCategories.map((category) {
                      if (category == 'accessibility') {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Row(
                            children: [
                              const Icon(Icons.accessible, size: 20),
                              const SizedBox(width: 8),
                              Text(languageProvider.translate('accessible')),
                            ],
                          ),
                        );
                      }
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(_getCategoryLabel(category)),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Accessibility filter
                CheckboxListTile(
                  title: Text(languageProvider.translate('accessible')),
                  value: _accessibleOnly,
                  onChanged: (value) {
                    setState(() {
                      _accessibleOnly = value ?? false;
                      _loadLandmarks();
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          // Landmarks list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _selectedCategory == null
                        ? Center(
                            child: Text(
                              languageProvider.translate('no_amenities'),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : _filteredLandmarks.isEmpty
                            ? Center(
                                child: Text(
                                  'No landmarks found',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredLandmarks.length,
                                itemBuilder: (context, index) {
                                  final landmark = _filteredLandmarks[index];
                                  return _LandmarkCard(
                                    landmark: landmark,
                                    showNavigateButton: routeProvider.selectedTransportMode == 'drive',
                                    onNavigate: () => _navigateToLandmark(landmark),
                                    languageProvider: languageProvider,
                                  );
                                },
                              ),
          ),
        ],
      ),
    );
  }

  String _getCategoryLabel(String category) {
    final labels = {
      'restaurant': 'Restaurant',
      'cafe': 'Cafe',
      'gas_station': 'Gas Station',
      'parking': 'Parking',
      'lodging': 'Hotel',
      'shopping_mall': 'Shopping Mall',
      'store': 'Store',
      'pharmacy': 'Pharmacy',
      'hospital': 'Hospital',
      'bank': 'Bank',
      'atm': 'ATM',
      'tourist_attraction': 'Tourist Attraction',
      'museum': 'Museum',
      'park': 'Park',
      'gym': 'Gym',
    };
    return labels[category] ?? category;
  }
}

/// Landmark card widget
class _LandmarkCard extends StatelessWidget {
  final LandmarkModel landmark;
  final bool showNavigateButton;
  final VoidCallback onNavigate;
  final LanguageProvider languageProvider;

  const _LandmarkCard({
    required this.landmark,
    required this.showNavigateButton,
    required this.onNavigate,
    required this.languageProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple[100],
          child: Icon(
            _getCategoryIcon(landmark.primaryCategory),
            color: Colors.purple,
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(landmark.name)),
            if (landmark.isAccessible)
              const Icon(
                Icons.accessible,
                color: Colors.green,
                size: 20,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (landmark.address != null) Text(landmark.address!),
            if (landmark.distance != null)
              Text(
                '${(landmark.distance! / 1609.34).toStringAsFixed(1)} miles away',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: showNavigateButton
            ? ElevatedButton(
                onPressed: onNavigate,
                child: Text(languageProvider.translate('navigate')),
              )
            : null,
        isThreeLine: true,
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final icons = {
      'restaurant': Icons.restaurant,
      'cafe': Icons.local_cafe,
      'gas_station': Icons.local_gas_station,
      'parking': Icons.local_parking,
      'lodging': Icons.hotel,
      'shopping_mall': Icons.store,
      'store': Icons.store,
      'pharmacy': Icons.local_pharmacy,
      'hospital': Icons.local_hospital,
      'bank': Icons.account_balance,
      'atm': Icons.atm,
      'tourist_attraction': Icons.camera_alt,
      'museum': Icons.museum,
      'park': Icons.park,
      'gym': Icons.fitness_center,
    };
    return icons[category] ?? Icons.place;
  }
}

