import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Models ───────────────────────────────────────────────────────────────────
class CropPrice {
  final String cropName;
  final double pricePerQuintal; // ₹
  final String trend; // 'rising', 'falling', 'stable'
  final String market;

  const CropPrice({
    required this.cropName,
    required this.pricePerQuintal,
    required this.trend,
    required this.market,
  });

  String get trendEmoji => trend == 'rising' ? '📈' : trend == 'falling' ? '📉' : '➡️';
}

// ─── Provider ─────────────────────────────────────────────────────────────────
final marketServiceProvider = Provider<MarketService>((ref) => MarketService());

// ─── Service ──────────────────────────────────────────────────────────────────
/// Market price service.
/// Currently returns curated mock data representative of typical Mandi prices.
/// To connect to real data: integrate data.gov.in /agmarknet API by replacing
/// [fetchCropPrices] with an actual Dio HTTP call using their resource ID.
class MarketService {
  Future<List<CropPrice>> fetchCropPrices(String state) async {
    // Simulated 300ms network latency
    await Future.delayed(const Duration(milliseconds: 300));

    // Typical Mandi prices for Maharashtra (₹/quintal)
    return const [
      CropPrice(cropName: 'Onion', pricePerQuintal: 2200, trend: 'rising', market: 'Lasalgaon'),
      CropPrice(cropName: 'Tomato', pricePerQuintal: 1500, trend: 'falling', market: 'Pune'),
      CropPrice(cropName: 'Soybean', pricePerQuintal: 5100, trend: 'stable', market: 'Nagpur'),
      CropPrice(cropName: 'Cotton', pricePerQuintal: 7200, trend: 'rising', market: 'Amravati'),
      CropPrice(cropName: 'Sugarcane', pricePerQuintal: 350, trend: 'stable', market: 'Kolhapur'),
      CropPrice(cropName: 'Wheat', pricePerQuintal: 2300, trend: 'stable', market: 'Nashik'),
      CropPrice(cropName: 'Rice', pricePerQuintal: 2100, trend: 'rising', market: 'Ratnagiri'),
      CropPrice(cropName: 'Maize', pricePerQuintal: 1900, trend: 'stable', market: 'Aurangabad'),
    ];
  }

  /// Returns a concise market summary string for the GPT context prompt
  Future<String> getMarketContextString(String state) async {
    final prices = await fetchCropPrices(state);
    final rising = prices.where((p) => p.trend == 'rising').map((p) => p.cropName).join(', ');
    final falling = prices.where((p) => p.trend == 'falling').map((p) => p.cropName).join(', ');
    return 'Rising prices: $rising | Falling: $falling';
  }
}
