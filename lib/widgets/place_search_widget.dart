import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/places_service.dart';
import '../models/location_model.dart';
import '../providers/location_provider.dart';

/// Place Search Widget with autocomplete
class PlaceSearchWidget extends StatefulWidget {
  final String label;
  final String? initialValue;
  final Function(LocationModel) onPlaceSelected;
  /// Optional icon shown inside the field (e.g. current location). Shown before clear/loading.
  final Widget? trailingIcon;

  const PlaceSearchWidget({
    super.key,
    required this.label,
    this.initialValue,
    required this.onPlaceSelected,
    this.trailingIcon,
  });

  @override
  State<PlaceSearchWidget> createState() => _PlaceSearchWidgetState();
}

class _PlaceSearchWidgetState extends State<PlaceSearchWidget> {
  final TextEditingController _controller = TextEditingController();
  final PlacesService _placesService = PlacesService();
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void didUpdateWidget(covariant PlaceSearchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When parent passes a new initialValue (e.g., after swap origin/destination),
    // keep the visible text field in sync.
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != null &&
        widget.initialValue!.isNotEmpty) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces(String query) async {
    if (query.length < 3) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final locationProvider = context.read<LocationProvider>();
      double? lat, lng;
      
      if (locationProvider.hasLocation) {
        lat = locationProvider.currentLocation!.latitude;
        lng = locationProvider.currentLocation!.longitude;
      }

      final suggestions = await _placesService.autocompletePlaces(
        query,
        lat: lat,
        lng: lng,
      );

      if (!mounted) return;
      setState(() => _suggestions = suggestions);
    } catch (e) {
      if (mounted) setState(() => _suggestions = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget? _buildSuffixIcon() {
    final Widget? rightPart = _isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  setState(() {
                    _suggestions = [];
                  });
                },
              )
            : null;
    if (widget.trailingIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.trailingIcon!,
          if (rightPart != null) rightPart,
        ],
      );
    }
    return rightPart;
  }

  Future<void> _selectPlace(Map<String, dynamic> suggestion) async {
    // Get place details
    final placeId = suggestion['placePrediction']?['placeId'] ?? 
                    suggestion['place_id'] ?? 
                    suggestion['placeId'];
    
    if (placeId == null) return;

    try {
      final placeDetails = await _placesService.getPlaceWithSummary(placeId);
      if (placeDetails != null) {
        final location = LocationModel.fromPlacesApi(placeDetails);
        widget.onPlaceSelected(location);
        
        setState(() {
          _suggestions = [];
          _controller.text = location.name ?? location.address ?? '';
        });
      }
    } catch (e) {
      print('Error getting place details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: 'Search for a place...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _suggestions = [];
                          });
                        },
                      )
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: _searchPlaces,
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                final prediction = suggestion['placePrediction'] ?? suggestion;
                final text = prediction['text']?['text'] ?? 
                            prediction['description'] ?? 
                            prediction['mainText'] ?? 
                            '';
                final secondaryText = prediction['structuredFormat']?['secondaryText']?['text'] ??
                                     prediction['secondaryText'] ??
                                     '';

                return ListTile(
                  leading: const Icon(Icons.place),
                  title: Text(text),
                  subtitle: secondaryText.isNotEmpty ? Text(secondaryText) : null,
                  onTap: () => _selectPlace(suggestion),
                );
              },
            ),
          ),
      ],
    );
  }
}

