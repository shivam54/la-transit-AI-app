import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/language_provider.dart';
import '../utils/constants.dart';

/// Voice Service - Speech Recognition and Text-to-Speech
class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  
  bool _isListening = false;
  bool _isInitialized = false;
  String? _lastResult;
  bool _shouldAutoRestart = false; // Control whether to auto-restart on timeout
  DateTime? _lastRestartTime; // Track last restart to prevent rapid restarts
  String? _lastPartialResult; // Track last partial result
  DateTime? _lastPartialResultTime; // Track when we last got a partial result
  Timer? _partialResultTimer; // Timer to process partial results after pause
  
  // Callbacks for current listening session
  Function(String result)? _currentOnResult;
  Function(String error)? _currentOnError;
  Function(String status)? _currentOnStatus;
  LanguageProvider? _currentLanguageProvider;

  bool get isListening => _isListening;
  String? get lastResult => _lastResult;

  /// Initialize voice services
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Check microphone permission first
      final hasPermission = await _checkMicrophonePermission();
      if (!hasPermission) {
        print('❌ Microphone permission not granted');
        return false;
      }

      // Initialize speech recognition with error/status handlers
      final available = await _speech.initialize(
        onError: (error) {
          print('❌ Speech recognition error: ${error.errorMsg}, permanent: ${error.permanent}');
          
          // Handle busy errors - wait longer before retrying
          if (error.errorMsg == 'error_busy') {
            print('⚠️ Speech service busy - waiting before retry...');
            _isListening = false;
            // Wait longer for busy errors
            Future.delayed(const Duration(seconds: 2), () {
              if (!_isListening && _shouldAutoRestart && _currentOnResult != null && _currentLanguageProvider != null) {
                _restartListening();
              }
            });
            return;
          }
          
          // Handle timeout errors - these are normal, but only restart if auto-restart is enabled
          if (error.errorMsg == 'error_speech_timeout' && !error.permanent && _isListening && _shouldAutoRestart) {
            print('ℹ️ Speech timeout - will restart if auto-restart enabled');
            _isListening = false;
            // Restart after a delay, but check debounce
            _restartListeningWithDebounce();
          } else if (error.errorMsg != 'error_speech_timeout' && error.errorMsg != 'error_busy') {
            // Other errors - report to caller
            _isListening = false;
            _currentOnError?.call('Speech recognition error: ${error.errorMsg}');
          }
        },
        onStatus: (status) {
          print('📡 Speech recognition status: $status');
          _currentOnStatus?.call(status);
          
          // Update listening state
          if (status == 'listening') {
            _isListening = true;
          } else if ((status == 'done' || status == 'notListening') && _isListening && _shouldAutoRestart) {
            // If done and we should still be listening, restart (with debounce)
            _isListening = false;
            _restartListeningWithDebounce();
          }
        },
      );

      if (!available) {
        print('❌ Speech recognition not available');
        return false;
      }

      // Initialize TTS with male voice
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.75); // Faster speech rate (0.75 = 75% faster than normal)
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      
      // Set completion handler to resume listening after TTS finishes
      // NOTE: Auto-restart is now disabled - user must manually click "Start Voice" button
      // This gives user time to process information and prevents conflicts
      _tts.setCompletionHandler(() {
        print('🔊 TTS finished speaking');
        // Don't auto-restart - user must click "Start Voice" button manually
        // This prevents conflicts and gives user control
      });
      
      // Try to set a male voice (optional - don't break TTS if this fails)
      try {
        final voices = await _tts.getVoices;
        if (voices != null && voices.isNotEmpty) {
          // Look for a male voice (common patterns: "male", "m", or specific male voice names)
          dynamic maleVoice;
          try {
            maleVoice = voices.firstWhere(
              (voice) {
                final name = (voice['name'] ?? '').toString().toLowerCase();
                final locale = (voice['locale'] ?? '').toString().toLowerCase();
                // Check for male indicators in voice name or locale
                return name.contains('male') || 
                       name.contains('m-') || 
                       locale.contains('male') ||
                       // Android male voices often have specific patterns
                       name.contains('en-us-x-sfg#male') ||
                       // iOS male voices
                       name.contains('daniel') ||
                       name.contains('alex');
              },
            );
          } catch (_) {
            // No male voice found, skip voice setting - use default
            print('ℹ️ No male voice found, using default voice');
            // Continue - TTS will use default voice
          }
          
          if (maleVoice != null) {
            final voiceName = maleVoice['name'];
            final voiceLocale = maleVoice['locale'];
            if (voiceName != null) {
              await _tts.setVoice({'name': voiceName, 'locale': voiceLocale});
              print('✅ Set TTS voice to: $voiceName');
            }
          }
        }
      } catch (e) {
        // If voice selection fails, continue with default voice - don't break TTS
        print('⚠️ Could not set male voice, using default: $e');
        // Don't throw - TTS will still work with default voice
      }

      _isInitialized = true;
      print('✅ Voice services initialized successfully');
      return true;
    } catch (e) {
      print('❌ Error initializing voice services: $e');
      return false;
    }
  }

  /// Check and request microphone permission
  Future<bool> _checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      print('Microphone permission permanently denied. Please enable in settings.');
      return false;
    }
    
    return false;
  }

  /// Restart listening with debounce to prevent rapid restarts
  void _restartListeningWithDebounce() {
    final now = DateTime.now();
    // Prevent restart if last restart was less than 2 seconds ago
    if (_lastRestartTime != null && now.difference(_lastRestartTime!).inSeconds < 2) {
      print('⏸️ Skipping restart - too soon after last restart');
      return;
    }
    _lastRestartTime = now;
    _restartListening();
  }
  
  /// Restart listening
  void _restartListening() {
    if (!_isListening && _shouldAutoRestart && _currentOnResult != null && _currentLanguageProvider != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isListening && _shouldAutoRestart && _currentOnResult != null && _currentLanguageProvider != null) {
          print('🔄 Restarting listening...');
          startListening(
            onResult: _currentOnResult!,
            languageProvider: _currentLanguageProvider!,
            onError: _currentOnError,
            onStatus: _currentOnStatus,
            autoRestart: true, // Keep auto-restart enabled
          );
        }
      });
    }
  }

  /// Start listening for voice input
  Future<void> startListening({
    required Function(String result) onResult,
    required LanguageProvider languageProvider,
    Function(String error)? onError,
    Function(String status)? onStatus,
    bool autoRestart = false, // Whether to auto-restart on timeout
  }) async {
    // Check microphone permission first
    final hasPermission = await _checkMicrophonePermission();
    if (!hasPermission) {
      onError?.call('Microphone permission denied. Please grant microphone access in app settings.');
      return;
    }

    // Store callbacks for this session FIRST (used in error/status handlers)
    _currentOnResult = onResult;
    _currentOnError = onError;
    _currentOnStatus = onStatus;
    _currentLanguageProvider = languageProvider;
    _shouldAutoRestart = autoRestart; // Set auto-restart flag

    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError?.call('Voice services not available');
        return;
      }
    }

    if (_isListening) {
      await stopListening();
      // Wait longer for previous session to fully stop and clean up
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // Double-check we're not still listening
    if (_speech.isListening) {
      print('⚠️ Speech recognition still active, canceling...');
      try {
        await _speech.cancel();
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        print('Error canceling speech recognition: $e');
      }
    }

    try {
      
      _isListening = true;
      final lang = languageProvider.speechRecognitionLanguage;
      
      onStatus?.call('Starting to listen...');

      await _speech.listen(
        onResult: (result) {
          print('🎤 Speech result: "${result.recognizedWords}", final: ${result.finalResult}');
          
          // Show partial results for feedback
          if (!result.finalResult && result.recognizedWords.isNotEmpty) {
            onStatus?.call('Heard: ${result.recognizedWords}');
            
            // Track partial results - if we get a good partial result and it hasn't changed for 2 seconds, process it
            if (result.recognizedWords.length >= 3) { // Only process if we have at least 3 characters
              _lastPartialResult = result.recognizedWords;
              _lastPartialResultTime = DateTime.now();
              
              // Cancel previous timer
              _partialResultTimer?.cancel();
              
              // Set timer to process partial result after 2 seconds of no updates
              _partialResultTimer = Timer(const Duration(seconds: 2), () {
                if (_lastPartialResult != null && 
                    _lastPartialResultTime != null &&
                    DateTime.now().difference(_lastPartialResultTime!).inSeconds >= 2) {
                  print('⏱️ Processing partial result after pause: "${_lastPartialResult}"');
                  _isListening = false;
                  _lastResult = _lastPartialResult;
                  onResult(_lastPartialResult!);
                  _lastPartialResult = null;
                  _lastPartialResultTime = null;
                }
              });
            }
          }
          
          // Process final results
          if (result.finalResult) {
            _partialResultTimer?.cancel(); // Cancel partial result timer if we get final result
            _isListening = false;
            
            if (result.recognizedWords.isNotEmpty) {
              _lastResult = result.recognizedWords;
              print('✅ Final result: "${result.recognizedWords}"');
              onResult(result.recognizedWords);
            } else {
              print('⚠️ Final result empty - restarting listening if auto-restart enabled');
              // Restart listening for empty results (timeout) only if auto-restart is enabled
              if (_shouldAutoRestart) {
                _restartListeningWithDebounce();
              }
            }
          }
        },
        listenFor: const Duration(seconds: 60), // Increased from 30 to 60 seconds
        pauseFor: const Duration(seconds: 5), // Increased pause time to 5 seconds
        localeId: lang,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation, // Dictation mode for continuous listening
          cancelOnError: false, // Don't cancel on error - handle timeouts gracefully
          partialResults: true, // Get partial results for feedback
        ),
        onSoundLevelChange: (level) {
          // Visual feedback can use this
          // print('Sound level: $level');
        },
      );
      
      // Check status after starting
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_speech.isListening) {
          _isListening = true;
          onStatus?.call('Listening...');
          print('✅ Speech recognition is now listening');
        } else {
          print('⚠️ Speech recognition not listening after start');
          _isListening = false;
          // Try to restart
          Future.delayed(const Duration(seconds: 1), () {
            if (!_isListening) {
              print('🔄 Retrying to start listening...');
              startListening(
                onResult: onResult,
                languageProvider: languageProvider,
                onError: onError,
                onStatus: onStatus,
              );
            }
          });
        }
      });
      
      print('✅ Started listening for speech recognition');
    } catch (e) {
      _isListening = false;
      print('Error starting speech recognition: $e');
      onError?.call('Error starting speech recognition: $e');
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    _partialResultTimer?.cancel(); // Cancel any pending partial result processing
    _lastPartialResult = null;
    _lastPartialResultTime = null;
    
    if (_isListening) {
      try {
        await _speech.stop();
      } catch (e) {
        print('Error stopping speech recognition: $e');
      }
      _isListening = false;
    }
  }
  
  /// Check if speech recognition is actually listening
  bool get isActuallyListening {
    return _isListening && _speech.isListening;
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    if (_isListening) {
      await _speech.cancel();
      _isListening = false;
    }
  }

  /// Clean and simplify text for better TTS clarity
  String _cleanTextForTTS(String text) {
    // Remove HTML tags
    String cleaned = text.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Replace HTML entities
    cleaned = cleaned
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', 'and')
        .replaceAll('&lt;', '')
        .replaceAll('&gt;', '')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    
    // Simplify common navigation phrases for better TTS
    cleaned = cleaned
        .replaceAll(RegExp(r'\bHead\s+(north|south|east|west|northeast|northwest|southeast|southwest)\b', caseSensitive: false), 'Go')
        .replaceAll(RegExp(r'\bTurn\s+(left|right)\s+onto\b', caseSensitive: false), 'Turn')
        .replaceAll(RegExp(r'\bonto\b', caseSensitive: false), 'on')
        .replaceAll(RegExp(r'\bContinue\s+straight\b', caseSensitive: false), 'Continue straight ahead');
    
    // Handle distance units with replaceAllMapped (for function replacement)
    cleaned = cleaned.replaceAllMapped(RegExp(r'\b(\d+)\s*(ft|feet|m|meter|meters|mi|mile|miles)\b', caseSensitive: false), (match) {
      final num = match.group(1) ?? '';
      final unit = match.group(2)?.toLowerCase() ?? '';
      if (unit.contains('ft') || unit.contains('feet') || unit.contains('meter')) {
        return '$num $unit';
      } else if (unit.contains('mi') || unit.contains('mile')) {
        return '$num mile${num != '1' ? 's' : ''}';
      }
      return match.group(0) ?? '';
    });
    
    // Add small pauses for better clarity (only after periods, not commas)
    cleaned = cleaned.replaceAll('. ', '. ');
    
    // Remove extra spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return cleaned;
  }

  /// Speak text
  Future<void> speak(String text, {required LanguageProvider languageProvider}) async {
    if (text.isEmpty) {
      print('⚠️ Attempted to speak empty text');
      return;
    }
    
    // Clean text for better TTS clarity
    final cleanedText = _cleanTextForTTS(text);
    
    // Stop speech recognition while TTS is speaking to prevent interference
    bool wasListening = _isListening;
    if (_isListening) {
      print('🔇 Stopping speech recognition while TTS speaks');
      await stopListening();
    }
    
    try {
      // ALWAYS set English language for TTS (force English regardless of language provider)
      await _tts.setLanguage('en-US');
      print('🌐 Set TTS language to: en-US');
      
      // Ensure speech rate is set - apply every time to ensure it's not reset
      await _tts.setSpeechRate(0.75); // Faster speech rate (0.75 = 75% faster than normal)
      
      // Try to ensure male English voice is set (optional - don't break if this fails)
      try {
        final voices = await _tts.getVoices;
        if (voices != null && voices.isNotEmpty) {
          // Filter to only English voices first
          final englishVoices = voices.where((voice) {
            final locale = (voice['locale'] ?? '').toString().toLowerCase();
            return locale.startsWith('en-') || locale == 'en';
          }).toList();
          
          if (englishVoices.isNotEmpty) {
            dynamic maleVoice;
            try {
              // Look for male English voice
              maleVoice = englishVoices.firstWhere(
                (voice) {
                  final name = (voice['name'] ?? '').toString().toLowerCase();
                  final locale = (voice['locale'] ?? '').toString().toLowerCase();
                  // Must be English AND male
                  return (locale.startsWith('en-') || locale == 'en') &&
                         (name.contains('male') || 
                          name.contains('m-') || 
                          name.contains('en-us-x-sfg#male') ||
                          (name.contains('daniel') || name.contains('alex')));
                },
              );
            } catch (_) {
              // No male English voice found, use first English voice
              maleVoice = englishVoices.first;
              print('ℹ️ No male English voice found, using: ${maleVoice['name']}');
            }
            
            if (maleVoice != null) {
              final voiceName = maleVoice['name'];
              final voiceLocale = maleVoice['locale'];
              if (voiceName != null && voiceLocale != null) {
                await _tts.setVoice({'name': voiceName, 'locale': voiceLocale});
                print('✅ Set TTS voice to: $voiceName ($voiceLocale)');
              }
            }
          } else {
            print('⚠️ No English voices found, using default');
          }
        }
      } catch (e) {
        // Ignore voice setting errors - TTS will work with default voice
        print('⚠️ Voice setting error (non-critical): $e');
      }
      
      // Language is already set to en-US above, no need to verify
      
      // Speak the cleaned text
      await _tts.speak(cleanedText);
      print('🔊 Speaking: $cleanedText');
      
      // Note: Listening will resume automatically via completion handler if auto-restart is enabled
      // and wasListening was true
    } catch (e) {
      print('❌ Error speaking text: $e');
      
      // If there was an error and we were listening, try to resume
      if (wasListening && _shouldAutoRestart && _currentOnResult != null && _currentLanguageProvider != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_isListening && _shouldAutoRestart && _currentOnResult != null && _currentLanguageProvider != null) {
            startListening(
              onResult: _currentOnResult!,
              languageProvider: _currentLanguageProvider!,
              onError: _currentOnError,
              onStatus: _currentOnStatus,
              autoRestart: true,
            );
          }
        });
      }
      
      // Re-throw so caller knows TTS failed
      rethrow;
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  /// Parse voice command for category
  String? parseCategoryFromCommand(String command) {
    final lowerCommand = command.toLowerCase();
    
    for (final entry in AppConstants.voiceCategoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerCommand.contains(keyword)) {
          return entry.key;
        }
      }
    }
    
    return null;
  }

  /// Parse voice command for number (option selection)
  int? parseNumberFromCommand(String command) {
    final lowerCommand = command.toLowerCase();
    
    // Check for direct numbers
    final numberRegex = RegExp(r'\b(\d+)\b');
    final match = numberRegex.firstMatch(lowerCommand);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }

    // Check for number words
    final numberWords = {
      'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
      'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
      'first': 1, 'second': 2, 'third': 3, 'fourth': 4, 'fifth': 5,
      'uno': 1, 'dos': 2, 'tres': 3, 'cuatro': 4, 'cinco': 5,
      'seis': 6, 'siete': 7, 'ocho': 8, 'nueve': 9, 'diez': 10,
    };

    for (final entry in numberWords.entries) {
      if (lowerCommand.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Parse radius from command (e.g., "within 2 miles")
  int? parseRadiusFromCommand(String command) {
    final lowerCommand = command.toLowerCase();
    
    // Look for "within X miles/km"
    final mileRegex = RegExp(r'within\s+(\d+)\s*(?:mile|mi)');
    final kmRegex = RegExp(r'within\s+(\d+)\s*(?:km|kilometer)');
    
    final mileMatch = mileRegex.firstMatch(lowerCommand);
    if (mileMatch != null) {
      final miles = int.tryParse(mileMatch.group(1) ?? '');
      return miles != null ? (miles * 1609.34).round() : null; // Convert to meters
    }
    
    final kmMatch = kmRegex.firstMatch(lowerCommand);
    if (kmMatch != null) {
      final km = int.tryParse(kmMatch.group(1) ?? '');
      return km != null ? (km * 1000).round() : null; // Convert to meters
    }

    return null;
  }

  /// Check if command requests accessible locations
  bool parseAccessibleOnly(String command) {
    final lowerCommand = command.toLowerCase();
    final accessibleKeywords = [
      'accessible',
      'wheelchair',
      'handicap',
      'disability',
      'accesible', // Spanish typo variant
    ];
    
    return accessibleKeywords.any((keyword) => lowerCommand.contains(keyword));
  }
}

