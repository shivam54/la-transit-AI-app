import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chatbot_service.dart';
import '../services/weather_service.dart';
import '../services/places_service.dart';
import '../services/events_service.dart';
import '../services/directions_service.dart';
import '../services/transit_routes_service.dart';
import '../providers/location_provider.dart';
import '../providers/route_provider.dart';
import '../providers/language_provider.dart';
import '../providers/auth_provider.dart';
import '../models/location_model.dart';
import '../models/route_model.dart';
import '../models/chatbot_response_model.dart';
import '../utils/constants.dart';
import 'route_planning_screen.dart';
import 'landmarks_screen.dart';
import 'transit_routes_screen.dart';

/// Chatbot Screen - AI-powered transit assistant
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final ChatbotService _chatbotService = ChatbotService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _showMenu = true; // Track if we should show the menu
  String? _awaitingCategorySelection; // Track if we're waiting for category selection
  String? _awaitingAmenityLocation; // Track if we're waiting for location for amenities
  String? _awaitingTransitOrigin; // Track if we're waiting for transit origin
  String? _awaitingTransitDestination; // Track if we're waiting for transit destination
  bool _awaitingRoutePlanningConfirmation = false; // Track if we're waiting for route planning confirmation
  LocationModel? _storedOrigin; // Store origin for route planning
  LocationModel? _storedDestination; // Store destination for route planning

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addWelcomeMessage();
    });
  }

  void _addWelcomeMessage() {
    final languageProvider = context.read<LanguageProvider>();
    final authProvider = context.read<AuthProvider>();
    final isSpanish = languageProvider.isSpanish;
    final username = authProvider.username;

    String welcomeText;
    if (username != null && username.isNotEmpty) {
      welcomeText = isSpanish
          ? "Hola, $username. Soy Amigo AI, tu compañero de viaje en la ciudad. ¿En qué puedo ayudarte hoy?"
          : "Hi, $username. I'm Amigo AI, your city travel buddy. How can I help you today?";
    } else {
      welcomeText = isSpanish
          ? "¡Hola! Soy Amigo AI, tu compañero de viaje en la ciudad. ¿En qué puedo ayudarte?"
          : "Hi! I'm Amigo AI, your city travel buddy. How can I help you?";
    }

    setState(() {
      _messages.add(ChatMessage(
        text: welcomeText,
        isUser: false,
        timestamp: DateTime.now(),
        showQuickActions: true, // Show quick action buttons
      ));
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Get context
    final locationProvider = context.read<LocationProvider>();
    final routeProvider = context.read<RouteProvider>();
    final languageProvider = context.read<LanguageProvider>();
    
    LocationModel? currentLocation;
    if (locationProvider.hasLocation) {
      currentLocation = locationProvider.currentLocation;
    }

    String? currentRoute;
    if (routeProvider.hasRoute) {
      final route = routeProvider.currentRoute!;
      currentRoute = '${route.origin.address ?? "Origin"} to ${route.destination.address ?? "Destination"}';
    }

    // Build conversation history (last 5 messages for context)
    final history = _messages
        .where((m) => !m.isUser || m.text != text) // Exclude current message
        .take(10)
        .map((m) => '${m.isUser ? "User" : "Assistant"}: ${m.text}')
        .toList();

    try {
      final lowerText = text.toLowerCase();
      
      // Handle "Back to Menu" request
      if (lowerText.contains('back to menu') || lowerText.contains('menu') || lowerText.contains('show menu')) {
        setState(() {
          _showMenu = true;
          _awaitingCategorySelection = null;
          _awaitingTransitOrigin = null;
          _awaitingTransitDestination = null;
          _messages.add(ChatMessage(
            text: languageProvider.isSpanish
                ? 'Volviendo al menú principal...'
                : 'Returning to main menu...',
            isUser: false,
            timestamp: DateTime.now(),
            showQuickActions: true,
          ));
          _isLoading = false;
        });
        _scrollToBottom();
        return;
      }

      // Handle location input for nearby amenities
      if (_awaitingAmenityLocation != null && _awaitingAmenityLocation == '') {
        // User is providing location for amenities
        LocationModel? searchLocation;
        String? locationTextToStore;
        
        // Check if user said "current location" or similar
        if (lowerText.contains('current') || lowerText.contains('my location') || lowerText.contains('here')) {
          if (currentLocation == null) {
            final locationProvider = context.read<LocationProvider>();
            if (locationProvider.hasLocation) {
              searchLocation = locationProvider.currentLocation;
            } else {
              await locationProvider.getCurrentLocation();
              if (locationProvider.hasLocation) {
                searchLocation = locationProvider.currentLocation;
              }
            }
          } else {
            searchLocation = currentLocation;
          }
          locationTextToStore = 'current location';
        } else {
          // Store the user's exact input text first
          final userInputText = text.trim();
          locationTextToStore = userInputText;
          
          // Try to geocode the raw text (user's exact input)
          searchLocation = await _chatbotService.geocodeLocation(userInputText);
          
          // If geocoding fails, show error but still store the text
          if (searchLocation == null) {
            setState(() {
              _messages.add(ChatMessage(
                text: languageProvider.isSpanish
                    ? 'No pude encontrar esa ubicación. Por favor, intenta con una dirección más específica o di "current location".'
                    : 'I couldn\'t find that location. Please try with a more specific address or say "current location".',
                isUser: false,
                timestamp: DateTime.now(),
              ));
              _isLoading = false;
            });
            _scrollToBottom();
            return;
          }
        }
        
        // Store the location (use geocoded location if available, otherwise store the text)
        // We'll geocode again when category is selected to ensure we have the right location
        setState(() {
          _awaitingAmenityLocation = locationTextToStore ?? text.trim();
          _awaitingCategorySelection = ''; // Now ask for category
        });
        
        setState(() {
          _messages.add(ChatMessage(
            text: languageProvider.isSpanish
                ? 'Perfecto. ¿Qué estás buscando?\n\nPuedes decir: comida, estacionamiento, eventos, atracciones, etc.'
                : 'Great! What are you looking for?\n\nYou can say: food, parking, events, attractions, etc.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
        return;
      }

      // Handle category selection for nearby amenities (after location is provided)
      if (_awaitingCategorySelection != null && _awaitingCategorySelection == '' && _awaitingAmenityLocation != null && _awaitingAmenityLocation != '') {
        final category = _chatbotService.getAmenityCategory(text, language: languageProvider.currentLanguage);
        if (category != null || lowerText.contains('food') || lowerText.contains('parking') || lowerText.contains('event') || lowerText.contains('attraction')) {
          // Get the location that was stored - geocode the user's exact input again
          LocationModel? searchLocation;
          
          // Check if it's "current location"
          if (_awaitingAmenityLocation!.toLowerCase().contains('current')) {
            if (currentLocation != null) {
              searchLocation = currentLocation;
            } else {
              final locationProvider = context.read<LocationProvider>();
              if (locationProvider.hasLocation) {
                searchLocation = locationProvider.currentLocation;
              } else {
                await locationProvider.getCurrentLocation();
                if (locationProvider.hasLocation) {
                  searchLocation = locationProvider.currentLocation;
                }
              }
            }
          } else {
            // Geocode the user's exact input text (stored in _awaitingAmenityLocation)
            searchLocation = await _chatbotService.geocodeLocation(_awaitingAmenityLocation!);
          }
          
          // Fallback to current location if geocoding fails
          if (searchLocation == null) {
            if (currentLocation != null) {
              searchLocation = currentLocation;
            } else {
              final locationProvider = context.read<LocationProvider>();
              if (locationProvider.hasLocation) {
                searchLocation = locationProvider.currentLocation;
              } else {
                await locationProvider.getCurrentLocation();
                if (locationProvider.hasLocation) {
                  searchLocation = locationProvider.currentLocation;
                }
              }
            }
          }
          
          if (searchLocation == null) {
            setState(() {
              _messages.add(ChatMessage(
                text: languageProvider.isSpanish
                    ? 'No puedo acceder a la ubicación. Por favor, intenta de nuevo.'
                    : 'I cannot access the location. Please try again.',
                isUser: false,
                timestamp: DateTime.now(),
              ));
              _isLoading = false;
            });
            _scrollToBottom();
            return;
          }
          
          // Determine final category - normalize 'events' to 'event'
          String? finalCategory = category;
          if (finalCategory == null) {
            if (lowerText.contains('event')) {
              finalCategory = 'event';
            } else if (lowerText.contains('food')) {
              finalCategory = 'restaurant';
            } else if (lowerText.contains('parking')) {
              finalCategory = 'parking';
            } else if (lowerText.contains('attraction')) {
              finalCategory = 'tourist_attraction';
            }
          } else if (finalCategory == 'events') {
            // Normalize 'events' to 'event'
            finalCategory = 'event';
          }
          
          // Clear the flags before processing
          final locationToUse = searchLocation;
          setState(() {
            _awaitingCategorySelection = null;
            _awaitingAmenityLocation = null;
          });
          
          await _handleNearbyAmenities(locationToUse, finalCategory, languageProvider, text);
          return;
        }
      }

      // Handle route planning confirmation
      if (_awaitingRoutePlanningConfirmation) {
        final lowerText = text.toLowerCase();
        if (lowerText == 'yes' || lowerText == 'sí' || lowerText == 'y' || lowerText == 'ok' || lowerText == 'okay' || lowerText == 'sure') {
          // Navigate to Plan Route screen with stored locations
          if (_storedOrigin != null && _storedDestination != null) {
            setState(() {
              _awaitingRoutePlanningConfirmation = false;
              _isLoading = false;
            });
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RoutePlanningScreen(
                    initialOrigin: _storedOrigin!,
                    initialDestination: _storedDestination!,
                  ),
                ),
              );
              _addFollowUpPrompt(languageProvider);
            }
            return;
          }
        } else {
          // User said no or something else
          setState(() {
            _awaitingRoutePlanningConfirmation = false;
            _messages.add(ChatMessage(
              text: languageProvider.isSpanish
                  ? 'De acuerdo. ¿Hay algo más en lo que pueda ayudarte?'
                  : 'Okay. Is there anything else I can help you with?',
              isUser: false,
              timestamp: DateTime.now(),
              showQuickActions: true,
            ));
            _isLoading = false;
          });
          _scrollToBottom();
          return;
        }
      }

      // Handle transit info flow
      if (_awaitingTransitOrigin != null || _awaitingTransitDestination != null) {
        final extractedLocations = await _chatbotService.extractLocations(
          message: text,
          currentLocation: currentLocation,
          language: languageProvider.currentLanguage,
        );
        
        // Check if we're waiting for origin (origin is empty string, destination is null)
        if ((_awaitingTransitOrigin == '' || _awaitingTransitOrigin != null) && _awaitingTransitDestination == null) {
          // We're waiting for origin
          if (extractedLocations.hasOrigin || extractedLocations.originText != null || text.trim().isNotEmpty) {
            // Store the user's exact input text (same as amenities flow)
            final originText = text.trim();
            setState(() {
              _awaitingTransitOrigin = originText;
              _awaitingTransitDestination = ''; // Set to empty string to indicate we're now waiting for destination
            });
            setState(() {
              _messages.add(ChatMessage(
                text: languageProvider.isSpanish
                    ? 'Perfecto. ¿Cuál es tu destino?'
                    : 'Great! What\'s your destination?',
                isUser: false,
                timestamp: DateTime.now(),
              ));
              _isLoading = false;
            });
            _scrollToBottom();
            return;
          } else {
            setState(() {
              _messages.add(ChatMessage(
                text: languageProvider.isSpanish
                    ? 'Por favor, proporciona tu punto de origen. Por ejemplo: "From Downtown LA"'
                    : 'Please provide your starting point. For example: "From Downtown LA"',
                isUser: false,
                timestamp: DateTime.now(),
              ));
              _isLoading = false;
            });
            _scrollToBottom();
            return;
          }
        } else if (_awaitingTransitDestination != null && _awaitingTransitOrigin != null && _awaitingTransitOrigin != '') {
          // We're waiting for destination (origin is set, destination is empty string)
          // Accept the text as destination even if extraction didn't work perfectly
          if (extractedLocations.hasDestination || extractedLocations.destinationText != null || text.trim().isNotEmpty) {
            // We have both, now show transit options
            // Store the user's exact input text (same as amenities flow)
            final destinationText = text.trim();
            await _handleTransitInfo(_awaitingTransitOrigin!, destinationText, languageProvider);
            setState(() {
              _awaitingTransitOrigin = null;
              _awaitingTransitDestination = null;
            });
            return;
          } else {
            setState(() {
              _messages.add(ChatMessage(
                text: languageProvider.isSpanish
                    ? 'Por favor, proporciona tu destino. Por ejemplo: "to Hollywood"'
                    : 'Please provide your destination. For example: "to Hollywood"',
                isUser: false,
                timestamp: DateTime.now(),
              ));
              _isLoading = false;
            });
            _scrollToBottom();
            return;
          }
        }
      }

      // Check if user is asking about route planning (even as a question)
      final isRoutePlanningQuestion = (lowerText.contains('plan') && lowerText.contains('route')) ||
                                      (lowerText.contains('how') && lowerText.contains('route')) ||
                                      (lowerText.contains('directions')) ||
                                      (lowerText.contains('navigate')) ||
                                      (lowerText.contains('get to'));
      
      // Check if user wants to plan a route (with locations or just asking)
      final extractedLocations = await _chatbotService.extractLocations(
        message: text,
        currentLocation: currentLocation,
        language: languageProvider.currentLanguage,
      );

      // Check if user wants to plan a route
      // This includes both questions about route planning AND actual route requests
      final hasLocationKeywords = lowerText.contains(' from ') || 
                                  lowerText.contains(' to ') ||
                                  lowerText.contains('towards') ||
                                  RegExp(r'\d+\s+[A-Za-z\s]+(?:Avenue|Street|St|Road|Rd|Boulevard|Blvd|Drive|Dr|Lane|Ln|Way|Court|Ct|Ave)', caseSensitive: false).hasMatch(text);
      
      final wantsRoute = isRoutePlanningQuestion || // Questions about route planning
                         lowerText == 'yes' ||
                         lowerText == 'sure' ||
                         lowerText == 'ok' ||
                         lowerText == 'okay' ||
                         lowerText.contains('let\'s plan') ||
                         lowerText.contains('plan route') ||
                         lowerText.contains('directions from') ||
                         lowerText.contains('directions to') ||
                         hasLocationKeywords ||
                         extractedLocations.isComplete ||
                         extractedLocations.hasOrigin ||
                         extractedLocations.hasDestination;

      if (wantsRoute) {
        // User wants to plan a route
        await _handleRoutePlanning(extractedLocations, languageProvider);
        return;
      }

      // Check if user wants nearby amenities
      if (currentLocation != null && _chatbotService.isAmenityRequest(text, language: languageProvider.currentLanguage)) {
        final category = _chatbotService.getAmenityCategory(text, language: languageProvider.currentLanguage);
        // Normalize 'events' to 'event' immediately
        final normalizedCategory = (category == 'events') ? 'event' : category;
        await _handleNearbyAmenities(currentLocation, normalizedCategory, languageProvider, text);
        return;
      }

      // Check if user is asking about weather - handle deterministically using WeatherService
      final isWeatherQuestion = lowerText.contains('weather') ||
          lowerText.contains('clima') ||
          lowerText.contains('hot outside') ||
          lowerText.contains('cold outside') ||
          lowerText.contains('rain') ||
          lowerText.contains('rainy') ||
          lowerText.contains('temperature') ||
          lowerText.contains('forecast');

      if (isWeatherQuestion) {
        await _handleWeatherQuestion(languageProvider, currentLocation);
        return;
      }

      // Get AI response for other queries
      final response = await _chatbotService.sendMessage(
        message: text,
        currentLocation: currentLocation,
        currentRoute: currentRoute,
        conversationHistory: history,
        language: languageProvider.currentLanguage,
      );

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
            showQuickActions: false, // Don't show quick actions on regular responses
          ));
          _isLoading = false;
        });
        _scrollToBottom();
        // Add follow-up prompt after AI response
        _addFollowUpPrompt(languageProvider);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: languageProvider.isSpanish
                ? 'Lo siento, estoy teniendo problemas para conectarme. Por favor intenta más tarde.'
                : 'Sorry, I\'m having trouble connecting right now. Please try again later.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
        // Add follow-up prompt after error
        _addFollowUpPrompt(languageProvider);
      }
    }
  }

  /// Deterministic weather handler - uses OpenWeatherMap via WeatherService.
  /// This avoids hallucinations by using only real API data.
  Future<void> _handleWeatherQuestion(
    LanguageProvider languageProvider,
    LocationModel? currentLocation,
  ) async {
    setState(() {
      _messages.add(ChatMessage(
        text: languageProvider.isSpanish
            ? 'Consultando el clima actual...'
            : 'Checking the current weather...',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();

    try {
      final weatherService = WeatherService();

      // For this app, always show weather for Los Angeles, regardless of emulator/device GPS.
      // This avoids Mountain View (Android emulator default) and keeps results LA‑focused.
      final double latitude = AppConstants.laCenterLat;
      final double longitude = AppConstants.laCenterLng;

      final weather = await weatherService.getCurrentWeather(
        latitude: latitude,
        longitude: longitude,
      );

      if (weather == null) {
        setState(() {
          _messages.add(ChatMessage(
            text: languageProvider.isSpanish
                ? 'No puedo obtener la información del clima en este momento. Por favor intenta de nuevo más tarde.'
                : 'I cannot retrieve weather information right now. Please try again later.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
        _addFollowUpPrompt(languageProvider);
        return;
      }

      final description = weather['description']?.toString() ?? '';
      final temp = weather['temperature'] ?? 0;
      final feelsLike = weather['feelsLike'] ?? temp;
      final humidity = weather['humidity'] ?? 0;
      final windSpeed = weather['windSpeed'] ?? 0;
      // Always label as Los Angeles for consistency
      final locationText = 'Los Angeles';

      final buffer = StringBuffer();
      if (languageProvider.isSpanish) {
        buffer.writeln('Clima actual en $locationText:');
        buffer.writeln(
            'Condiciones: $description, temperatura ${temp}°F (sensación de ${feelsLike}°F).');
        buffer.writeln('Humedad: ${humidity}%. Viento: ${windSpeed} mph.');
      } else {
        buffer.writeln('Current weather in $locationText:');
        buffer.writeln(
            'Conditions: $description, temperature ${temp}°F (feels like ${feelsLike}°F).');
        buffer.writeln('Humidity: ${humidity}%. Wind: ${windSpeed} mph.');
      }

      setState(() {
        _messages.add(ChatMessage(
          text: buffer.toString(),
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
      _scrollToBottom();
      _addFollowUpPrompt(languageProvider);
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: languageProvider.isSpanish
              ? 'Ocurrió un error al obtener el clima. Por favor intenta de nuevo.'
              : 'There was an error fetching the weather. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
      _scrollToBottom();
      _addFollowUpPrompt(languageProvider);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy, color: Colors.purple),
            SizedBox(width: 8),
            Text('Transit Assistant'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(languageProvider.isSpanish 
                      ? 'Acerca del Asistente de Tránsito' 
                      : 'About Transit Assistant'),
                  content: Text(languageProvider.isSpanish
                      ? 'Puedo ayudarte con:\n\n'
                        '• Planificación de rutas y navegación\n'
                        '• Horarios de tránsito e información en tiempo real\n'
                        '• Encontrar servicios cercanos\n'
                        '• Sugerencias según el clima\n'
                        '• Preguntas generales sobre tránsito\n\n'
                        'Me enfoco en temas de tránsito y navegación. Para otras preguntas, te redirigiré cortésmente.'
                      : 'I can help you with:\n\n'
                        '• Route planning and navigation\n'
                        '• Transit schedules and real-time info\n'
                        '• Finding nearby amenities\n'
                        '• Weather-aware suggestions\n'
                        '• General transit questions\n\n'
                        'I focus on transit and navigation topics. For other questions, I\'ll politely redirect you.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(languageProvider.isSpanish ? 'Entendido' : 'Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  // Loading indicator
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Thinking...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Input area
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: languageProvider.isSpanish
                              ? 'Pregunta sobre rutas, tránsito, clima...'
                              : 'Ask about routes, transit, weather...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      mini: true,
                      onPressed: _isLoading ? null : _sendMessage,
                      backgroundColor: Colors.purple,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle route planning with extracted locations
  Future<void> _handleRoutePlanning(
    ExtractedLocation extracted,
    LanguageProvider languageProvider,
  ) async {
    // Check if we have both locations
    if (!extracted.isComplete) {
      // Ask for missing locations
      String askText;
      if (!extracted.hasOrigin && !extracted.hasDestination) {
        // Need both - make it clear and friendly
        askText = languageProvider.isSpanish
            ? '¡Perfecto! Puedo ayudarte a planificar una ruta ahora mismo.\n\nPara hacerlo, necesito saber:\n\n📍 **Tu punto de origen** (desde dónde quieres salir)\n📍 **Tu destino** (a dónde quieres llegar)\n\nPor favor, escribe algo como:\n"From [tu ubicación] to [destino]"\n\nPor ejemplo: "From Downtown LA to Hollywood" o "From 3105 S Normandie Avenue to 744 S Figueroa street"'
            : 'Great! I can help you plan a route right now.\n\nTo do that, I need to know:\n\n📍 **Your starting point** (where you want to leave from)\n📍 **Your destination** (where you want to go)\n\nPlease type something like:\n"From [your location] to [destination]"\n\nFor example: "From Downtown LA to Hollywood" or "From 3105 S Normandie Avenue to 744 S Figueroa street"';
      } else if (!extracted.hasOrigin) {
        // Need origin
        askText = languageProvider.isSpanish
            ? 'Tengo tu destino. ¿Cuál es tu punto de origen?\n\nPor ejemplo: "From Downtown LA"'
            : 'I have your destination. What\'s your starting point?\n\nFor example: "From Downtown LA"';
      } else {
        // Need destination
        askText = languageProvider.isSpanish
            ? 'Tengo tu origen. ¿Cuál es tu destino?\n\nPor ejemplo: "to Hollywood"'
            : 'I have your origin. What\'s your destination?\n\nFor example: "to Hollywood"';
      }
      
      setState(() {
        _messages.add(ChatMessage(
          text: askText,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    // Always show confirmation with user's ORIGINAL input text first
    // This ensures user sees exactly what they typed, not geocoded results
    final originDisplay = extracted.originText ?? 
                         (extracted.origin != null 
                           ? (extracted.origin!.address ?? extracted.origin!.name ?? 'Current Location')
                           : 'Current Location');
    final destinationDisplay = extracted.destinationText ?? 
                              (extracted.destination != null 
                                ? (extracted.destination!.address ?? extracted.destination!.name ?? 'Unknown')
                                : 'Unknown');
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.isSpanish ? 'Confirmar Ubicaciones' : 'Confirm Locations'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              languageProvider.isSpanish
                  ? '¿Estas ubicaciones son correctas?'
                  : 'Are these locations correct?',
            ),
            const SizedBox(height: 16),
            Text(
              '${languageProvider.isSpanish ? "Origen" : "Origin"}: $originDisplay',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${languageProvider.isSpanish ? "Destino" : "Destination"}: $destinationDisplay',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              languageProvider.isSpanish
                  ? 'Nota: Buscaré la ubicación exacta cuando confirmes.'
                  : 'Note: I will search for the exact location when you confirm.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(languageProvider.isSpanish ? 'Cancelar' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(languageProvider.isSpanish ? 'Confirmar' : 'Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Now geocode AFTER user confirms (so they see their exact input first)
    LocationModel? finalOrigin = extracted.origin;
    LocationModel? finalDestination = extracted.destination;
    
    if (finalOrigin == null && extracted.originText != null && extracted.originText!.toLowerCase() != 'current location') {
      setState(() {
        _messages.add(ChatMessage(
          text: languageProvider.isSpanish
              ? 'Buscando tu origen...'
              : 'Searching for your origin...',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
      finalOrigin = await _chatbotService.geocodeLocation(extracted.originText!);
    } else if (finalOrigin == null) {
      // Use current location
      final locationProvider = context.read<LocationProvider>();
      if (locationProvider.hasLocation) {
        finalOrigin = locationProvider.currentLocation;
      }
    }
    
    if (finalDestination == null && extracted.destinationText != null) {
      setState(() {
        _messages.add(ChatMessage(
          text: languageProvider.isSpanish
              ? 'Buscando tu destino...'
              : 'Searching for your destination...',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
      finalDestination = await _chatbotService.geocodeLocation(extracted.destinationText!);
    }
    
    if (finalOrigin != null && finalDestination != null) {
      _navigateToRoutePlanning(finalOrigin, finalDestination);
    } else {
      setState(() {
        _messages.add(ChatMessage(
          text: languageProvider.isSpanish
              ? 'No pude encontrar una o ambas ubicaciones. Por favor, intenta con direcciones más específicas.'
              : 'I couldn\'t find one or both locations. Please try with more specific addresses.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }

    setState(() {
      _isLoading = false;
    });
    _scrollToBottom();
  }

  /// Navigate to route planning screen with pre-filled locations
  void _navigateToRoutePlanning(LocationModel origin, LocationModel destination) {
    final languageProvider = context.read<LanguageProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoutePlanningScreen(
          initialOrigin: origin,
          initialDestination: destination,
        ),
      ),
    );
    // Add follow-up prompt after navigation
    _addFollowUpPrompt(languageProvider);
  }

  /// Handle transit info request - show recommendations in chat, then ask if they want to plan route
  Future<void> _handleTransitInfo(
    String originText,
    String destinationText,
    LanguageProvider languageProvider,
  ) async {
    setState(() {
      _messages.add(ChatMessage(
        text: languageProvider.isSpanish
            ? 'Analizando las mejores opciones de viaje...'
            : 'Analyzing the best travel options...',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();

    try {
      // Geocode locations using the user's exact input text (same logic as amenities)
      LocationModel? origin;
      LocationModel? destination;
      
      // Check if origin is "current location"
      if (originText.toLowerCase().contains('current') || originText.toLowerCase().contains('my location') || originText.toLowerCase().contains('here')) {
        final locationProvider = context.read<LocationProvider>();
        if (locationProvider.hasLocation) {
          origin = locationProvider.currentLocation;
        } else {
          await locationProvider.getCurrentLocation();
          if (locationProvider.hasLocation) {
            origin = locationProvider.currentLocation;
          }
        }
      } else {
        // Geocode the user's exact input text
        origin = await _chatbotService.geocodeLocation(originText);
      }
      
      // Check if destination is "current location"
      if (destinationText.toLowerCase().contains('current') || destinationText.toLowerCase().contains('my location') || destinationText.toLowerCase().contains('here')) {
        final locationProvider = context.read<LocationProvider>();
        if (locationProvider.hasLocation) {
          destination = locationProvider.currentLocation;
        } else {
          await locationProvider.getCurrentLocation();
          if (locationProvider.hasLocation) {
            destination = locationProvider.currentLocation;
          }
        }
      } else {
        // Geocode the user's exact input text
        destination = await _chatbotService.geocodeLocation(destinationText);
      }

      if (origin == null || destination == null) {
        setState(() {
          _messages.add(ChatMessage(
            text: languageProvider.isSpanish
                ? 'No pude encontrar una o ambas ubicaciones. Por favor, intenta con direcciones más específicas.'
                : 'I couldn\'t find one or both locations. Please try with more specific addresses.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
        return;
      }

      // Store locations for route planning
      _storedOrigin = origin;
      _storedDestination = destination;

      // Fetch all route options in parallel
      final transitRoutesService = TransitRoutesService();
      final directionsService = DirectionsService();
      final weatherService = WeatherService();

      // Get transit routes, driving route, and weather
      final transitRoutesFuture = transitRoutesService.getTransitRoutes(
        origin: origin,
        destination: destination,
      );
      final drivingRouteFuture = directionsService.getDrivingRoutes(
        origin: origin,
        destination: destination,
      );
      final weatherFuture = weatherService.getCurrentWeather(
        latitude: origin.latitude,
        longitude: origin.longitude,
      );

      final results = await Future.wait([
        transitRoutesFuture,
        drivingRouteFuture,
        weatherFuture,
      ]);

      final transitRoutes = results[0] as List<RouteModel>;
      final drivingRoutes = results[1] as List<RouteModel>;
      final weather = results[2] as Map<String, dynamic>?;

      // Build recommendations message
      final recommendations = StringBuffer();
      
      if (languageProvider.isSpanish) {
        recommendations.writeln('Recomendaciones de viaje:\n');
      } else {
        recommendations.writeln('Travel Recommendations:\n');
      }

      // Weather consideration
      String? weatherAdvice;
      if (weather != null) {
        final condition = weather['condition']?.toString().toLowerCase() ?? '';
        final temp = weather['temperature'] ?? 0;
        final description = weather['description'] ?? '';
        
        if (condition.contains('rain') || condition.contains('storm') || condition.contains('snow')) {
          weatherAdvice = languageProvider.isSpanish
              ? 'Nota: El clima actual es $description (${temp}°F). Te recomendamos considerar transporte público o ride-share para evitar conducir en condiciones adversas.\n'
              : 'Note: Current weather is $description (${temp}°F). We recommend considering public transit or ride-share to avoid driving in adverse conditions.\n';
        } else if (temp > 85) {
          weatherAdvice = languageProvider.isSpanish
              ? 'Nota: Hace calor (${temp}°F). El transporte público con aire acondicionado puede ser más cómodo.\n'
              : 'Note: It\'s hot (${temp}°F). Air-conditioned public transit may be more comfortable.\n';
        } else if (temp < 50) {
          weatherAdvice = languageProvider.isSpanish
              ? 'Nota: Hace frío (${temp}°F). Considera ride-share o conducir para mayor comodidad.\n'
              : 'Note: It\'s cold (${temp}°F). Consider ride-share or driving for more comfort.\n';
        }
      }

      // Best transit route
      if (transitRoutes.isNotEmpty) {
        final bestTransit = transitRoutes.first;
        final durationMinutes = (bestTransit.totalDuration / 60).round();
        final distanceMiles = (bestTransit.totalDistance / 1609.34).toStringAsFixed(1);
        
        // Extract transit line info
        String transitInfo = '';
        if (bestTransit.transitDetails != null && bestTransit.transitDetails!.isNotEmpty) {
          final firstTransit = bestTransit.transitDetails!.first;
          final lineName = firstTransit['line']?['short_name'] ?? 
                         firstTransit['line']?['name'] ?? 'transit';
          transitInfo = languageProvider.isSpanish
              ? ' (Línea $lineName)'
              : ' (Line $lineName)';
        }

        if (languageProvider.isSpanish) {
          recommendations.writeln('Mejor opción de transporte público:');
          recommendations.writeln('Tiempo estimado: $durationMinutes minutos');
          recommendations.writeln('Distancia: $distanceMiles millas$transitInfo');
          recommendations.writeln('Ideal para ahorrar dinero y tiempo mientras viajas por la ciudad.\n');
        } else {
          recommendations.writeln('Best Public Transit Option:');
          recommendations.writeln('Estimated time: $durationMinutes minutes');
          recommendations.writeln('Distance: $distanceMiles miles$transitInfo');
          recommendations.writeln('Ideal for saving money and time while traveling through the city.\n');
        }
      }

      // Driving route
      if (drivingRoutes.isNotEmpty) {
        final bestDriving = drivingRoutes.first;
        final durationMinutes = (bestDriving.totalDuration / 60).round();
        final distanceMiles = (bestDriving.totalDistance / 1609.34).toStringAsFixed(1);
        
        if (languageProvider.isSpanish) {
          recommendations.writeln('Opción de conducir:');
          recommendations.writeln('Tiempo estimado: $durationMinutes minutos');
          recommendations.writeln('Distancia: $distanceMiles millas');
          recommendations.writeln('Perfecto si valoras la comodidad y la flexibilidad en tu viaje.\n');
        } else {
          recommendations.writeln('Driving Option:');
          recommendations.writeln('Estimated time: $durationMinutes minutes');
          recommendations.writeln('Distance: $distanceMiles miles');
          recommendations.writeln('Perfect if you value comfort and flexibility in your journey.\n');
        }
      }

      // Ride-share options
      if (languageProvider.isSpanish) {
        recommendations.writeln('Servicios de ride-share:');
        recommendations.writeln('Disponible a través de Uber, Lyft y Waymo');
        recommendations.writeln('Una excelente alternativa si prefieres no conducir o usar transporte público.');
      } else {
        recommendations.writeln('Ride-Share Services:');
        recommendations.writeln('Available through Uber, Lyft, and Waymo');
        recommendations.writeln('An excellent alternative if you prefer not to drive or use public transit.');
      }
      
      if (weatherAdvice != null) {
        recommendations.writeln();
        recommendations.write(weatherAdvice);
      }

      // Add weather advice if available
      if (weatherAdvice != null) {
        recommendations.writeln(weatherAdvice);
        recommendations.writeln();
      }

      // Show recommendations
      setState(() {
        _messages.add(ChatMessage(
          text: recommendations.toString(),
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();

      // Ask if they want to plan route
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _awaitingRoutePlanningConfirmation = true;
        _messages.add(ChatMessage(
          text: languageProvider.isSpanish
              ? '¿Te gustaría planificar una ruta ahora?'
              : 'Would you like to plan a route now?',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
      _scrollToBottom();

    } catch (e) {
      print('❌ Error in transit info: $e');
      setState(() {
        _messages.add(ChatMessage(
          text: languageProvider.isSpanish
              ? 'Error al buscar opciones de tránsito. Por favor intenta de nuevo.'
              : 'Error searching for transit options. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
      _scrollToBottom();
      _addFollowUpPrompt(languageProvider);
    }
  }

  /// Handle nearby amenities request - display results in chat (same method as route planning)
  Future<void> _handleNearbyAmenities(
    LocationModel searchLocation,
    String? category,
    LanguageProvider languageProvider,
    String userMessage,
  ) async {
    setState(() {
      _messages.add(ChatMessage(
        text: languageProvider.isSpanish
            ? 'Buscando lugares cercanos...'
            : 'Searching for nearby places...',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();

    try {
      // Normalize category - ensure 'events' becomes 'event'
      // Also handle null category by checking if user message contains 'event'
      String? normalizedCategory = category;
      if (normalizedCategory == 'events') {
        normalizedCategory = 'event';
      } else if (normalizedCategory == null && userMessage.toLowerCase().contains('event')) {
        normalizedCategory = 'event';
      }
      
      print('🔍 Category: $category, Normalized: $normalizedCategory');
      
      // Special handling for events - use EventsService ONLY
      if (normalizedCategory == 'event') {
        final eventsService = EventsService();
        final events = await eventsService.getNearbyEvents(
          latitude: searchLocation.latitude,
          longitude: searchLocation.longitude,
          radiusMiles: 5,
        );

        if (events.isEmpty) {
          setState(() {
            _messages.add(ChatMessage(
              text: languageProvider.isSpanish
                  ? 'No se encontraron eventos cercanos para hoy. Intenta buscar eventos para otra fecha.'
                  : 'No nearby events found for today. Try searching for events on another date.',
              isUser: false,
              timestamp: DateTime.now(),
            ));
          });
        } else {
          final locations = events.map((e) => e.location).toList();
          setState(() {
            _messages.add(ChatMessage(
              text: languageProvider.isSpanish
                  ? 'Encontré ${events.length} eventos cercanos para hoy:'
                  : 'Found ${events.length} nearby events for today:',
              isUser: false,
              timestamp: DateTime.now(),
              locations: locations,
              category: 'event',
            ));
          });
        }
        // IMPORTANT: Return early to prevent falling through to PlacesService
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
        _addFollowUpPrompt(languageProvider);
        return;
      }
      
      // Additional safeguard: if user message contains 'event', don't use PlacesService
      if (userMessage.toLowerCase().contains('event') && normalizedCategory != 'event') {
        // User mentioned event but category wasn't detected - still use EventsService
        final eventsService = EventsService();
        final events = await eventsService.getNearbyEvents(
          latitude: searchLocation.latitude,
          longitude: searchLocation.longitude,
          radiusMiles: 5,
        );

        if (events.isEmpty) {
          setState(() {
            _messages.add(ChatMessage(
              text: languageProvider.isSpanish
                  ? 'No se encontraron eventos cercanos para hoy. Intenta buscar eventos para otra fecha.'
                  : 'No nearby events found for today. Try searching for events on another date.',
              isUser: false,
              timestamp: DateTime.now(),
            ));
          });
        } else {
          final locations = events.map((e) => e.location).toList();
          setState(() {
            _messages.add(ChatMessage(
              text: languageProvider.isSpanish
                  ? 'Encontré ${events.length} eventos cercanos para hoy:'
                  : 'Found ${events.length} nearby events for today:',
              isUser: false,
              timestamp: DateTime.now(),
              locations: locations,
              category: 'event',
            ));
          });
        }
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
        _addFollowUpPrompt(languageProvider);
        return;
      }
      
      // Use PlacesService (same as route planning screen) - ONLY if not events
      {
        final placesService = PlacesService();
        List<String>? types;
        
        // Map category to Google Places API types (same as LandmarksScreen)
        if (normalizedCategory == 'restaurant' || normalizedCategory == 'food') {
          types = ['restaurant', 'cafe', 'meal_takeaway'];
        } else if (normalizedCategory == 'cafe') {
          types = ['cafe', 'bakery'];
        } else if (normalizedCategory == 'parking') {
          types = ['parking'];
        } else if (normalizedCategory == 'gas_station') {
          types = ['gas_station'];
        } else if (normalizedCategory == 'pharmacy') {
          types = ['pharmacy', 'drugstore'];
        } else if (normalizedCategory == 'hospital') {
          types = ['hospital', 'doctor', 'dentist'];
        } else if (normalizedCategory == 'bank') {
          types = ['bank', 'atm'];
        } else if (normalizedCategory == 'supermarket') {
          types = ['supermarket', 'grocery_store', 'convenience_store'];
        } else if (normalizedCategory == 'tourist_attraction' || normalizedCategory == 'attraction') {
          types = ['tourist_attraction', 'museum', 'art_gallery', 'park'];
        } else if (normalizedCategory == 'shopping') {
          types = ['shopping_mall', 'store', 'clothing_store'];
        }
        // If no category specified, search all types (same as LandmarksPanelWidget)
        // BUT: Never search for places if user asked for events
        if (userMessage.toLowerCase().contains('event')) {
          setState(() {
            _messages.add(ChatMessage(
              text: languageProvider.isSpanish
                  ? 'No se encontraron eventos cercanos para hoy. Intenta buscar eventos para otra fecha.'
                  : 'No nearby events found for today. Try searching for events on another date.',
              isUser: false,
              timestamp: DateTime.now(),
            ));
            _isLoading = false;
          });
          _scrollToBottom();
          _addFollowUpPrompt(languageProvider);
          return;
        }

        // Use same method as route planning screen - searchNearbyLandmarks with proper radius
        final landmarks = await placesService.searchNearbyLandmarks(
          latitude: searchLocation.latitude,
          longitude: searchLocation.longitude,
          radius: AppConstants.defaultSearchRadius, // Same as LandmarksScreen uses
          includedTypes: types, // Filter by category if specified
          includeAccessibility: true, // Include accessibility info
        );

        if (landmarks.isEmpty) {
          setState(() {
            _messages.add(ChatMessage(
              text: languageProvider.isSpanish
                  ? 'No se encontraron lugares cercanos. Intenta con una categoría diferente o verifica tu ubicación.'
                  : 'No nearby places found. Try a different category or check your location.',
              isUser: false,
              timestamp: DateTime.now(),
            ));
          });
        } else {
          // Display landmarks in chat (same format as before but using correct location)
          // Map category to user-friendly display name
          String displayCategory;
          if (languageProvider.isSpanish) {
            switch (normalizedCategory) {
              case 'restaurant':
              case 'food':
                displayCategory = 'restaurantes';
                break;
              case 'parking':
                displayCategory = 'estacionamiento';
                break;
              case 'gas_station':
                displayCategory = 'gasolineras';
                break;
              case 'pharmacy':
                displayCategory = 'farmacias';
                break;
              case 'hospital':
                displayCategory = 'hospitales';
                break;
              case 'bank':
                displayCategory = 'bancos';
                break;
              case 'supermarket':
                displayCategory = 'supermercados';
                break;
              case 'tourist_attraction':
              case 'attraction':
                displayCategory = 'atracciones';
                break;
              case 'shopping':
                displayCategory = 'tiendas';
                break;
              case 'cafe':
                displayCategory = 'cafés';
                break;
              default:
                displayCategory = 'lugares';
            }
          } else {
            switch (normalizedCategory) {
              case 'restaurant':
              case 'food':
                displayCategory = 'restaurants';
                break;
              case 'parking':
                displayCategory = 'parking';
                break;
              case 'gas_station':
                displayCategory = 'gas stations';
                break;
              case 'pharmacy':
                displayCategory = 'pharmacies';
                break;
              case 'hospital':
                displayCategory = 'hospitals';
                break;
              case 'bank':
                displayCategory = 'banks';
                break;
              case 'supermarket':
                displayCategory = 'supermarkets';
                break;
              case 'tourist_attraction':
              case 'attraction':
                displayCategory = 'attractions';
                break;
              case 'shopping':
                displayCategory = 'shops';
                break;
              case 'cafe':
                displayCategory = 'cafes';
                break;
              default:
                displayCategory = 'places';
            }
          }
          
          final locations = landmarks.map((l) => l.location).toList();
          
          setState(() {
            _messages.add(ChatMessage(
              text: languageProvider.isSpanish
                  ? '$displayCategory cercanos'
                  : 'Nearby $displayCategory',
              isUser: false,
              timestamp: DateTime.now(),
              locations: locations,
              category: normalizedCategory,
            ));
          });
        }
      }
    } catch (e) {
      print('❌ Error fetching amenities: $e');
      setState(() {
        _messages.add(ChatMessage(
          text: languageProvider.isSpanish
              ? 'Error al buscar lugares cercanos. Por favor intenta de nuevo.'
              : 'Error searching for nearby places. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
      // Add follow-up prompt after showing results
      _addFollowUpPrompt(languageProvider);
    }
  }

  /// Add a follow-up prompt asking if user needs more help
  void _addFollowUpPrompt(LanguageProvider languageProvider) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: languageProvider.isSpanish
                ? '¿Necesitas algo más?'
                : 'Need anything else?',
            isUser: false,
            timestamp: DateTime.now(),
            showQuickActions: true, // Show quick action buttons
          ));
        });
        _scrollToBottom();
      }
    });
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final languageProvider = context.watch<LanguageProvider>();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.purple[100],
                  child: const Icon(Icons.smart_toy, size: 18, color: Colors.purple),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isUser ? Colors.purple : Colors.grey[200],
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: message.isUser ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                      // Display locations list if available
                      if (message.locations != null && message.locations!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...message.locations!.take(10).map((location) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: message.isUser 
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: message.isUser 
                                      ? Colors.white.withOpacity(0.3)
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 18,
                                    color: message.isUser ? Colors.white : Colors.purple,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          location.name ?? location.address ?? 'Location',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: message.isUser ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        if (location.address != null && location.address != location.name)
                                          Text(
                                            location.address!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: message.isUser 
                                                  ? Colors.white70 
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                ),
              ),
              if (message.isUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue[100],
                  child: const Icon(Icons.person, size: 18, color: Colors.blue),
                ),
              ],
            ],
          ),
          // Quick action buttons
          if (message.showQuickActions && !message.isUser) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickActionChip(
                  languageProvider.isSpanish ? 'Planificar Ruta' : 'Plan Route',
                  Icons.route,
                  null, // null means navigate directly
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RoutePlanningScreen(),
                      ),
                    );
                  },
                ),
                _buildQuickActionChip(
                  languageProvider.isSpanish ? 'Clima Actual' : 'Current Weather',
                  Icons.wb_sunny,
                  languageProvider.isSpanish 
                      ? '¿Cómo está el clima?'
                      : 'What\'s the weather like?',
                ),
                _buildQuickActionChip(
                  languageProvider.isSpanish ? 'Información de Tránsito' : 'Transit Info',
                  Icons.directions_bus,
                  null, // null means handle specially
                  onTap: () {
                    setState(() {
                      _showMenu = false;
                      _awaitingTransitOrigin = ''; // Empty string means we're waiting for origin
                      _awaitingTransitDestination = null; // Not waiting for destination yet
                      _messages.add(ChatMessage(
                        text: languageProvider.isSpanish
                            ? 'Para obtener información de tránsito, necesito tu origen y destino.\n\n¿Cuál es tu punto de origen?'
                            : 'To get transit information, I need your origin and destination.\n\nWhat\'s your starting point?',
                        isUser: false,
                        timestamp: DateTime.now(),
                      ));
                    });
                    _scrollToBottom();
                  },
                ),
                _buildQuickActionChip(
                  languageProvider.isSpanish ? 'Lugares Cercanos' : 'Nearby Amenities',
                  Icons.location_on,
                  null, // null means handle specially
                  onTap: () {
                    setState(() {
                      _showMenu = false;
                      _awaitingAmenityLocation = ''; // Empty string means we're waiting for location
                      _awaitingCategorySelection = null; // Not waiting for category yet
                      _messages.add(ChatMessage(
                        text: languageProvider.isSpanish
                            ? 'Para buscar lugares cercanos, necesito saber la ubicación.\n\n¿Dónde quieres buscar? Puedes decir una dirección o "current location" para usar tu ubicación actual.'
                            : 'To search for nearby places, I need to know the location.\n\nWhere would you like to search? You can say an address or "current location" to use your current location.',
                        isUser: false,
                        timestamp: DateTime.now(),
                      ));
                    });
                    _scrollToBottom();
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(
    String label,
    IconData icon,
    String? query, {
    VoidCallback? onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: Colors.purple),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.purple[50],
      side: BorderSide(color: Colors.purple[200]!),
      onPressed: () {
        if (onTap != null) {
          onTap();
        } else if (query != null) {
          _messageController.text = query;
          _sendMessage();
        }
      },
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool showQuickActions; // Show quick action buttons for assistant messages
  final List<LocationModel>? locations; // For nearby amenities
  final String? category; // For amenities category

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.showQuickActions = false,
    this.locations,
    this.category,
  });
}

