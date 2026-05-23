import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/cache/hive_service.dart';

// Global Event Channel to trigger Listing Creation Form from other screens
final marketplaceShowFormEvent = ValueNotifier<bool>(false);

class CropListing {
  final String id;
  final String cropName;
  final String category; // 'Grains', 'Vegetables', 'Fruits'
  final double quantity; // in kg
  final double pricePerKg;
  final String location;
  final int distanceKm;
  final String freshness; // 'Freshly Harvested', '1 Day Old', etc.
  final String imagePath;
  final String harvestDate;

  CropListing({
    required this.id,
    required this.cropName,
    required this.category,
    required this.quantity,
    required this.pricePerKg,
    required this.location,
    required this.distanceKm,
    required this.freshness,
    required this.imagePath,
    required this.harvestDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'cropName': cropName,
        'category': category,
        'quantity': quantity,
        'pricePerKg': pricePerKg,
        'location': location,
        'distanceKm': distanceKm,
        'freshness': freshness,
        'imagePath': imagePath,
        'harvestDate': harvestDate,
      };

  factory CropListing.fromJson(Map<dynamic, dynamic> json) {
    return CropListing(
      id: json['id'] as String,
      cropName: json['cropName'] as String,
      category: json['category'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      pricePerKg: (json['pricePerKg'] as num).toDouble(),
      location: json['location'] as String,
      distanceKm: (json['distanceKm'] as num).toInt(),
      freshness: json['freshness'] as String,
      imagePath: json['imagePath'] as String,
      harvestDate: json['harvestDate'] as String,
    );
  }
}

// Global active cart item counts (Riverpod 3 Notifier standard)
class CartCountNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() {
    state = state + 1;
  }
}

final cartCountProvider = NotifierProvider<CartCountNotifier, int>(() {
  return CartCountNotifier();
});

// Category filter notifier
class CropFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setFilter(String filter) {
    state = filter;
  }
}

final cropFilterProvider = NotifierProvider<CropFilterNotifier, String>(() {
  return CropFilterNotifier();
});

// Distance filter notifier
class MaxDistanceFilterNotifier extends Notifier<double> {
  @override
  double build() => 100.0;

  void setDistance(double distance) {
    state = distance;
  }
}

final maxDistanceFilterProvider = NotifierProvider<MaxDistanceFilterNotifier, double>(() {
  return MaxDistanceFilterNotifier();
});

// Product listings notifier maintaining offline caches
class MarketplaceListingsNotifier extends Notifier<AsyncValue<List<CropListing>>> {
  @override
  AsyncValue<List<CropListing>> build() {
    Future.microtask(() => fetchListings());
    return const AsyncLoading();
  }

  Future<void> fetchListings() async {
    state = const AsyncLoading();
    try {
      // Simulate remote API fetch latency
      await Future.delayed(const Duration(milliseconds: 1200));

      final remoteListings = _getMockInitialListings();
      
      // Save successfully to Hive cache
      final jsonList = remoteListings.map((c) => c.toJson()).toList();
      HiveService.cacheMarketplaceListings(jsonList);

      state = AsyncData(remoteListings);
    } catch (e) {
      // Offline fallback: Check Hive cache
      final cachedList = HiveService.getCachedMarketplaceListings();
      if (cachedList != null) {
        final listings = cachedList.map((j) => CropListing.fromJson(j as Map)).toList();
        state = AsyncData(listings);
      } else {
        state = AsyncError("Failed to fetch listings. Check connection.", StackTrace.current);
      }
    }
  }

  // Add new produce listing by farmer
  void addListing(CropListing listing) {
    state.whenData((currentList) {
      final updatedList = [listing, ...currentList];
      
      // Update Hive cache
      final jsonList = updatedList.map((c) => c.toJson()).toList();
      HiveService.cacheMarketplaceListings(jsonList);

      state = AsyncData(updatedList);
    });
  }

  List<CropListing> _getMockInitialListings() {
    return [
      CropListing(
        id: '1',
        cropName: 'Organic Tomato (टमाटर)',
        category: 'Vegetables',
        quantity: 150.0,
        pricePerKg: 35.0,
        location: 'Khed, Pune',
        distanceKm: 12,
        freshness: 'Freshly Harvested',
        imagePath: 'tomato',
        harvestDate: '2026-05-21',
      ),
      CropListing(
        id: '2',
        cropName: 'Basmati Rice (चावल)',
        category: 'Grains',
        quantity: 800.0,
        pricePerKg: 72.0,
        location: 'Shirur, Pune',
        distanceKm: 28,
        freshness: 'Sun-Dried',
        imagePath: 'rice',
        harvestDate: '2026-05-18',
      ),
      CropListing(
        id: '3',
        cropName: 'Alphonso Mango (आम)',
        category: 'Fruits',
        quantity: 250.0,
        pricePerKg: 120.0,
        location: 'Ratnagiri, MH',
        distanceKm: 85,
        freshness: 'Freshly Picked',
        imagePath: 'mango',
        harvestDate: '2026-05-22',
      ),
      CropListing(
        id: '4',
        cropName: 'Farm Onions (प्याज)',
        category: 'Vegetables',
        quantity: 600.0,
        pricePerKg: 24.0,
        location: 'Chakan, Pune',
        distanceKm: 18,
        freshness: 'Field Grade A',
        imagePath: 'onion',
        harvestDate: '2026-05-20',
      ),
      CropListing(
        id: '5',
        cropName: 'Organic Wheat (गेहूं)',
        category: 'Grains',
        quantity: 1200.0,
        pricePerKg: 28.5,
        location: 'Baramati, Pune',
        distanceKm: 42,
        freshness: 'New Harvest',
        imagePath: 'wheat',
        harvestDate: '2026-05-15',
      ),
    ];
  }
}
final marketplaceListingsProvider = NotifierProvider<MarketplaceListingsNotifier, AsyncValue<List<CropListing>>>(() {
  return MarketplaceListingsNotifier();
});
