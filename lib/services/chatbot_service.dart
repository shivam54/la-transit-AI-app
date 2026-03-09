import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/constants.dart';
import '../models/location_model.dart';
import '../models/chatbot_response_model.dart';
import 'weather_service.dart';
import 'places_service.dart';

/// Chatbot Service using Groq API
/// Provides AI-powered assistance for transit-related queries
class ChatbotService {
  final Dio _dio = Dio();
  final String _apiKey = AppConstants.groqApiKey;
  final String _baseUrl = 'https://api.groq.com/openai/v1';
  final WeatherService _weatherService = WeatherService();

  /// Send a message to the chatbot
  Future<String> sendMessage({
    required String message,
    LocationModel? currentLocation,
    String? currentRoute,
    List<String> conversationHistory = const [],
    String language = 'en', // 'en' or 'es'
  }) async {
    try {
      // Get weather data if available
      String weatherContext = '';
      if (currentLocation != null) {
        try {
          final weather = await _weatherService.getCurrentWeather(
            latitude: currentLocation.latitude,
            longitude: currentLocation.longitude,
          );
          if (weather != null) {
            final condition = weather['condition']?.toString() ?? 'unknown';
            final temp = weather['temperature'] ?? 0;
            final description = weather['description']?.toString() ?? '';
            final humidity = weather['humidity'] ?? 0;
            
            if (language == 'es') {
              weatherContext = '\nClima Actual: $description, ${temp}°F, $humidity% humedad.';
            } else {
              weatherContext = '\nCurrent Weather: $description, ${temp}°F, $humidity% humidity.';
            }
            print('✅ Weather data fetched: $description, ${temp}°F');
          } else {
            print('⚠️ Weather data is null - API key may be missing or request failed');
          }
        } catch (e) {
          // Weather fetch failed, continue without it
          print('⚠️ Weather fetch failed: $e');
        }
      }

      // Build system prompt focused on transit assistance
      final systemPrompt = _buildSystemPrompt(
        currentLocation: currentLocation,
        currentRoute: currentRoute,
        weatherContext: weatherContext,
        language: language,
      );

      // Build conversation messages - ensure proper format
      final messages = <Map<String, dynamic>>[];
      
      // Add system message
      messages.add({
        'role': 'system',
        'content': systemPrompt,
      });
      
      // Add conversation history
      for (final msg in conversationHistory) {
        final role = msg.startsWith('User:') ? 'user' : 'assistant';
        final content = msg.replaceFirst(RegExp(r'^(User|Assistant):\s*'), '').trim();
        if (content.isNotEmpty) {
          messages.add({
            'role': role,
            'content': content,
          });
        }
      }
      
      // Add current user message
      messages.add({
        'role': 'user',
        'content': message.trim(),
      });
      
      // Validate messages
      for (final msg in messages) {
        if (msg['role'] == null || msg['content'] == null) {
          print('⚠️ Invalid message: $msg');
        }
      }

      // Validate API key
      if (_apiKey.isEmpty || _apiKey.trim().isEmpty) {
        print('❌ Groq API key is empty');
        return language == 'es'
            ? 'Error de configuración: La clave de API no está configurada.'
            : 'Configuration error: API key is not set.';
      }

      print('🔍 Calling Groq API with model: llama-3.1-70b-versatile');
      print('📤 Request messages count: ${messages.length}');
      print('📤 First message role: ${messages.isNotEmpty ? messages[0]['role'] : 'none'}');
      
      // Try with llama-3.1-8b-instant first (faster and more reliable)
      // Available models: llama-3.1-70b-versatile, llama-3.1-8b-instant, mixtral-8x7b-32768
      final model = 'llama-3.1-8b-instant'; // Faster model, less likely to have issues
      
      // Call Groq API with timeout
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          validateStatus: (status) => status! < 500, // Accept 4xx as valid to handle errors
        ),
        data: {
          'model': model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 500,
        },
      );

      print('📡 Groq API response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['choices'] != null && 
            (data['choices'] as List).isNotEmpty &&
            data['choices'][0]['message'] != null) {
          final content = data['choices'][0]['message']['content'] as String;
          print('✅ Got response from Groq API');
          return content.trim();
        } else {
          print('⚠️ Groq API response missing choices or content: ${data}');
          return language == 'es'
              ? 'Lo siento, la respuesta del servidor no es válida. Por favor intenta de nuevo.'
              : 'Sorry, the server response is invalid. Please try again.';
        }
      } else {
        // Handle error response
        final errorData = response.data;
        String errorMessage = 'Unknown error';
        
        if (errorData is Map) {
          if (errorData['error'] != null && errorData['error'] is Map) {
            errorMessage = errorData['error']['message']?.toString() ?? 
                          errorData['error'].toString();
          } else {
            errorMessage = errorData['message']?.toString() ?? errorData.toString();
          }
        }
        
        print('❌ Groq API error (${response.statusCode}): $errorMessage');
        print('❌ Full error response: $errorData');
        
        // Provide helpful error message
        if (response.statusCode == 400) {
          return language == 'es'
              ? 'Error en la solicitud. Por favor intenta reformular tu pregunta o intenta de nuevo.'
              : 'Request error. Please try rephrasing your question or try again.';
        }
        
        final errorMsg = language == 'es'
            ? 'Lo siento, encontré un error. Por favor intenta de nuevo.'
            : 'Sorry, I encountered an error. Please try again.';
        return errorMsg;
      }
    } catch (e) {
      print('❌ Chatbot error: $e');
      if (e is DioException) {
        if (e.response != null) {
          print('Response status: ${e.response?.statusCode}');
          print('Response data: ${e.response?.data}');
          
          // Handle specific error cases
          if (e.response?.statusCode == 401) {
            return language == 'es'
                ? 'Error de autenticación. Por favor verifica la configuración de la API.'
                : 'Authentication error. Please check API configuration.';
          } else if (e.response?.statusCode == 429) {
            return language == 'es'
                ? 'Demasiadas solicitudes. Por favor espera un momento e intenta de nuevo.'
                : 'Too many requests. Please wait a moment and try again.';
          }
        } else if (e.type == DioExceptionType.connectionTimeout ||
                   e.type == DioExceptionType.receiveTimeout) {
          return language == 'es'
              ? 'Tiempo de espera agotado. Por favor verifica tu conexión a internet e intenta de nuevo.'
              : 'Connection timeout. Please check your internet connection and try again.';
        } else if (e.type == DioExceptionType.connectionError) {
          return language == 'es'
              ? 'Error de conexión. Por favor verifica tu conexión a internet.'
              : 'Connection error. Please check your internet connection.';
        }
      }
      
      final errorMsg = language == 'es'
          ? 'Lo siento, estoy teniendo problemas para conectarme. Por favor intenta más tarde.'
          : 'Sorry, I\'m having trouble connecting right now. Please try again later.';
      return errorMsg;
    }
  }

  /// Build system prompt for transit-focused assistance
  String _buildSystemPrompt({
    LocationModel? currentLocation,
    String? currentRoute,
    String weatherContext = '',
    String language = 'en',
  }) {
    final locationInfo = currentLocation != null
        ? 'User is currently at: ${currentLocation.address ?? '${currentLocation.latitude}, ${currentLocation.longitude}'}'
        : 'User location is not available.';

    final routeInfo = currentRoute != null
        ? 'User has an active route: $currentRoute'
        : 'User does not have an active route.';

    final isSpanish = language == 'es';
    final languageInstruction = isSpanish
        ? 'IMPORTANT: You MUST respond entirely in Spanish (Español). All your responses should be in Spanish.'
        : 'IMPORTANT: You MUST respond entirely in English. All your responses should be in English.';

    final redirectMessage = isSpanish
        ? 'Estoy aquí para ayudarte con tránsito y navegación en LA. ¿Cómo puedo ayudarte con tu viaje?'
        : "I'm here to help with transit and navigation in LA. How can I assist you with your journey?";

    final appFeatureMessage = isSpanish
        ? 'Puedes usar la función "Planificar Ruta" para encontrar la mejor ruta'
        : "You can use the 'Plan Route' feature to find the best route";

    return '''You are Amigo AI, a friendly city travel assistant for the Amigo AI app. Your purpose is to assist users with transit-related queries in Los Angeles and help them discover useful places nearby.

$languageInstruction

CONTEXT:
- $locationInfo
- $routeInfo$weatherContext

CAPABILITIES:
1. **Route Planning**: Help users plan routes, find transit options, and navigate LA
2. **Transit Information**: Provide information about LA Metro, Metrolink, buses, and other transit options
3. **Weather Impact**: Consider weather conditions when suggesting transit options (ONLY if weather data is provided in context)
4. **Nearby Amenities**: Help users find restaurants, parking, gas stations, and other services
5. **App Navigation**: Guide users on how to use app features

IMPORTANT RULES:
- If weather data is NOT provided in the context above, DO NOT make up or guess weather information
- If user asks about weather and no weather data is available, politely inform them that weather information is currently unavailable
- Only provide weather information if it's explicitly included in the context above
6. **General Transit Questions**: Answer questions about schedules, fares, accessibility, etc.

GUIDELINES:
- Be CLEAR and ACTIONABLE - provide step-by-step instructions
- Use simple, direct language - avoid technical jargon
- IMPORTANT: When user asks "How do I plan a route?" or similar questions, DO NOT give step-by-step instructions. Instead, tell them you can help them plan a route right now by asking: "I can help you plan a route! Where would you like to go from and to?"
- For other route planning questions without locations, ask: "I'd be happy to help you plan a route! Please tell me your starting point and destination."
- Be concise, friendly, and helpful
- Focus on transit and navigation topics
- If asked about something unrelated to transit/navigation, politely redirect: "$redirectMessage"
- Use weather information to provide relevant advice (e.g., "It's raining, consider covered transit options")
- Suggest using app features when relevant (e.g., "$appFeatureMessage")
- If you don't know specific schedule information, suggest checking the app's real-time arrivals feature

RESPONSE STYLE:
- Be CLEAR and ACTIONABLE - tell users exactly what to do
- Use simple, direct language - avoid jargon
- When suggesting routes, provide specific steps: "1. Go to the 'Plan Route' screen, 2. Enter your origin and destination, 3. Select your preferred transport mode"
- Use numbered lists or bullet points for multiple steps
- Keep responses concise (2-3 sentences for simple queries, 4-5 for complex ones)
- Be conversational but professional
- Emphasize safety and accessibility when relevant
- ALWAYS respond in ${isSpanish ? 'Spanish' : 'English'} based on user's language preference
- If user asks to plan a route, provide clear step-by-step instructions on how to use the app's route planning feature''';
  }

  final PlacesService _placesService = PlacesService();

  /// Extract location information from user message
  Future<ExtractedLocation> extractLocations({
    required String message,
    LocationModel? currentLocation,
    String language = 'en',
  }) async {
    final lowerMessage = message.toLowerCase();
    
    // Check if this is a question (how, what, where, etc.) - don't extract locations from questions
    final questionPatterns = language == 'es'
        ? ['cómo', 'qué', 'dónde', 'cuándo', 'por qué', 'cómo se', 'cómo puedo', 'qué es', 'dónde está']
        : ['how', 'what', 'where', 'when', 'why', 'how do', 'how can', 'how to', 'what is', 'where is', 'tell me'];
    
    final isQuestion = questionPatterns.any((pattern) => lowerMessage.startsWith(pattern) || lowerMessage.contains(' $pattern '));
    
    // If it's a question, don't extract locations
    if (isQuestion) {
      return ExtractedLocation();
    }
    
    // Check if message contains addresses (numbers + street names) - this is a strong indicator
    final hasAddressPattern = RegExp(r'\d+\s+[A-Za-z\s]+(?:Avenue|Street|St|Road|Rd|Boulevard|Blvd|Drive|Dr|Lane|Ln|Way|Court|Ct|Ave)', caseSensitive: false).hasMatch(message);
    
    // Check for location keywords that indicate actual locations (not questions)
    final locationKeywords = language == 'es'
        ? ['desde', 'hacia', 'a', 'hasta']
        : ['from', 'to', 'towards'];
    
    final hasLocationKeywords = locationKeywords.any((keyword) => lowerMessage.contains(' $keyword '));
    
    // Only extract if it has addresses OR location keywords (not just route planning keywords)
    if (!hasAddressPattern && !hasLocationKeywords) {
      return ExtractedLocation();
    }

    // Try to extract origin and destination from message
    String? originText;
    String? destinationText;

    // Patterns: "from X to Y", "to Y from X", "X to Y", etc.
    // Also handle addresses like "3105 S Normandie Avenue to 744 S Figueroa street"
    // Use non-greedy matching but ensure we capture full addresses
    final fromToPattern = RegExp(r'from\s+(.+?)\s+to\s+(.+)$', caseSensitive: false);
    final toFromPattern = RegExp(r'to\s+(.+?)\s+from\s+(.+)$', caseSensitive: false);
    final addressToPattern = RegExp(r'^(.+?)\s+to\s+(.+)$', caseSensitive: false); // "Address to Address" - capture to end
    final simpleToPattern = RegExp(r'to\s+(.+)$', caseSensitive: false); // Capture everything after "to"

    var match = fromToPattern.firstMatch(message);
    if (match != null) {
      originText = match.group(1)?.trim();
      destinationText = match.group(2)?.trim();
    } else {
      match = toFromPattern.firstMatch(message);
      if (match != null) {
        destinationText = match.group(1)?.trim();
        originText = match.group(2)?.trim();
      } else {
        // Try "Address to Address" pattern (e.g., "3105 S Normandie Avenue to 744 S Figueroa street")
        match = addressToPattern.firstMatch(message);
        if (match != null) {
          originText = match.group(1)?.trim();
          destinationText = match.group(2)?.trim();
        } else {
          match = simpleToPattern.firstMatch(message);
          if (match != null) {
            destinationText = match.group(1)?.trim();
            // Use current location as origin if available
            if (currentLocation != null) {
              originText = 'current location';
            }
          }
        }
      }
    }

    // If no pattern matched, try to find locations after keywords
    if (originText == null && destinationText == null) {
      final parts = message.split(RegExp(r'\s+(?:from|to|from|a|desde|hacia)\s+', caseSensitive: false));
      if (parts.length >= 2) {
        originText = parts[0].trim();
        destinationText = parts[1].trim();
      } else if (parts.length == 1 && currentLocation != null) {
        destinationText = parts[0].trim();
        originText = 'current location';
      }
    }

    // Geocode the locations
    LocationModel? origin;
    LocationModel? destination;

    if (originText != null && originText.isNotEmpty && originText.toLowerCase() != 'current location') {
      try {
        origin = await geocodeLocation(originText);
      } catch (e) {
        print('⚠️ Error geocoding origin: $e');
      }
    } else if (currentLocation != null) {
      origin = currentLocation;
    }

    if (destinationText != null && destinationText.isNotEmpty) {
      try {
        destination = await geocodeLocation(destinationText);
      } catch (e) {
        print('⚠️ Error geocoding destination: $e');
      }
    }

    return ExtractedLocation(
      originText: originText,
      destinationText: destinationText,
      origin: origin,
      destination: destination,
    );
  }

  /// Geocode a location string to LocationModel
  Future<LocationModel?> geocodeLocation(String locationText) async {
    if (locationText.trim().isEmpty) return null;
    
    final cleanText = locationText.trim();
    
    try {
      // First, try the address as-is
      List<Location> locations = [];
      try {
        locations = await locationFromAddress(cleanText);
        if (locations.isNotEmpty) {
          print('✅ Found location for "$cleanText"');
        }
      } catch (e) {
        print('⚠️ First geocoding attempt failed for "$cleanText": $e');
      }
      
      // If that fails and the address doesn't already contain city/state, try adding "Los Angeles, CA"
      if (locations.isEmpty && !cleanText.toLowerCase().contains('los angeles') && 
          !cleanText.toLowerCase().contains('la,') && !cleanText.toLowerCase().contains(', ca') &&
          !cleanText.toLowerCase().contains('california')) {
        try {
          final enhancedAddress = '$cleanText, Los Angeles, CA';
          print('🔄 Trying enhanced address: "$enhancedAddress"');
          locations = await locationFromAddress(enhancedAddress);
          if (locations.isNotEmpty) {
            print('✅ Found location with enhanced address');
          }
        } catch (e) {
          print('⚠️ Enhanced geocoding attempt failed: $e');
        }
      }
      
      // If still no results, try with just "Los Angeles" appended
      if (locations.isEmpty && !cleanText.toLowerCase().contains('los angeles')) {
        try {
          final enhancedAddress = '$cleanText, Los Angeles';
          print('🔄 Trying with Los Angeles: "$enhancedAddress"');
          locations = await locationFromAddress(enhancedAddress);
          if (locations.isNotEmpty) {
            print('✅ Found location with Los Angeles');
          }
        } catch (e) {
          print('⚠️ Los Angeles geocoding attempt failed: $e');
        }
      }
      
      // Try Google Places API autocomplete as fallback if geocoding package fails
      if (locations.isEmpty) {
        try {
          print('🔄 Trying Google Places API autocomplete for "$cleanText"');
          final placesService = PlacesService();
          // Use Places API autocomplete to find the place
          final suggestions = await placesService.autocompletePlaces(cleanText);
          if (suggestions.isNotEmpty) {
            // Get the first suggestion's place ID and fetch details
            final placeId = suggestions.first['placePrediction']?['placeId'] ?? 
                           suggestions.first['place_id'];
            if (placeId != null) {
              final placeDetails = await placesService.getPlaceWithSummary(placeId);
              if (placeDetails != null) {
                final location = placeDetails['location'];
                if (location != null) {
                  return LocationModel(
                    latitude: (location['latitude'] as num).toDouble(),
                    longitude: (location['longitude'] as num).toDouble(),
                    address: placeDetails['formattedAddress'] ?? cleanText,
                    name: placeDetails['displayName']?['text'] ?? cleanText,
                  );
                }
              }
            }
          }
        } catch (e) {
          print('⚠️ Google Places API fallback failed: $e');
        }
      }
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        // Get address from reverse geocoding
        final placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
        final address = placemarks.isNotEmpty
            ? '${placemarks.first.street ?? ''}, ${placemarks.first.locality ?? ''}, ${placemarks.first.administrativeArea ?? ''}'
                .replaceAll(RegExp(r',\s*,+'), ',')
                .replaceAll(RegExp(r'^,\s*'), '')
                .replaceAll(RegExp(r'\s*,$'), '')
                .trim()
            : null;

        return LocationModel(
          latitude: location.latitude,
          longitude: location.longitude,
          address: address ?? cleanText,
          name: cleanText,
        );
      } else {
        print('⚠️ No locations found for "$cleanText" after all attempts');
      }
    } catch (e) {
      print('⚠️ Geocoding error for "$cleanText": $e');
    }
    return null;
  }

  /// Check if message is asking for nearby amenities
  bool isAmenityRequest(String message, {String language = 'en'}) {
    final lowerMessage = message.toLowerCase();
    
    // Generic keywords that indicate user wants to find places
    final amenityKeywords = language == 'es'
        ? ['buscar', 'encuentra', 'muéstrame', 'dónde', 'cerca', 'cercanos', 'cercano', 'lugares', 'sitios', 'mostrar']
        : ['find', 'search', 'show', 'where', 'nearby', 'near', 'close', 'places', 'locations', 'list'];

    // Also check for specific categories
    final categoryKeywords = language == 'es'
        ? ['restaurantes', 'restaurante', 'comida', 'eventos', 'estacionamiento', 'gasolina', 'gas', 'farmacia', 'hospital', 'banco', 'café', 'tienda', 'supermercado']
        : ['restaurant', 'restaurants', 'food', 'events', 'parking', 'gas', 'pharmacy', 'hospital', 'bank', 'cafe', 'store', 'supermarket', 'shopping'];

    return amenityKeywords.any((keyword) => lowerMessage.contains(keyword)) ||
           categoryKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  /// Get category from message - returns Google Places API type
  String? getAmenityCategory(String message, {String language = 'en'}) {
    final lowerMessage = message.toLowerCase();
    
    final categories = {
      'restaurant': language == 'es' 
          ? ['restaurante', 'restaurantes', 'comida', 'comer', 'cena', 'almuerzo']
          : ['restaurant', 'restaurants', 'food', 'eat', 'dining', 'lunch', 'dinner'],
      'cafe': language == 'es'
          ? ['café', 'cafe', 'cafetería']
          : ['cafe', 'coffee', 'coffee shop'],
      'event': language == 'es'
          ? ['evento', 'eventos', 'concierto', 'show', 'espectáculo']
          : ['event', 'events', 'concert', 'show'],
      'parking': language == 'es'
          ? ['estacionamiento', 'parking', 'aparcamiento']
          : ['parking', 'park'],
      'gas_station': language == 'es'
          ? ['gasolina', 'gas', 'gasolinera', 'combustible']
          : ['gas', 'gas station', 'fuel'],
      'pharmacy': language == 'es'
          ? ['farmacia', 'farmacias']
          : ['pharmacy', 'drugstore'],
      'hospital': language == 'es'
          ? ['hospital', 'hospitales', 'clínica']
          : ['hospital', 'clinic'],
      'bank': language == 'es'
          ? ['banco', 'bancos', 'cajero']
          : ['bank', 'atm'],
      'supermarket': language == 'es'
          ? ['supermercado', 'tienda', 'grocery']
          : ['supermarket', 'grocery', 'store', 'shopping'],
    };

    for (final entry in categories.entries) {
      if (entry.value.any((keyword) => lowerMessage.contains(keyword))) {
        return entry.key;
      }
    }

    return null; // Generic search if no specific category
  }

  /// Fetch nearby amenities
  Future<List<LocationModel>> fetchNearbyAmenities({
    required LocationModel currentLocation,
    String? category,
    int radiusMeters = 2000,
  }) async {
    try {
      List<String>? types;
      
      if (category == 'restaurant') {
        types = ['restaurant', 'cafe', 'meal_takeaway'];
      } else if (category == 'event') {
        // Events are handled separately via EventsService
        return [];
      } else if (category == 'parking') {
        types = ['parking'];
      } else if (category == 'gas_station') {
        types = ['gas_station'];
      }

      final landmarks = await _placesService.searchNearbyLandmarks(
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude,
        radius: radiusMeters,
        includedTypes: types,
      );

      // Convert landmarks to LocationModel
      return landmarks.map((landmark) => landmark.location).toList();
    } catch (e) {
      print('⚠️ Error fetching nearby amenities: $e');
      return [];
    }
  }
}

