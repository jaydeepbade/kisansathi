import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Provider ────────────────────────────────────────────────────────────────
final openAIServiceProvider = Provider<OpenAIService>((ref) => OpenAIService());

// ─── Service ─────────────────────────────────────────────────────────────────
class OpenAIService {
  // ⚠️  Replace with your actual OpenAI API key
  static const String _apiKey = 'YOUR_OPENAI_API_KEY';
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4.1-mini';

  late final Dio _dio;

  OpenAIService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.openai.com',
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      receiveTimeout: const Duration(seconds: 30),
      connectTimeout: const Duration(seconds: 15),
    ));
  }

  /// System prompt — agriculture expert persona
  static String _buildSystemPrompt({
    String? location,
    String? rainfall,
    String? temperature,
    String? humidity,
    String? marketTrend,
    String language = 'English',
  }) {
    final contextBlock = StringBuffer();
    contextBlock.writeln('You are FarmSaathi AI — an expert agricultural advisor for Indian farmers.');
    contextBlock.writeln('You give practical, actionable, and region-specific crop advice.');
    contextBlock.writeln('Always include: best crop suggestions, expected yield, fertilizer tips, pest warnings, and market prices when relevant.');
    contextBlock.writeln('Reply in $language language. Keep answers concise but rich in detail.');
    contextBlock.writeln('Use emojis sparingly to highlight key points. Format important data as bullet lists.');

    if (location != null || temperature != null || rainfall != null) {
      contextBlock.writeln('\n--- REAL-TIME FARM CONTEXT ---');
      if (location != null) contextBlock.writeln('📍 Location: $location');
      if (temperature != null) contextBlock.writeln('🌡️ Temperature: $temperature');
      if (rainfall != null) contextBlock.writeln('🌧️ Rainfall: $rainfall');
      if (humidity != null) contextBlock.writeln('💧 Humidity: $humidity');
      if (marketTrend != null) contextBlock.writeln('📈 Market Trend: $marketTrend');
      contextBlock.writeln('---');
    }

    return contextBlock.toString();
  }

  /// Send a conversation to GPT and get a streaming response
  Future<String> sendMessage({
    required List<Map<String, String>> messages,
    String language = 'English',
    String? location,
    String? temperature,
    String? rainfall,
    String? humidity,
    String? marketTrend,
  }) async {
    final systemPrompt = _buildSystemPrompt(
      location: location,
      temperature: temperature,
      rainfall: rainfall,
      humidity: humidity,
      marketTrend: marketTrend,
      language: language,
    );

    final payload = {
      'model': _model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        ...messages,
      ],
      'temperature': 0.7,
      'max_tokens': 800,
    };

    try {
      final response = await _dio.post('/v1/chat/completions', data: payload);
      final content = response.data['choices'][0]['message']['content'] as String;
      return content.trim();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return '⚠️ API key is invalid. Please set a valid OpenAI API key in openai_service.dart.';
      }
      return '⚠️ Could not reach AI. Please check your internet connection and try again.\n\nError: ${e.message}';
    } catch (e) {
      return '⚠️ Unexpected error: $e';
    }
  }
}
