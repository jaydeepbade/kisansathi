import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dio/dio.dart';
import 'dart:io';

class ElevenLabsService {
  final FlutterTts _fallbackTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Dio _dio = Dio();
  
  // Set your ElevenLabs API Key here or load from .env
  final String _apiKey = ''; 
  final String _voiceId = 'pNInz6obbf5AWCGq2vj8'; // Example ID (Rachel)

  ElevenLabsService() {
    _initFallbackTts();
  }

  Future<void> _initFallbackTts() async {
    await _fallbackTts.setSpeechRate(0.5);
    await _fallbackTts.setVolume(1.0);
    await _fallbackTts.setPitch(1.0);
    await _fallbackTts.awaitSpeakCompletion(true);
  }

  Future<void> speak(String text, String languageCode) async {
    if (_apiKey.isEmpty) {
      // Fallback to local TTS if no API key is provided
      await _fallbackTts.setLanguage(languageCode);
      await _fallbackTts.speak(text);
      return;
    }

    try {
      final response = await _dio.post(
        'https://api.elevenlabs.io/v1/text-to-speech/$_voiceId/stream',
        options: Options(
          headers: {
            'xi-api-key': _apiKey,
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.bytes,
        ),
        data: {
          'text': text,
          'model_id': 'eleven_multilingual_v2', // Supports EN, HI
          'voice_settings': {
            'stability': 0.5,
            'similarity_boost': 0.75,
          }
        },
      );

      // Save bytes to temp file and play
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/elevenlabs_tts.mp3');
      await file.writeAsBytes(response.data);

      await _audioPlayer.setFilePath(file.path);
      await _audioPlayer.play();
      // Wait for playback to finish
      await _audioPlayer.playerStateStream.firstWhere(
        (state) => state.processingState == ProcessingState.completed,
      );
    } catch (e) {
      print('ElevenLabs API Error: $e');
      // Fallback if network fails
      await _fallbackTts.setLanguage(languageCode);
      await _fallbackTts.speak(text);
    }
  }

  Future<void> stopSpeaking() async {
    await _audioPlayer.stop();
    await _fallbackTts.stop();
  }
}
