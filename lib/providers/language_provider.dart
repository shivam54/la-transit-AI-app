import 'package:flutter/material.dart';

/// Language Provider for English/Spanish Support
class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'en'; // 'en' or 'es'
  
  String get currentLanguage => _currentLanguage;
  bool get isEnglish => _currentLanguage == 'en';
  bool get isSpanish => _currentLanguage == 'es';

  void setLanguage(String language) {
    if (language == 'en' || language == 'es') {
      _currentLanguage = language;
      notifyListeners();
    }
  }

  void toggleLanguage() {
    _currentLanguage = _currentLanguage == 'en' ? 'es' : 'en';
    notifyListeners();
  }

  // Language Packs (same as web app)
  static const Map<String, Map<String, String>> _languagePacks = {
    'en': {
      'app_title': 'Amigo AI',
      'search_origin': 'From',
      'search_destination': 'To',
      'search_button': 'Search Route',
      'driving_mode': 'Driving',
      'transit_mode': 'Public Transit',
      'walking_mode': 'Walking',
      'biking_mode': 'Biking',
      'landmarks': 'Landmarks',
      'select_type': 'Select type...',
      'no_amenities': 'No amenities selected',
      'accessible': 'Accessible',
      'navigate': 'Navigate',
      'voice_assistant': 'Voice Assistant',
      'listening': 'Listening...',
      'speak_now': 'Speak now...',
    },
    'es': {
      'app_title': 'Amigo AI',
      'search_origin': 'Desde',
      'search_destination': 'Hasta',
      'search_button': 'Buscar Ruta',
      'driving_mode': 'Conduciendo',
      'transit_mode': 'Tránsito Público',
      'walking_mode': 'Caminando',
      'biking_mode': 'En Bicicleta',
      'landmarks': 'Puntos de Interés',
      'select_type': 'Seleccionar tipo...',
      'no_amenities': 'No hay servicios seleccionados',
      'accessible': 'Accesible',
      'navigate': 'Navegar',
      'voice_assistant': 'Asistente de Voz',
      'listening': 'Escuchando...',
      'speak_now': 'Habla ahora...',
    },
  };

  String translate(String key) {
    return _languagePacks[_currentLanguage]?[key] ?? key;
  }

  // Voice recognition language
  String get speechRecognitionLanguage {
    return _currentLanguage == 'es' ? 'es-ES' : 'en-US';
  }

  // Text-to-speech language
  String get textToSpeechLanguage {
    return _currentLanguage == 'es' ? 'es-ES' : 'en-US';
  }
}

