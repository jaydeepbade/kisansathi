import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/cache/hive_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/dashboard_providers.dart';
import '../presentation/navigation_wrapper.dart';
import '../../recommendations/presentation/recommendations_screen.dart';

// Marketplace state triggers (needed for navigation actions)
import '../../marketplace/providers/marketplace_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context, ref);
    
    // Read cached farmer credentials
    final farmerName = HiveService.getString('user_name') ?? 'Rajesh Kumar';
    final farmLocation = HiveService.getString('user_location') ?? 'Pune, Maharashtra';

    // Watch weather and alerts providers
    final weatherState = ref.watch(weatherStateProvider);
    final alertsStream = ref.watch(alertsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.getTranslate('app_name'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Badge(
              label: const Text('3'),
              child: const Icon(Icons.notifications_none, color: AppColors.primary),
            ),
            onPressed: () {
              // Open notifications (to be implemented)
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Greeting Card
              _buildGreetingCard(farmerName, farmLocation, isDark, loc),
              
              // Weather state display (Offline notification if cache active)
              weatherState.when(
                data: (state) => Column(
                  children: [
                    if (state.isFromCache)
                      _buildOfflineBanner(state.errorMessage ?? ""),
                    _buildWeatherWidget(context, state.data, isDark, loc),
                  ],
                ),
                loading: () => _buildShimmerWeather(),
                error: (err, _) => _buildErrorWeatherWidget(ref),
              ),

              // 2. Crop Health Score Ring
              _buildCropHealthScore(isDark, loc),

              // 3. Quick Action Buttons Row
              _buildQuickActionsRow(ref, context, loc),

              // 4. AI Advisories Call-To-Action Banner
              _buildAiAdvisoriesBanner(context, isDark, loc),

              // 5. Recent Alerts List (Supabase Stream)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  loc.getTranslate('recent_alerts'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              alertsStream.when(
                data: (alerts) => _buildAlertsList(alerts, isDark),
                loading: () => _buildShimmerAlerts(),
                error: (err, _) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Failed to load realtime alerts (अलर्ट लोड करने में विफल)'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingCard(String name, String location, bool isDark, AppLocalizations loc) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withAlpha(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withAlpha(51),
            child: const Icon(Icons.person, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.getTranslate('welcome_farmer'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withAlpha(204),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withAlpha(229),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.secondary.withAlpha(51),
        border: Border.all(color: AppColors.secondary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: AppColors.secondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherWidget(BuildContext context, dynamic weather, bool isDark, AppLocalizations loc) {
    if (weather == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  weather.condition == 'Rainy' ? Icons.cloudy_snowing : Icons.wb_sunny,
                  color: weather.condition == 'Rainy' ? Colors.blue : AppColors.secondary,
                  size: 40,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.getTranslate('weather_title'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      weather.rainForecast,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${weather.temperature}°C',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '💧 ${loc.getTranslate('humidity')}: ${weather.humidity}%',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => _buildAdvancedWeatherDialog(context, isDark, loc, weather),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        loc.getTranslate('advanced_weather'),
                        style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedWeatherDialog(BuildContext context, bool isDark, AppLocalizations loc, dynamic weather) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.cloud, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(loc.getTranslate('advanced_weather'), style: const TextStyle(fontSize: 18)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.getTranslate('soil_moisture')),
              const Text('42%', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.getTranslate('wind_speed')),
              const Text('12 km/h NW', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(loc.getTranslate('7_day_forecast'), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          // Dummy 7 day forecast
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Day ${index+1}', style: const TextStyle(fontSize: 10)),
                      const Icon(Icons.wb_sunny, size: 18, color: Colors.orange),
                      const Text('32°', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildCropHealthScore(bool isDark, AppLocalizations loc) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Circular Progress Indicator Styled
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: 0.88,
                    strokeWidth: 8,
                    backgroundColor: AppColors.primary.withAlpha(38),
                    color: AppColors.primary,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                const Text(
                  '88%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.getTranslate('crop_health_score'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Optimal Field Status (इष्टतम स्थिति)',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nitrogen, phosphorus, moisture levels are currently ideal.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsRow(WidgetRef ref, BuildContext context, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Action 1: Scan Leaf
          Expanded(
            child: _buildActionCard(
              icon: Icons.camera_alt,
              label: loc.getTranslate('scan_leaf'),
              color: Colors.green.shade600,
              onTap: () {
                ref.read(navigationIndexProvider.notifier).setIndex(2); // Go to Scan tab
              },
            ),
          ),
          const SizedBox(width: 10),
          // Action 2: List Produce
          Expanded(
            child: _buildActionCard(
              icon: Icons.add_shopping_cart,
              label: loc.getTranslate('list_produce'),
              color: AppColors.secondary,
              onTap: () {
                ref.read(navigationIndexProvider.notifier).setIndex(1); // Go to Marketplace
                // Trigger the bottom sheet directly in the marketplace!
                Future.delayed(const Duration(milliseconds: 150)).then((_) {
                  marketplaceShowFormEvent.value = true;
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          // Action 3: Check Prices
          Expanded(
            child: _buildActionCard(
              icon: Icons.trending_up,
              label: loc.getTranslate('check_prices'),
              color: Colors.blue.shade600,
              onTap: () {
                ref.read(navigationIndexProvider.notifier).setIndex(3); // Go to Analytics
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(76), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiAdvisoriesBanner(BuildContext context, bool isDark, AppLocalizations loc) {
    return GestureDetector(
      onTap: () {
        // Route seamlessly to full AI Recommendations Screen
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const RecommendationsScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(20),
          border: Border.all(color: AppColors.primary, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.getTranslate('ai_recs_title'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Heavy Rain expected — check 3 custom recommendations.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsList(List<String> alerts, bool isDark) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.campaign,
                color: AppColors.secondary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  alert,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerWeather() {
    return Container(
      margin: const EdgeInsets.all(12),
      height: 72,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerAlerts() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        height: 54,
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWeatherWidget(WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Could not fetch Weather data.'),
            ElevatedButton(
              onPressed: () {
                ref.read(weatherStateProvider.notifier).fetchWeather();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(80, 36),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
