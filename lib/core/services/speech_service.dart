import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  
  // Track active callbacks for the current session
  Function(String error)? activeErrorCallback;
  VoidCallback? activeStatusCallback;

  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onError: (val) {
          debugPrint('SpeechToText onError: $val');
          activeErrorCallback?.call(val.errorMsg);
        },
        onStatus: (val) {
          debugPrint('SpeechToText onStatus: $val');
          if (val == 'notListening' || val == 'done') {
            activeStatusCallback?.call();
          }
        },
      );
    } catch (e) {
      debugPrint('SpeechToText init exception: $e');
      _isInitialized = false;
    }
    return _isInitialized;
  }

  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
    required Function(double decibels) onSoundLevel,
    VoidCallback? onListeningStopped,
    Function(String error)? onError,
    String localeId = 'ml_IN',
  }) async {
    activeErrorCallback = onError;
    activeStatusCallback = onListeningStopped;

    final hasPermission = await initialize();
    if (!hasPermission) {
      debugPrint('Speech recognition not initialized - permission might be denied.');
      onError?.call('Microphone permission denied or speech recognition unavailable.');
      return;
    }

    // Chrome/Web Speech API uses BCP 47 hyphenated tags (e.g., 'ml-IN' instead of 'ml_IN')
    final formattedLocale = kIsWeb ? localeId.replaceAll('_', '-') : localeId;

    try {
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords, result.finalResult);
        },
        onSoundLevelChange: onSoundLevel,
        localeId: formattedLocale,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
      );
    } catch (e) {
      debugPrint('Error starting speech listening: $e');
      onError?.call(e.toString());
    }
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (e) {
      debugPrint('Error stopping speech: $e');
    }
  }

  Future<void> cancelListening() async {
    try {
      await _speech.cancel();
    } catch (e) {
      debugPrint('Error cancelling speech: $e');
    }
  }
}
