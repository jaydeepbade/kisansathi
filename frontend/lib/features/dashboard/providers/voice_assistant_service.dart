import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../../core/api/elevenlabs_service.dart';

enum VoiceAssistantState { idle, listening, processing, speaking, error }

class VoiceAssistantStateData {
  final VoiceAssistantState state;
  final String currentTranscript;
  final String aiResponse;
  final String selectedLanguage;
  final String? errorMessage;

  VoiceAssistantStateData({
    this.state = VoiceAssistantState.idle,
    this.currentTranscript = '',
    this.aiResponse = '',
    this.selectedLanguage = 'en-US',
    this.errorMessage,
  });

  VoiceAssistantStateData copyWith({
    VoiceAssistantState? state,
    String? currentTranscript,
    String? aiResponse,
    String? selectedLanguage,
    String? errorMessage,
  }) {
    return VoiceAssistantStateData(
      state: state ?? this.state,
      currentTranscript: currentTranscript ?? this.currentTranscript,
      aiResponse: aiResponse ?? this.aiResponse,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class VoiceAssistantNotifier extends Notifier<VoiceAssistantStateData> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ElevenLabsService _ttsService = ElevenLabsService();
  Timer? _pauseTimer;

  @override
  VoiceAssistantStateData build() {
    _initSpeech();
    
    ref.onDispose(() {
      _pauseTimer?.cancel();
      _speech.stop();
      _ttsService.stopSpeaking();
    });

    return VoiceAssistantStateData();
  }

  Future<void> _initSpeech() async {
    try {
      await _speech.initialize();
    } catch (e) {
      state = state.copyWith(
          state: VoiceAssistantState.error, errorMessage: "Speech init failed.");
    }
  }

  void setLanguage(String langCode) {
    state = state.copyWith(selectedLanguage: langCode);
  }

  Future<void> greetAndListen() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      state = state.copyWith(
          state: VoiceAssistantState.error,
          errorMessage: 'Microphone permission denied.');
      return;
    }

    if (!_speech.isAvailable) {
      await _initSpeech();
    }

    // Set speaking state for the initial greeting
    state = state.copyWith(
      state: VoiceAssistantState.speaking,
      aiResponse: 'What can I help you with, sir?',
      currentTranscript: '',
      errorMessage: null,
    );

    // Play greeting
    await _ttsService.speak('What can I help you with, sir?', state.selectedLanguage);

    // After greeting, clear response and start listening
    state = state.copyWith(aiResponse: '');
    await startListening();
  }

  Future<void> startListening() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      state = state.copyWith(
          state: VoiceAssistantState.error,
          errorMessage: 'Microphone permission denied.');
      return;
    }

    if (!_speech.isAvailable) {
      await _initSpeech();
    }

    state = state.copyWith(
      state: VoiceAssistantState.listening,
      currentTranscript: '',
      aiResponse: '',
      errorMessage: null,
    );

    _ttsService.stopSpeaking();

    await _speech.listen(
      onResult: (result) {
        state = state.copyWith(currentTranscript: result.recognizedWords);
        
        // Smart pause detection
        _pauseTimer?.cancel();
        _pauseTimer = Timer(const Duration(seconds: 2), () {
          if (state.state == VoiceAssistantState.listening) {
            _stopAndProcess();
          }
        });
      },
      localeId: state.selectedLanguage,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
    );
  }

  Future<void> _stopAndProcess() async {
    await _speech.stop();
    _pauseTimer?.cancel();

    if (state.currentTranscript.trim().isEmpty) {
      state = state.copyWith(state: VoiceAssistantState.idle);
      return;
    }

    state = state.copyWith(state: VoiceAssistantState.processing);
    
    // Simulate API delay for processing
    await Future.delayed(const Duration(milliseconds: 800));

    // Mock response generation based on transcript
    String responseText = _generateMockResponse(state.currentTranscript, state.selectedLanguage);
    
    state = state.copyWith(state: VoiceAssistantState.speaking);
    
    // Stream text UI
    _streamText(responseText);

    // Stream TTS Audio
    await _ttsService.speak(responseText, state.selectedLanguage);
    
    // Once speaking is done (simplified, we wait for text stream then small delay)
    // We assume TTS takes some time. Since it's a mock stream, we just wait.
  }

  void _streamText(String text) async {
    List<String> words = text.split(' ');
    String currentResponse = '';
    
    for (String word in words) {
      if (state.state != VoiceAssistantState.speaking) break; // Interrupted
      currentResponse += '$word ';
      state = state.copyWith(aiResponse: currentResponse);
      await Future.delayed(const Duration(milliseconds: 300)); // typing speed
    }
    
    await Future.delayed(const Duration(seconds: 1));
    if (state.state == VoiceAssistantState.speaking) {
      state = state.copyWith(state: VoiceAssistantState.idle);
    }
  }

  Future<void> stopListeningAndSpeaking() async {
    _pauseTimer?.cancel();
    if (_speech.isListening) await _speech.stop();
    await _ttsService.stopSpeaking();
    state = state.copyWith(state: VoiceAssistantState.idle);
  }

  String _generateMockResponse(String query, String langCode) {
    query = query.toLowerCase();
    if (langCode == 'hi-IN') {
      if (query.contains('weather') || query.contains('मौसम')) {
        return "आज भारी बारिश की संभावना है। कृपया अपनी फसलों को सुरक्षित रखें।";
      }
      return "मैं आपकी बात सुन रहा हूँ। मैं एक AI कृषि सहायक हूँ, आपकी कैसे मदद कर सकता हूँ?";
    } else if (langCode == 'mr-IN') {
      if (query.contains('weather') || query.contains('हवामान')) {
        return "आज जोरदार पावसाची शक्यता आहे. कृपया तुमच्या पिकांची काळजी घ्या.";
      }
      return "मी ऐकत आहे. मी कृषी सहाय्यक आहे, मी तुम्हाला कशी मदत करू शकतो?";
    } else {
      if (query.contains('weather') || query.contains('rain')) {
        return "There is a high chance of heavy rain today. Please ensure your crops are protected and irrigation is paused.";
      } else if (query.contains('price') || query.contains('market')) {
        return "The current market price for wheat has increased by 5% in the Pune market.";
      }
      return "I heard you say: '$query'. As your KrishiNova AI assistant, I'm here to help you optimize your farming.";
    }
  }

}

final voiceAssistantProvider =
    NotifierProvider<VoiceAssistantNotifier, VoiceAssistantStateData>(() {
  return VoiceAssistantNotifier();
});
