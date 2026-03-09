import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../providers/route_provider.dart';
import '../providers/language_provider.dart';
import '../models/route_model.dart';
import '../models/location_model.dart';
import '../utils/constants.dart';
import '../utils/polyline_decoder.dart';
import '../services/voice_service.dart';
import '../services/places_service.dart';
import '../services/directions_service.dart';
import '../models/landmark_model.dart';

/// Map Screen with Google Maps integration
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  StreamSubscription<Position>? _positionSubscription;
  bool _followUser = false; // start with static route view; user can opt-in
  int? _currentStepIndex; // Current step being displayed
  bool _showDirectionsPanel = true; // Show/hide directions panel
  bool _isNavigating = false; // Navigation mode active
  bool _isPreviewMode = false; // Preview mode for browsing route
  final VoiceService _voiceService = VoiceService();
  final PlacesService _placesService = PlacesService();
  final DirectionsService _directionsService = DirectionsService();
  Position? _lastKnownPosition;
  bool _isListeningForCommand = false; // Listening for voice commands
  bool _isAwaitingSelection = false; // Waiting for user to select from options
  List<LandmarkModel> _currentLandmarkOptions = []; // Current landmark search results
  RouteModel? _originalDestinationRoute; // Store original route destination
  String? _pendingCommand; // Store command that needs confirmation

  @override
  void initState() {
    super.initState();
    _voiceService.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMapFromRoute();
      _startLocationStream();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMapFromRoute();
  }

  void _updateMapFromRoute() {
    final routeProvider = context.read<RouteProvider>();
    final locationProvider = context.read<LocationProvider>();
    
    if (routeProvider.hasRoute) {
      _drawRoute(routeProvider.currentRoute!);
    } else if (locationProvider.hasLocation) {
      _centerOnLocation(locationProvider.currentLocation!);
    }
  }

  void _drawRoute(RouteModel route) {
    setState(() {
      _markers.clear();
      _polylines.clear();
      // Only reset step index if it's null or out of bounds
      if (_currentStepIndex == null || _currentStepIndex! >= route.steps.length) {
        _currentStepIndex = route.steps.isNotEmpty ? 0 : null;
      }

      // Add origin marker
      _markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: LatLng(route.origin.latitude, route.origin.longitude),
          infoWindow: InfoWindow(
            title: route.origin.name ?? 'Origin',
            snippet: route.origin.address ?? '',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );

      // Add destination marker
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(route.destination.latitude, route.destination.longitude),
          infoWindow: InfoWindow(
            title: route.destination.name ?? 'Destination',
            snippet: route.destination.address ?? '',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );

      // Add step markers for turn-by-turn directions
      for (var i = 0; i < route.steps.length; i++) {
        final step = route.steps[i];
        final isCurrentStep = i == _currentStepIndex;
        
        // Create a custom icon for the current step (larger, different color)
        _markers.add(
          Marker(
            markerId: MarkerId('step_$i'),
            position: LatLng(
              step.startLocation.latitude,
              step.startLocation.longitude,
            ),
            infoWindow: InfoWindow(
              title: 'Step ${i + 1}',
              snippet: _stripHtmlTags(step.instructions),
            ),
            icon: isCurrentStep
                ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)
                : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            onTap: () {
              setState(() {
                _currentStepIndex = i;
                _centerOnStep(step);
              });
            },
          ),
        );
      }

      // Add transit stop markers (bus/train icons) if transit details are available
      final transitDetails = route.transitDetails ?? [];
      for (var i = 0; i < transitDetails.length; i++) {
        final detail = transitDetails[i];
        final departureStop = detail['departure_stop'] ?? {};
        final stopLocation = departureStop['location'] ?? {};
        final lat = stopLocation['lat'] ?? stopLocation['latitude'];
        final lng = stopLocation['lng'] ?? stopLocation['longitude'];
        if (lat == null || lng == null) continue;

        _markers.add(
          Marker(
            markerId: MarkerId('transit_stop_$i'),
            position: LatLng(
              (lat as num).toDouble(),
              (lng as num).toDouble(),
            ),
            infoWindow: InfoWindow(
              title: departureStop['name']?.toString() ?? 'Transit Stop',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        );
      }

      // Draw polyline if available
      if (route.polyline != null) {
        try {
          final points = PolylineDecoder.decodePolyline(route.polyline!);
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: points,
              color: Colors.blue,
              width: 5,
            ),
          );
        } catch (e) {
          // Fallback to straight line if decoding fails
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: [
                LatLng(route.origin.latitude, route.origin.longitude),
                LatLng(route.destination.latitude, route.destination.longitude),
              ],
              color: Colors.blue,
              width: 5,
            ),
          );
        }
      }

      // Center map on route
      _centerMapOnRoute(route);
      
      // If we have steps, center on the first step
      if (route.steps.isNotEmpty && _currentStepIndex != null) {
        _centerOnStep(route.steps[_currentStepIndex!]);
      }
    });
  }

  void _centerOnStep(RouteStep step) {
    if (_mapController == null) return;
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(step.startLocation.latitude, step.startLocation.longitude),
        16.0, // Zoom in closer for step details
      ),
    );
  }

  String _stripHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  Future<void> _navigateToStep(int direction) async {
    final routeProvider = context.read<RouteProvider>();
    if (!routeProvider.hasRoute) {
      debugPrint('No route available');
      return;
    }
    
    final route = routeProvider.currentRoute!;
    if (route.steps.isEmpty) {
      debugPrint('Route has no steps');
      return;
    }
    
    // Initialize step index if null
    if (_currentStepIndex == null) {
      _currentStepIndex = 0;
    }
    
    final currentIndex = _currentStepIndex!;
    final newIndex = (currentIndex + direction).clamp(0, route.steps.length - 1);
    
    // Only update if index actually changed
    if (newIndex == currentIndex) {
      debugPrint('Step index unchanged: $newIndex');
      return;
    }
    
    debugPrint('Navigating from step $currentIndex to step $newIndex');
    
    setState(() {
      _currentStepIndex = newIndex;
    });
    
    // Update markers to highlight current step (without resetting index)
    _updateMarkersForStep(route, newIndex);
    
    // Center on the new step
    if (newIndex < route.steps.length) {
      _centerOnStep(route.steps[newIndex]);
    }
    
    // Speak the direction if in navigation mode (not preview mode)
    if (_isNavigating && !_isPreviewMode && newIndex < route.steps.length) {
      final step = route.steps[newIndex];
      final languageProvider = context.read<LanguageProvider>();
      await _voiceService.speak(
        _stripHtmlTags(step.instructions),
        languageProvider: languageProvider,
      );
    }
  }

  void _updateMarkersForStep(RouteModel route, int stepIndex) {
    setState(() {
      // Clear existing step markers but keep origin/destination
      _markers.removeWhere((marker) => marker.markerId.value.startsWith('step_'));
      
      // Add step markers for turn-by-turn directions
      for (var i = 0; i < route.steps.length; i++) {
        final step = route.steps[i];
        final isCurrentStep = i == stepIndex;
        
        _markers.add(
          Marker(
            markerId: MarkerId('step_$i'),
            position: LatLng(
              step.startLocation.latitude,
              step.startLocation.longitude,
            ),
            infoWindow: InfoWindow(
              title: 'Step ${i + 1}',
              snippet: _stripHtmlTags(step.instructions),
            ),
            icon: isCurrentStep
                ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)
                : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            onTap: () {
              if (!_isNavigating) {
                setState(() {
                  _currentStepIndex = i;
                });
                _updateMarkersForStep(route, i);
                _centerOnStep(step);
              }
            },
          ),
        );
      }
    });
  }

  void _enterPreviewMode() {
    setState(() {
      _isPreviewMode = true;
      _isNavigating = false;
      _followUser = false;
    });
    _voiceService.stopSpeaking();
  }

  void _exitPreviewMode() {
    setState(() {
      _isPreviewMode = false;
    });
  }

  void _centerMapOnRoute(RouteModel route) {
    if (_mapController == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        route.origin.latitude < route.destination.latitude
            ? route.origin.latitude
            : route.destination.latitude,
        route.origin.longitude < route.destination.longitude
            ? route.origin.longitude
            : route.destination.longitude,
      ),
      northeast: LatLng(
        route.origin.latitude > route.destination.latitude
            ? route.origin.latitude
            : route.destination.latitude,
        route.origin.longitude > route.destination.longitude
            ? route.origin.longitude
            : route.destination.longitude,
      ),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  void _centerOnLocation(LocationModel location) {
    if (_mapController == null) return;

    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(location.latitude, location.longitude),
        AppConstants.defaultMapZoom,
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateMapFromRoute();
  }

  void _startLocationStream() async {
    // Ensure permissions are granted; LocationProvider already handles this on startup.
    try {
      _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters during navigation
        ),
      ).listen((position) {
        // Ignore obviously invalid coordinates (common on emulators)
        if (position.latitude == 0 && position.longitude == 0) return;
        
        _lastKnownPosition = position;
        
        // During navigation, always follow user and check if approaching next step
        if (_isNavigating) {
          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(position.latitude, position.longitude),
              ),
            );
          }
          _checkProximityToStep(position);
        } else if (_followUser && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(position.latitude, position.longitude),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('Error starting location stream: $e');
    }
  }

  void _checkProximityToStep(Position currentPosition) async {
    final routeProvider = context.read<RouteProvider>();
    if (!routeProvider.hasRoute || _currentStepIndex == null) return;
    
    final route = routeProvider.currentRoute!;
    if (_currentStepIndex! >= route.steps.length) return;
    
    final currentStep = route.steps[_currentStepIndex!];
    final stepLocation = currentStep.endLocation;
    
    final distance = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      stepLocation.latitude,
      stepLocation.longitude,
    );
    
    // If within 50 meters of step end, move to next step
    if (distance < 50 && _currentStepIndex! < route.steps.length - 1) {
      await _navigateToStep(1);
    }
    
    // Check if reached detour destination
    if (routeProvider.hasActiveDetour) {
      await _checkIfReachedLandmark();
    }
  }

  Future<void> _startNavigation() async {
    final routeProvider = context.read<RouteProvider>();
    if (!routeProvider.hasRoute) return;
    
    setState(() {
      _isNavigating = true;
      _isPreviewMode = false; // Exit preview mode when starting navigation
      _followUser = true; // Auto-enable follow during navigation
    });
    
    // Speak first direction
    final route = routeProvider.currentRoute!;
    final languageProvider = context.read<LanguageProvider>();
    if (route.steps.isNotEmpty) {
      String instruction = 'Starting navigation. ${_stripHtmlTags(route.steps[0].instructions)}';
      
      // Note: Voice commands are now manual - user must click the button to enable
      
      await _voiceService.speak(
        instruction,
        languageProvider: languageProvider,
      );
    }
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
      _isPreviewMode = false;
      _isListeningForCommand = false;
      _isAwaitingSelection = false;
      _currentLandmarkOptions = [];
      _pendingCommand = null;
    });
    _voiceService.stopSpeaking();
    _voiceService.stopListening();
  }

  void _startListeningForCommands() {
    // Only enable voice commands for driving mode
    final routeProvider = context.read<RouteProvider>();
    if (!_isNavigating || routeProvider.selectedTransportMode != 'drive') {
      if (mounted) {
        setState(() {
          _isListeningForCommand = false;
        });
      }
      return;
    }
    
    // Check if already listening - prevent duplicate starts
    if (_voiceService.isListening) {
      debugPrint('⚠️ Already listening, skipping restart');
      return;
    }
    
    // Update UI to show we're starting to listen
    if (mounted) {
      setState(() {
        _isListeningForCommand = true;
      });
    }
    
    // Stop any existing listening first
    _voiceService.stopListening();
    
    // Longer delay to ensure previous listening is fully stopped and TTS has finished
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!_isNavigating || !mounted) {
        if (mounted) {
          setState(() {
            _isListeningForCommand = false;
          });
        }
        return;
      }
      
      // Double-check we're not already listening
      if (_voiceService.isListening) {
        debugPrint('⚠️ Speech recognition already active, skipping start');
        return;
      }
      
      final languageProvider = context.read<LanguageProvider>();
      
      _voiceService.startListening(
        languageProvider: languageProvider,
        autoRestart: true, // Enable auto-restart for continuous listening during navigation
        onResult: (result) {
          if (mounted) {
            _handleVoiceCommand(result);
          }
        },
        onError: (error) {
          debugPrint('Voice command error: $error');
          if (mounted) {
            setState(() {
              _isListeningForCommand = false;
            });
          }
          // Don't manually retry - auto-restart will handle it if enabled
        },
        onStatus: (status) {
          debugPrint('Voice status: $status');
          if (mounted) {
            setState(() {
              if (status == 'Listening...' || status.toLowerCase().contains('listening')) {
                _isListeningForCommand = true;
              } else if (status.toLowerCase().contains('error') || status.toLowerCase().contains('not listening')) {
                _isListeningForCommand = false;
              }
            });
          }
        },
      );
    });
  }

  Future<void> _handleVoiceCommand(String command) async {
    final languageProvider = context.read<LanguageProvider>();
    final lowerCommand = command.toLowerCase();
    
    debugPrint('Voice command received: $command');
    
    // Stop listening immediately to prevent conflicts
    await _voiceService.stopListening();
    setState(() {
      _isListeningForCommand = false; // Stop listening while processing
    });
    
    // Small delay to ensure speech recognition is fully stopped
    await Future.delayed(const Duration(milliseconds: 300));
    
    // If awaiting selection, handle selection
    if (_isAwaitingSelection) {
      await _handleLandmarkSelection(command, languageProvider);
      // Don't auto-restart - user must click "Start Voice" again
      return;
    }
    
    // Check if we have a pending command that needs confirmation
    if (_pendingCommand != null) {
      debugPrint('📋 Processing confirmation for pending command: $_pendingCommand');
      
      // User is confirming the command - check for yes/confirm/correct (more flexible)
      final isYes = lowerCommand == 'yes' || 
                    lowerCommand.contains('yes') || 
                    lowerCommand.contains('confirm') || 
                    lowerCommand.contains('correct') ||
                    lowerCommand.contains('sí') ||
                    lowerCommand == 'y';
      
      final isNo = lowerCommand == 'no' || 
                   lowerCommand.contains('no') || 
                   lowerCommand.contains('cancel') ||
                   lowerCommand.contains('cancelar');
      
      if (isYes) {
        // Process the confirmed command
        final confirmedCommand = _pendingCommand!;
        _pendingCommand = null;
        debugPrint('✅ Confirmed command: $confirmedCommand');
        
        if (confirmedCommand.toLowerCase().contains('nearby')) {
          // Search for nearby landmarks
          await _searchNearbyLandmarks(confirmedCommand, languageProvider);
        } else if (confirmedCommand.startsWith('navigate_to_')) {
          // Navigate to selected landmark
          final numberStr = confirmedCommand.replaceFirst('navigate_to_', '');
          final number = int.tryParse(numberStr);
          if (number != null && number >= 1 && number <= _currentLandmarkOptions.length) {
            final selectedLandmark = _currentLandmarkOptions[number - 1];
            await _voiceService.speak(
              languageProvider.isSpanish
                ? 'Navegando a ${selectedLandmark.name}.'
                : 'Navigating to ${selectedLandmark.name}.',
              languageProvider: languageProvider,
            );
            await _navigateToLandmark(selectedLandmark);
            setState(() {
              _isAwaitingSelection = false;
              _currentLandmarkOptions = [];
            });
          }
        }
      } else if (isNo) {
        // Cancel the pending command
        _pendingCommand = null;
        setState(() {
          _isAwaitingSelection = false;
          _currentLandmarkOptions = [];
        });
        await _voiceService.speak(
          languageProvider.isSpanish 
            ? 'Comando cancelado. Por favor, inténtalo de nuevo.'
            : 'Command cancelled. Please try again.',
          languageProvider: languageProvider,
        );
      } else {
        // Unknown response to confirmation - ask again
        await _voiceService.speak(
          languageProvider.isSpanish
            ? 'Por favor, di sí para confirmar o no para cancelar.'
            : 'Please say yes to confirm or no to cancel.',
          languageProvider: languageProvider,
        );
        // Restart listening for confirmation
        await Future.delayed(const Duration(milliseconds: 500));
        if (_isNavigating && _pendingCommand != null) {
          _startListeningForCommands();
        }
      }
      // Don't auto-restart - user must click "Start Voice" again (unless we're waiting for confirmation)
      return;
    }
    
    // Check if command is just a category name (e.g., "restaurants", "parking", "gas station")
    // If so, treat it as a nearby search
    final category = _voiceService.parseCategoryFromCommand(command);
    final isCategoryOnly = category != null && 
                           !lowerCommand.contains('nearby') &&
                           !lowerCommand.contains('find') &&
                           !lowerCommand.contains('show') &&
                           !lowerCommand.contains('tell');
    
    // Check for landmark search commands (with "nearby" keyword or category-only)
    if (lowerCommand.contains('find nearby') || 
        lowerCommand.contains('tell me nearby') ||
        lowerCommand.contains('show me nearby') ||
        lowerCommand.contains('nearby') ||
        isCategoryOnly) {
      
      // If it's category-only, prepend "nearby" for better confirmation message
      final searchCommand = isCategoryOnly ? 'nearby $command' : command;
      
      // Store command and ask for confirmation
      _pendingCommand = searchCommand;
      await _voiceService.speak(
        languageProvider.isSpanish
          ? '¿Quieres buscar $searchCommand? Di sí para confirmar o no para cancelar.'
          : 'Do you want to search for $searchCommand? Say yes to confirm or no to cancel.',
        languageProvider: languageProvider,
      );
      
      // Wait a bit, then restart listening for confirmation
      await Future.delayed(const Duration(milliseconds: 500));
      if (_isNavigating && _pendingCommand != null) {
        _startListeningForCommands();
      }
    } else if (lowerCommand.contains('cancel') || lowerCommand.contains('never mind')) {
      setState(() {
        _isAwaitingSelection = false;
        _currentLandmarkOptions = [];
        _pendingCommand = null;
      });
      await _voiceService.speak(
        languageProvider.isSpanish ? 'Cancelado.' : 'Cancelled.',
        languageProvider: languageProvider,
      );
      // Don't auto-restart - user must click "Start Voice" again
    } else {
      // Unknown command - don't restart automatically
      await _voiceService.speak(
        languageProvider.isSpanish
          ? 'No entendí ese comando. Por favor, intenta de nuevo.'
          : 'I didn\'t understand that command. Please try again.',
        languageProvider: languageProvider,
      );
    }
  }

  Future<void> _searchNearbyLandmarks(String command, LanguageProvider languageProvider) async {
    // Try to get current position from multiple sources
    Position? currentPosition = _lastKnownPosition;
    double? lat;
    double? lng;
    
    // If we have a cached position, use it
    if (currentPosition != null) {
      lat = currentPosition.latitude;
      lng = currentPosition.longitude;
      debugPrint('📍 Using cached position: $lat, $lng');
    } else {
      // Fallback 1: Try LocationProvider
      final locationProvider = context.read<LocationProvider>();
      if (locationProvider.hasLocation && locationProvider.currentLocation != null) {
        lat = locationProvider.currentLocation!.latitude;
        lng = locationProvider.currentLocation!.longitude;
        debugPrint('📍 Using location from LocationProvider: $lat, $lng');
        // Also try to update cached position
        try {
          currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 2), // Shorter timeout
          ).timeout(const Duration(seconds: 2));
          _lastKnownPosition = currentPosition;
        } catch (_) {
          // Ignore - we already have location from LocationProvider
        }
      } else {
        // Fallback 2: Try to get position directly with shorter timeout
        try {
          currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low, // Use low for faster response
            timeLimit: const Duration(seconds: 3), // Shorter timeout
          ).timeout(const Duration(seconds: 3));
          lat = currentPosition.latitude;
          lng = currentPosition.longitude;
          _lastKnownPosition = currentPosition; // Cache it
          debugPrint('📍 Got position directly: $lat, $lng');
        } catch (e) {
          debugPrint('❌ Could not get current position: $e');
          // Last resort: Try to get last known position from route
          final routeProvider = context.read<RouteProvider>();
          if (routeProvider.hasRoute && routeProvider.currentRoute != null) {
            // Use origin as fallback (user's starting point)
            lat = routeProvider.currentRoute!.origin.latitude;
            lng = routeProvider.currentRoute!.origin.longitude;
            debugPrint('📍 Using route origin as fallback: $lat, $lng');
          }
        }
      }
    }
    
    if (lat == null || lng == null) {
      await _voiceService.speak(
        'Location not available. Please wait for GPS signal.',
        languageProvider: languageProvider,
      );
      _startListeningForCommands();
      return;
    }
    
    await _voiceService.speak(
      'Searching nearby places. Please wait.',
      languageProvider: languageProvider,
    );
    
    // Parse category from command
    String? category = _voiceService.parseCategoryFromCommand(command);
    List<String>? includedTypes;
    
    // Map category to place types
    if (category != null) {
      final categoryMap = {
        'restaurant': ['restaurant', 'cafe', 'meal_takeaway'],
        'cafe': ['cafe', 'bakery'],
        'parking': ['parking'],
        'gas_station': ['gas_station'],
        'pharmacy': ['pharmacy'],
        'hospital': ['hospital'],
        'bank': ['bank', 'atm'],
        'shopping_mall': ['shopping_mall', 'department_store'],
        'lodging': ['lodging'],
      };
      includedTypes = categoryMap[category];
    }
    
    // If no specific category, search broadly
    if (includedTypes == null) {
      // Try to infer from keywords
      if (command.contains('restaurant') || command.contains('food') || command.contains('eat')) {
        includedTypes = ['restaurant', 'cafe'];
      } else if (command.contains('parking')) {
        includedTypes = ['parking'];
      } else if (command.contains('gas') || command.contains('fuel')) {
        includedTypes = ['gas_station'];
      } else {
        includedTypes = ['restaurant', 'cafe', 'parking', 'gas_station', 'pharmacy'];
      }
    }
    
    try {
      debugPrint('🔍 Searching landmarks near: $lat, $lng');
      final landmarks = await _placesService.searchNearbyLandmarks(
        latitude: lat,
        longitude: lng,
        radius: 2000, // 2km radius
        includedTypes: includedTypes,
        accessibleOnly: _voiceService.parseAccessibleOnly(command),
      );
      
      if (landmarks.isEmpty) {
        await _voiceService.speak(
          'No nearby places found. Try a different search.',
          languageProvider: languageProvider,
        );
        _startListeningForCommands();
        return;
      }
      
      // Limit to top 5 for voice selection
      final topLandmarks = landmarks.take(5).toList();
      _currentLandmarkOptions = topLandmarks;
      
      setState(() {
        _isAwaitingSelection = true;
      });
      
      // Speak the options
      final optionsText = topLandmarks.asMap().entries.map((e) {
        final index = e.key + 1;
        final landmark = e.value;
        return 'Option $index: ${landmark.name}';
      }).join('. ');
      
      await _voiceService.speak(
        languageProvider.isSpanish
          ? 'Encontré ${topLandmarks.length} opciones. $optionsText. Por favor, haz clic en el botón Iniciar Voz para decir el número de opción.'
          : 'Found ${topLandmarks.length} options. $optionsText. Please click the Start Voice button to say the option number.',
        languageProvider: languageProvider,
      );
      
      // Don't restart listening automatically - user must click "Start Voice" button
      // This gives user time to process the options
    } catch (e) {
      debugPrint('Error searching landmarks: $e');
      await _voiceService.speak(
        'Error searching for places. Please try again.',
        languageProvider: languageProvider,
      );
      _startListeningForCommands();
    }
  }

  Future<void> _handleLandmarkSelection(String command, LanguageProvider languageProvider) async {
    final number = _voiceService.parseNumberFromCommand(command);
    
    if (number == null || number < 1 || number > _currentLandmarkOptions.length) {
      await _voiceService.speak(
        'Invalid selection. Please say a number between 1 and ${_currentLandmarkOptions.length}.',
        languageProvider: languageProvider,
      );
      _startListeningForCommands();
      return;
    }
    
    final selectedLandmark = _currentLandmarkOptions[number - 1];
    
    await _voiceService.speak(
      'Navigating to ${selectedLandmark.name}.',
      languageProvider: languageProvider,
    );
    
    // Create detour route to selected landmark
    await _navigateToLandmark(selectedLandmark);
    
    setState(() {
      _isAwaitingSelection = false;
      _currentLandmarkOptions = [];
    });
    
    // Continue listening for more commands
    _startListeningForCommands();
  }

  Future<void> _navigateToLandmark(LandmarkModel landmark) async {
    if (_lastKnownPosition == null) return;
    
    final routeProvider = context.read<RouteProvider>();
    final languageProvider = context.read<LanguageProvider>();
    
    // Create location model for landmark
    final landmarkLocation = LocationModel(
      latitude: landmark.location.latitude,
      longitude: landmark.location.longitude,
      name: landmark.name,
      address: landmark.address,
    );
    
    // Create location model for current position
    final currentLocation = LocationModel(
      latitude: _lastKnownPosition!.latitude,
      longitude: _lastKnownPosition!.longitude,
      name: 'Current Location',
    );
    
    try {
      // Get route to landmark
      final detourRoute = await _directionsService.getDirections(
        origin: currentLocation,
        destination: landmarkLocation,
        transportMode: routeProvider.selectedTransportMode == 'public_transit' ? 'public_transit' : 'drive',
      );
      
      if (detourRoute != null) {
        // Store original destination if not already stored
        if (_originalDestinationRoute == null && routeProvider.hasRoute) {
          _originalDestinationRoute = routeProvider.currentRoute;
        }
        
        // Start detour
        routeProvider.startDetour(detourRoute);
        
        // Update map
        _drawRoute(detourRoute);
        setState(() {
          _currentStepIndex = 0;
        });
        
        // Speak first direction
        if (detourRoute.steps.isNotEmpty) {
          await _voiceService.speak(
            'Heading to ${landmark.name}. ${_stripHtmlTags(detourRoute.steps[0].instructions)}',
            languageProvider: languageProvider,
          );
        }
      }
    } catch (e) {
      debugPrint('Error navigating to landmark: $e');
      await _voiceService.speak(
        'Could not find route to ${landmark.name}. Please try another option.',
        languageProvider: languageProvider,
      );
    }
  }

  Future<void> _checkIfReachedLandmark() async {
    if (_lastKnownPosition == null) return;
    
    final routeProvider = context.read<RouteProvider>();
    if (!routeProvider.hasActiveDetour) return;
    
    final currentRoute = routeProvider.currentRoute;
    if (currentRoute == null || _originalDestinationRoute == null) return;
    
    final destination = currentRoute.destination;
    final distance = Geolocator.distanceBetween(
      _lastKnownPosition!.latitude,
      _lastKnownPosition!.longitude,
      destination.latitude,
      destination.longitude,
    );
    
    // If within 50 meters of detour destination, resume original route
    if (distance < 50) {
      final languageProvider = context.read<LanguageProvider>();
      final originalDest = _originalDestinationRoute!.destination;
      
      await _voiceService.speak(
        'You have arrived. Continuing to your original destination.',
        languageProvider: languageProvider,
      );
      
      // Update origin to current location and navigate to original destination
      final newOrigin = LocationModel(
        latitude: _lastKnownPosition!.latitude,
        longitude: _lastKnownPosition!.longitude,
        name: 'Current Location',
      );
      
      final finalRoute = await _directionsService.getDirections(
        origin: newOrigin,
        destination: originalDest,
        transportMode: routeProvider.selectedTransportMode == 'public_transit' ? 'public_transit' : 'drive',
      );
      
      if (finalRoute != null) {
        routeProvider.setRoute(finalRoute);
        _drawRoute(finalRoute);
        setState(() {
          _currentStepIndex = 0;
          _originalDestinationRoute = null;
        });
        
        if (finalRoute.steps.isNotEmpty) {
          await _voiceService.speak(
            'Continuing to ${originalDest.name ?? "destination"}. ${_stripHtmlTags(finalRoute.steps[0].instructions)}',
            languageProvider: languageProvider,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final routeProvider = context.watch<RouteProvider>();

    // Default to LA center if no location
    final initialPosition = locationProvider.hasLocation
        ? LatLng(
            locationProvider.currentLocation!.latitude,
            locationProvider.currentLocation!.longitude,
          )
        : const LatLng(AppConstants.laCenterLat, AppConstants.laCenterLng);

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: AppConstants.defaultMapZoom,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            zoomControlsEnabled: true,
            compassEnabled: true,
            // Disable Google Maps logo and attribution that might open external maps
            mapToolbarEnabled: false, // This removes the toolbar with "Open in Google Maps"
          ),
          // Directions panel overlay
          if (routeProvider.hasRoute)
            _buildDirectionsPanel(routeProvider.currentRoute!),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Voice command button (only for driving mode during navigation)
          if (_isNavigating && routeProvider.selectedTransportMode == 'drive')
            FloatingActionButton.extended(
              heroTag: 'voice_command',
              onPressed: () {
                if (_isListeningForCommand) {
                  // Stop listening
                  _voiceService.stopListening();
                  setState(() {
                    _isListeningForCommand = false;
                    _isAwaitingSelection = false;
                    _currentLandmarkOptions = [];
                  });
                } else {
                  // Start listening
                  _startListeningForCommands();
                }
              },
              backgroundColor: _isListeningForCommand ? Colors.blue : Colors.grey[600],
              icon: Icon(
                _isListeningForCommand ? Icons.mic : Icons.mic_none,
                color: Colors.white,
              ),
              label: Text(
                _isListeningForCommand ? 'Listening...' : 'Start Voice',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (_isNavigating && routeProvider.selectedTransportMode == 'drive')
            const SizedBox(height: 8),
          if (routeProvider.hasActiveDetour)
            FloatingActionButton.extended(
              heroTag: 'back_to_route',
              onPressed: () {
                routeProvider.resumeOriginalRoute();
                _updateMapFromRoute();
              },
              icon: const Icon(Icons.route),
              label: const Text('Back to Route'),
            ),
          if (routeProvider.hasActiveDetour) const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'follow_user',
            onPressed: () {
              setState(() {
                _followUser = !_followUser;
              });
            },
            tooltip: _followUser ? 'Stop following location' : 'Follow my location',
            child: Icon(
              _followUser ? Icons.gps_fixed : Icons.gps_not_fixed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionsPanel(RouteModel route) {
    if (route.steps.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final currentStep = _currentStepIndex != null && _currentStepIndex! < route.steps.length
        ? route.steps[_currentStepIndex!]
        : route.steps[0];
    final stepIndex = _currentStepIndex ?? 0;
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          // Current step display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step ${stepIndex + 1} of ${route.steps.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _stripHtmlTags(currentStep.instructions),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.straighten, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${(currentStep.distance / 1609.34).toStringAsFixed(1)} mi',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${(currentStep.duration / 60).toStringAsFixed(0)} min',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showDirectionsPanel ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                  ),
                  onPressed: () {
                    setState(() {
                      _showDirectionsPanel = !_showDirectionsPanel;
                    });
                  },
                ),
              ],
            ),
          ),
          // Navigation buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              children: [
                // Mode toggle buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isPreviewMode ? null : _enterPreviewMode,
                        icon: const Icon(Icons.preview, size: 18),
                        label: const Text('Preview Route'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: _isPreviewMode ? Colors.blue.shade50 : null,
                          foregroundColor: _isPreviewMode ? Colors.blue.shade900 : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isNavigating ? _stopNavigation : _startNavigation,
                        icon: Icon(_isNavigating ? Icons.stop : Icons.play_arrow, size: 18),
                        label: Text(_isNavigating ? 'Stop' : 'Start Journey'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: _isNavigating ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                // Show Previous/Next buttons in Preview Mode
                if (_isPreviewMode) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: stepIndex > 0
                              ? () => _navigateToStep(-1)
                              : null,
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text('Previous Step'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: stepIndex < route.steps.length - 1
                              ? () => _navigateToStep(1)
                              : null,
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: const Text('Next Step'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Preview Mode: Browse through route steps. Click "Start Journey" to begin navigation.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (_isNavigating) ...[
                  // Show navigation status during active navigation
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.navigation, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Navigation is active. Steps will advance automatically as you travel.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
            // All steps list (scrollable) - only show if expanded
            if (_showDirectionsPanel && route.steps.length > 1)
              Container(
                height: 150,
                child: ListView.builder(
                  itemCount: route.steps.length,
                  itemBuilder: (context, index) {
                final step = route.steps[index];
                final isSelected = index == stepIndex;
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300],
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    _stripHtmlTags(step.instructions),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${(step.distance / 1609.34).toStringAsFixed(1)} mi',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _currentStepIndex = index;
                      _centerOnStep(step);
                      _drawRoute(route);
                    });
                  },
                );
              },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}

