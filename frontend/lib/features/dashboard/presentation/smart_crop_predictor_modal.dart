import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';

class SmartCropPredictorModal extends ConsumerStatefulWidget {
  const SmartCropPredictorModal({super.key});

  @override
  ConsumerState<SmartCropPredictorModal> createState() => _SmartCropPredictorModalState();
}

class _SmartCropPredictorModalState extends ConsumerState<SmartCropPredictorModal> {
  int _analysisStep = 0;
  bool _analysisComplete = false;

  final List<String> _analysisFactors = [
    'Fetching Weather Forecast & Rainfall data...',
    'Analyzing Soil Conditions & Temperature...',
    'Checking Water Availability...',
    'Evaluating Market & Export Demand...',
    'Reviewing Local Mandi Prices & Seasonal Trends...',
    'Factoring Government Schemes & Fertilizer Costs...',
  ];

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    for (int i = 0; i < _analysisFactors.length; i++) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        setState(() {
          _analysisStep = i + 1;
        });
      }
    }
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _analysisComplete = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2D3D) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: AppColors.primary, size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Smart Crop Predictor',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '“What crop should I grow NEXT for maximum profit?”',
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          
          if (!_analysisComplete) ...[
            LinearProgressIndicator(
              value: (_analysisStep / _analysisFactors.length).clamp(0.0, 1.0),
              backgroundColor: AppColors.primary.withAlpha(40),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
            const SizedBox(height: 20),
            ...List.generate(_analysisFactors.length, (index) {
              final isActive = index == _analysisStep;
              final isDone = index < _analysisStep;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Icon(
                      isDone ? Icons.check_circle : (isActive ? Icons.sync : Icons.circle_outlined),
                      color: isDone ? AppColors.success : (isActive ? AppColors.primary : Colors.grey),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _analysisFactors[index],
                        style: TextStyle(
                          color: isDone || isActive
                              ? (isDark ? Colors.white : Colors.black87)
                              : Colors.grey,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else ...[
            // Result View
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withAlpha(200)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(60),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.grass, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Highly Recommended Crop',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Soybean (JS 335)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.trending_up, color: Colors.greenAccent, size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        'Projected Profit Margin: 42%',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Based on upcoming monsoon forecast and 15% increase in local mandi demand.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('View Detailed Farming Plan'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
