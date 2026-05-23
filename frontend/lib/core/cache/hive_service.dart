import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';

class HiveService {
  static const String settingsBoxName = 'settings_box';
  static const String dashboardBoxName = 'dashboard_box';
  static const String marketplaceBoxName = 'marketplace_box';

  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      
      // Open all required boxes for offline-first caching
      await Hive.openBox(settingsBoxName);
      await Hive.openBox(dashboardBoxName);
      await Hive.openBox(marketplaceBoxName);
      
      debugPrint('📦 Hive Offline Caches initialized successfully.');
    } catch (e) {
      debugPrint('🚨 Hive initialization failed: $e');
    }
  }

  // --- Settings Box Helpers ---
  static void saveString(String key, String value) {
    Hive.box(settingsBoxName).put(key, value);
  }

  static String? getString(String key) {
    return Hive.box(settingsBoxName).get(key) as String?;
  }

  static void saveBool(String key, bool value) {
    Hive.box(settingsBoxName).put(key, value);
  }

  static bool getBool(String key, {bool defaultValue = false}) {
    return Hive.box(settingsBoxName).get(key, defaultValue: defaultValue) as bool;
  }

  // --- Dashboard Cache Helpers ---
  static void cacheDashboardData(String key, Map<String, dynamic> data) {
    Hive.box(dashboardBoxName).put(key, data);
  }

  static Map<dynamic, dynamic>? getCachedDashboardData(String key) {
    final data = Hive.box(dashboardBoxName).get(key);
    if (data is Map) return data;
    return null;
  }

  // --- Marketplace Cache Helpers ---
  static void cacheMarketplaceListings(List<Map<String, dynamic>> listings) {
    Hive.box(marketplaceBoxName).put('listings', listings);
  }

  static List<dynamic>? getCachedMarketplaceListings() {
    return Hive.box(marketplaceBoxName).get('listings') as List<dynamic>?;
  }

  // Clear all caches on logout
  static Future<void> clearAll() async {
    await Hive.box(settingsBoxName).clear();
    await Hive.box(dashboardBoxName).clear();
    await Hive.box(marketplaceBoxName).clear();
  }
}
