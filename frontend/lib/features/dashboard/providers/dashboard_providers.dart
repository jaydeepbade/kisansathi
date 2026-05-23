import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/mock_endpoints.dart';
import '../../../core/cache/hive_service.dart';

// Model to hold weather status with offline flag
class WeatherState {
  final WeatherData? data;
  final bool isFromCache;
  final String? errorMessage;

  WeatherState({this.data, this.isFromCache = false, this.errorMessage});
}

class WeatherNotifier extends Notifier<AsyncValue<WeatherState>> {
  @override
  AsyncValue<WeatherState> build() {
    // Proactively fetch weather on initialization
    Future.microtask(() => fetchWeather());
    return const AsyncLoading();
  }

  Future<void> fetchWeather() async {
    state = const AsyncLoading();
    try {
      // Simulate real network fetch
      final freshWeather = await MockEndpoints.fetchWeather();
      
      // Save successfully to offline Hive cache
      HiveService.cacheDashboardData('cached_weather', freshWeather.toJson());
      
      state = AsyncData(WeatherState(data: freshWeather, isFromCache: false));
    } catch (e) {
      // Offline fallback: Check Hive cache
      final cachedJson = HiveService.getCachedDashboardData('cached_weather');
      if (cachedJson != null) {
        final cachedWeather = WeatherData.fromJson(cachedJson);
        state = AsyncData(WeatherState(
          data: cachedWeather, 
          isFromCache: true,
          errorMessage: "Offline: Loaded from cache (ऑफलाइन: कैशे से लोड किया गया)"
        ));
      } else {
        state = AsyncError("Failed to fetch weather. Please try again.", StackTrace.current);
      }
    }
  }
}

// Global weather future/cache provider
final weatherStateProvider = NotifierProvider<WeatherNotifier, AsyncValue<WeatherState>>(() {
  return WeatherNotifier();
});

// Alerts Riverpod stream provider (simulating a Supabase Realtime channel)
final alertsStreamProvider = StreamProvider<List<String>>((ref) async* {
  final List<String> currentAlerts = [
    'Late Blight Risk: Potato growers in Pune advisory active. (झुलसा रोग का खतरा)',
    'Tomato Prices Spike: 25% price increase in Indore Mandi. (टमाटर के दाम में उछाल)',
    'Heavy Rain Advisory: Shield your harvested grains. (भारी बारिश की चेतावनी)',
  ];

  yield currentAlerts;

  // Simulate receiving a realtime notification alert after 15 seconds
  await Future.delayed(const Duration(seconds: 15));
  currentAlerts.insert(0, '⚠️ Mandi Alert: Wheat prices hit record ₹2,850/quintal in Pune! (नया मंडी भाव)');
  yield List.from(currentAlerts);
});
