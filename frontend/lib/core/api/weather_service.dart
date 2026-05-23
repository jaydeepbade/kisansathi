import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Models ───────────────────────────────────────────────────────────────────
class WeatherData {
  final double temperature;
  final double humidity;
  final double rainfall; // mm precipitation (3h block from OWM)
  final String description;
  final String cityName;

  const WeatherData({
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    required this.description,
    required this.cityName,
  });

  String get rainfallLabel {
    if (rainfall == 0) return 'No rain';
    if (rainfall < 5) return 'Light rain';
    if (rainfall < 20) return 'Moderate rain';
    return 'Heavy rain';
  }

  String toContextString() =>
      'Location: $cityName | Temp: ${temperature.toStringAsFixed(1)}°C | '
      'Humidity: ${humidity.toStringAsFixed(0)}% | Rainfall: $rainfallLabel';
}

// ─── Provider ─────────────────────────────────────────────────────────────────
final weatherServiceProvider = Provider<WeatherService>((ref) => WeatherService());

// ─── Service ──────────────────────────────────────────────────────────────────
class WeatherService {
  // ⚠️  Replace with your actual OpenWeatherMap API key (free tier works)
  static const String _apiKey = 'YOUR_OPENWEATHER_API_KEY';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  late final Dio _dio;

  WeatherService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  Future<WeatherData?> fetchWeather(String city) async {
    try {
      final response = await _dio.get('/weather', queryParameters: {
        'q': city,
        'appid': _apiKey,
        'units': 'metric',
      });

      final data = response.data;
      return WeatherData(
        temperature: (data['main']['temp'] as num).toDouble(),
        humidity: (data['main']['humidity'] as num).toDouble(),
        rainfall: data['rain'] != null
            ? ((data['rain']['1h'] ?? data['rain']['3h'] ?? 0) as num).toDouble()
            : 0.0,
        description: data['weather'][0]['description'] as String,
        cityName: data['name'] as String,
      );
    } catch (_) {
      // Return a sensible default so the chat still works offline
      return const WeatherData(
        temperature: 30.0,
        humidity: 65.0,
        rainfall: 0.0,
        description: 'Data unavailable',
        cityName: 'Unknown',
      );
    }
  }
}
