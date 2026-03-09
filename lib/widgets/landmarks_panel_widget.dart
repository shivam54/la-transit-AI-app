import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../services/places_service.dart';
import '../services/events_service.dart';
import '../models/landmark_model.dart';
import '../utils/constants.dart';

/// Landmarks Panel Widget - Shows landmarks near a stop/step
class LandmarksPanelWidget extends StatefulWidget {
  final String stopName;
  final LocationModel? location;
  final String? selectedCategory;

  const LandmarksPanelWidget({
    super.key,
    required this.stopName,
    this.location,
    this.selectedCategory,
  });

  @override
  State<LandmarksPanelWidget> createState() => _LandmarksPanelWidgetState();
}

class _LandmarksPanelWidgetState extends State<LandmarksPanelWidget> {
  final PlacesService _placesService = PlacesService();
  final EventsService _eventsService = EventsService();
  List<LandmarkModel> _allLandmarks = [];
  List<LandmarkModel> _visibleLandmarks = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedCategory;
  bool _accessibleOnly = false;

  @override
  void initState() {
    super.initState();
    // Start with no category selected - user chooses what they care about.
    _selectedCategory = widget.selectedCategory;
    if (widget.location != null && widget.stopName.isNotEmpty) {
      _fetchLandmarks();
    }
  }

  @override
  void didUpdateWidget(LandmarksPanelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stopName != oldWidget.stopName || 
        widget.location != oldWidget.location) {
      _fetchLandmarks();
    }
  }

  Future<void> _fetchLandmarks() async {
    if (widget.location == null || widget.stopName.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Special case: Events come from Ticketmaster API, not Places.
      if (_selectedCategory == 'events') {
        // Check if API key is configured
        if (AppConstants.ticketmasterApiKey.isEmpty || 
            AppConstants.ticketmasterApiKey.trim().isEmpty) {
          setState(() {
            _error = 'Events API key not configured. Please add your Ticketmaster API key in lib/utils/constants.dart';
            _allLandmarks = [];
            _visibleLandmarks = [];
            _isLoading = false;
          });
          return;
        }
        
        final events = await _eventsService.getNearbyEvents(
          latitude: widget.location!.latitude,
          longitude: widget.location!.longitude,
        );
        setState(() {
          _allLandmarks = events;
          _applyFilter();
          _isLoading = false;
          // If no events found and no error, show a helpful message
          if (events.isEmpty && _error == null) {
            _error = null; // Clear any previous error, let the empty state message show
          }
        });
        return;
      }

      // Fetch a rich set of nearby landmarks ONCE (all types).
      final landmarks = await _placesService.searchNearbyLandmarks(
        latitude: widget.location!.latitude,
        longitude: widget.location!.longitude,
        radius: 1500,
        includedTypes: null,
        includeAccessibility: true,
      );

      setState(() {
        _allLandmarks = landmarks;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to fetch nearby landmarks.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stopName.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Landmarks & Amenities near ${widget.stopName}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Filters row: category + accessibility toggle
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Filter by type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    isDense: true,
                  ),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('Select type...'),
                    ),
                    DropdownMenuItem(value: 'food', child: Text('Food & Coffee')),
                    DropdownMenuItem(value: 'shops', child: Text('Shops & Services')),
                    DropdownMenuItem(value: 'lodging', child: Text('Hotels & Stay')),
                    DropdownMenuItem(value: 'parking', child: Text('Parking & Gas')),
                    DropdownMenuItem(value: 'fun', child: Text('Attractions & Entertainment')),
                    DropdownMenuItem(value: 'events', child: Text('Events')),
                    DropdownMenuItem(value: 'essentials', child: Text('Essentials (Pharmacy, Bank, etc.)')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                    // For events we need to hit Ticketmaster; for others we can
                    // safely refetch Places data as needed.
                    _fetchLandmarks();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Switch(
                        value: _accessibleOnly,
                        onChanged: (v) {
                          setState(() {
                            _accessibleOnly = v;
                            _applyFilter();
                          });
                        },
                        activeColor: Colors.green,
                      ),
                      const Text(
                        '♿',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const Text(
                    'Accessible only',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Landmarks List
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            )
          else if (_selectedCategory == null)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Select a type above to view nearby places.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            )
          else if (_visibleLandmarks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'No places for this filter. Try another type.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            )
          else
            ..._visibleLandmarks.map((landmark) => Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (landmark.isAccessible)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '♿ Accessible',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          Text(
                            '${_getCategoryLabel(landmark.types)}: ${landmark.name}',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (landmark.address != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 2),
                          child: Text(
                            landmark.address!,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      if (landmark.accessibilityOptions != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 2),
                          child: Text(
                            _buildAccessibilityText(landmark.accessibilityOptions!),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  String _getCategoryLabel(List<String>? types) {
    // Prefer the active filter label so categories stay consistent
    switch (_selectedCategory) {
      case 'food':
        return 'Food';
      case 'shops':
        return 'Shops';
      case 'lodging':
        return 'Hotel';
      case 'parking':
        return 'Parking & Gas';
      case 'fun':
        return 'Attraction';
      case 'events':
        return 'Event';
      case 'essentials':
        return 'Essential';
    }

    if (types == null || types.isEmpty) return 'Place';

    return types.first.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  void _applyFilter() {
    // Start with all landmarks returned for this category
    var filtered = List<LandmarkModel>.from(_allLandmarks);

    // If API ever returns mixed-category items, apply a secondary guard
    if (_selectedCategory != null) {
      filtered =
          filtered.where((l) => _matchesCategory(l, _selectedCategory!)).toList();
    }

    if (_accessibleOnly) {
      filtered = filtered.where((l) => l.isAccessible).toList();
    }

    _visibleLandmarks = filtered;
  }

  bool _matchesCategory(LandmarkModel landmark, String category) {
    final types = landmark.types ?? [];
    final lowerTypes = types.map((t) => t.toLowerCase()).toList();

    switch (category) {
      case 'food':
        // True "Food & Coffee" – restaurants, cafes, bakeries, bars.
        final isEatery = lowerTypes.any((t) =>
            t.contains('restaurant') ||
            t.contains('cafe') ||
            t.contains('bakery') ||
            t.contains('bar'));

        // But explicitly EXCLUDE pure grocery/supermarket-style places.
        final isGroceryLike = lowerTypes.any((t) =>
            t.contains('supermarket') ||
            t.contains('grocery') ||
            t.contains('convenience_store') ||
            t.contains('liquor_store'));

        return isEatery && !isGroceryLike;
      case 'shops':
        return lowerTypes.any((t) =>
            t.contains('shopping_mall') ||
            t.contains('store') ||
            t.contains('supermarket') ||
            t.contains('grocery_store') ||
            t.contains('convenience_store') ||
            t.contains('clothing_store') ||
            t.contains('department_store'));
      case 'lodging':
        return lowerTypes.any((t) =>
            t.contains('lodging') || t.contains('hotel') || t.contains('motel'));
      case 'parking':
        // Parking category: match places with parking-related types
        return lowerTypes.any((t) =>
            t.contains('parking') ||
            t.contains('parking_garage') ||
            t.contains('gas_station') ||
            t.contains('car_rental'));
      case 'fun':
        // Explicitly EXCLUDE parking-related types from attractions
        final isParking = lowerTypes.any((t) =>
            t.contains('parking') ||
            t.contains('parking_garage') ||
            t.contains('gas_station'));
        if (isParking) return false;
        
        // Match actual attractions/entertainment (but exclude "park" if it's just parking)
        return lowerTypes.any((t) =>
            (t.contains('tourist_attraction') && !t.contains('parking')) ||
            (t.contains('park') && !t.contains('parking')) ||
            t.contains('amusement_park') ||
            t.contains('zoo') ||
            t.contains('movie_theater') ||
            t.contains('stadium') ||
            t.contains('art_gallery') ||
            t.contains('museum') ||
            t.contains('night_club'));
      case 'essentials':
        return lowerTypes.any((t) =>
            t.contains('pharmacy') ||
            t.contains('hospital') ||
            t.contains('bank') ||
            t.contains('atm') ||
            t.contains('supermarket') ||
            t.contains('grocery_store') ||
            t.contains('transit_station') ||
            t.contains('bus_station') ||
            t.contains('subway_station') ||
            t.contains('train_station'));
      case 'events':
        return lowerTypes.any((t) => t.contains('event'));
      default:
        return true;
    }
  }

  String _buildAccessibilityText(Map<String, dynamic> options) {
    final flags = <String>[];
    if (options['wheelchairAccessibleEntrance'] == true) {
      flags.add('Wheelchair accessible entrance');
    }
    if (options['wheelchairAccessibleParking'] == true) {
      flags.add('Accessible parking');
    }
    if (options['wheelchairAccessibleRestroom'] == true) {
      flags.add('Accessible restroom');
    }
    if (options['wheelchairAccessibleSeating'] == true) {
      flags.add('Accessible seating');
    }

    if (flags.isEmpty) {
      return 'Accessibility details not provided';
    }

    return flags.join(' • ');
  }
}

