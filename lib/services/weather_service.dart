import 'package:dio/dio.dart';
import '../utils/constants.dart';

/// Weather Service - Fetches current weather data
class WeatherService {
  final Dio _dio = Dio();
  final String _apiKey = AppConstants.openWeatherApiKey;
  final String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  /// Get current weather for a location
  Future<Map<String, dynamic>?> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    if (_apiKey.isEmpty || _apiKey.trim().isEmpty) {
      print('⚠️ OpenWeatherMap API key not set. Please add your API key in lib/utils/constants.dart');
      print('   Get a free API key from: https://openweathermap.org/api');
      return null;
    }

    try {
      final response = await _dio.get(
        '$_baseUrl/weather',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'appid': _apiKey,
          'units': 'imperial', // Fahrenheit
        },
        options: Options(
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Validate response structure
        if (data['weather'] == null || (data['weather'] as List).isEmpty) {
          print('⚠️ Weather API returned invalid data structure');
          return null;
        }
        
        if (data['main'] == null) {
          print('⚠️ Weather API returned missing main data');
          return null;
        }
        
        final weatherData = data['weather'][0];
        final mainData = data['main'];
        
        return {
          'condition': weatherData['main']?.toString().toLowerCase() ?? 'unknown',
          'description': weatherData['description']?.toString() ?? '',
          'temperature': (mainData['temp'] as num).round(),
          'feelsLike': (mainData['feels_like'] as num).round(),
          'humidity': mainData['humidity'] ?? 0,
          'windSpeed': (data['wind']?['speed'] as num?)?.round() ?? 0,
          'city': data['name']?.toString() ?? 'Unknown',
        };
      } else if (response.statusCode == 401) {
        print('❌ Weather API authentication failed. Check your API key.');
        print('   Response: ${response.data}');
        return null;
      } else {
        print('⚠️ Weather API error: ${response.statusCode}');
        print('   Response: ${response.data}');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching weather: $e');
      if (e is DioException) {
        print('   Status: ${e.response?.statusCode}');
        print('   Message: ${e.message}');
      }
      return null;
    }
  }
}

