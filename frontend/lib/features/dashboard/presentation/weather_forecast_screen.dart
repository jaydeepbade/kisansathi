import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/api/mock_endpoints.dart';
import '../providers/dashboard_providers.dart';

class WeatherForecastScreen extends ConsumerWidget {
  final WeatherData weather;
  const WeatherForecastScreen({super.key, required this.weather});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRainy = weather.condition == 'Rainy';

    final List<Map<String, dynamic>> weekForecast = [
      {'day': 'Today', 'icon': isRainy ? Icons.water_drop : Icons.wb_sunny, 'high': weather.temperature, 'low': weather.temperature - 4, 'desc': weather.condition, 'color': isRainy ? Colors.blue : Colors.orange},
      {'day': 'Tomorrow', 'icon': Icons.cloud, 'high': 30.2, 'low': 24.5, 'desc': 'Cloudy', 'color': Colors.blueGrey},
      {'day': 'Wed', 'icon': Icons.thunderstorm, 'high': 27.8, 'low': 22.0, 'desc': 'Thunder', 'color': Colors.deepPurple},
      {'day': 'Thu', 'icon': Icons.grain, 'high': 29.5, 'low': 23.8, 'desc': 'Light Rain', 'color': Colors.lightBlue},
      {'day': 'Fri', 'icon': Icons.wb_sunny, 'high': 33.0, 'low': 26.0, 'desc': 'Sunny', 'color': Colors.orange},
      {'day': 'Sat', 'icon': Icons.wb_cloudy, 'high': 31.0, 'low': 25.5, 'desc': 'Partly Cloudy', 'color': Colors.blueGrey},
      {'day': 'Sun', 'icon': Icons.wb_sunny, 'high': 34.5, 'low': 27.0, 'desc': 'Sunny', 'color': Colors.deepOrange},
    ];

    final List<Map<String, dynamic>> hourlyForecast = [
      {'hour': 'Now', 'icon': isRainy ? Icons.water_drop : Icons.wb_sunny, 'temp': weather.temperature, 'color': isRainy ? Colors.blue : Colors.orange},
      {'hour': '3 PM', 'icon': Icons.cloud, 'temp': weather.temperature - 1, 'color': Colors.blueGrey},
      {'hour': '6 PM', 'icon': Icons.grain, 'temp': weather.temperature - 2, 'color': Colors.lightBlue},
      {'hour': '9 PM', 'icon': Icons.nights_stay, 'temp': weather.temperature - 5, 'color': Colors.indigo},
      {'hour': '12 AM', 'icon': Icons.nights_stay, 'temp': weather.temperature - 7, 'color': Colors.indigo},
      {'hour': '3 AM', 'icon': Icons.nights_stay, 'temp': weather.temperature - 8, 'color': Colors.indigo},
      {'hour': '6 AM', 'icon': Icons.wb_twilight, 'temp': weather.temperature - 4, 'color': Colors.amber},
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1B2A) : const Color(0xFFE8F4FD),
      body: CustomScrollView(
        slivers: [
          // Hero Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: isRainy ? Colors.blue.shade700 : Colors.orange.shade600,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isRainy
                        ? [Colors.blue.shade900, Colors.blue.shade400]
                        : [Colors.orange.shade700, Colors.amber.shade300],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Icon(
                        isRainy ? Icons.water_drop : Icons.wb_sunny,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${weather.temperature.toStringAsFixed(1)}°C',
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w200,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        weather.condition,
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pune, Maharashtra',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withAlpha(180),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Stats Row
                  _buildStatsCard(weather, isDark),
                  const SizedBox(height: 20),

                  // Farming Advisory Banner
                  _buildFarmingAdvisory(weather, isDark),
                  const SizedBox(height: 20),

                  // Hourly Forecast
                  _buildSectionTitle('Hourly Forecast', Icons.schedule, isDark),
                  const SizedBox(height: 12),
                  _buildHourlyForecast(hourlyForecast, isDark),
                  const SizedBox(height: 20),

                  // 7-Day Forecast
                  _buildSectionTitle('7-Day Forecast', Icons.date_range, isDark),
                  const SizedBox(height: 12),
                  _buildWeekForecast(weekForecast, isDark),
                  const SizedBox(height: 20),

                  // Agri Metrics
                  _buildSectionTitle('Agri Metrics', Icons.agriculture, isDark),
                  const SizedBox(height: 12),
                  _buildAgriMetrics(weather, isDark),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(WeatherData weather, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2D3D) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.water_drop, '${weather.humidity.toStringAsFixed(0)}%', 'Humidity', Colors.blue, isDark),
          _buildDivider(isDark),
          _buildStatItem(Icons.air, '12 km/h', 'Wind', Colors.teal, isDark),
          _buildDivider(isDark),
          _buildStatItem(Icons.compress, '1012 hPa', 'Pressure', Colors.purple, isDark),
          _buildDivider(isDark),
          _buildStatItem(Icons.visibility, '10 km', 'Visibility', Colors.orange, isDark),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
            )),
        Text(label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            )),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 40,
      width: 1,
      color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
    );
  }

  Widget _buildFarmingAdvisory(WeatherData weather, bool isDark) {
    final isRainy = weather.condition == 'Rainy';
    final advColor = isRainy ? Colors.blue : Colors.orange;
    final advisory = isRainy
        ? 'Heavy rainfall expected. Avoid irrigation. Ensure proper drainage in your fields. Protect harvested crops from moisture.'
        : 'Sunny weather ahead. Good time for spraying pesticides. Ensure adequate irrigation for your crops.';
    final icon = isRainy ? Icons.warning_amber_rounded : Icons.wb_sunny;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: advColor.withAlpha(20),
        border: Border.all(color: advColor.withAlpha(80)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: advColor.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: advColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🌾 Farming Advisory',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: advColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  advisory,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyForecast(List<Map<String, dynamic>> hours, bool isDark) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hours.length,
        itemBuilder: (context, index) {
          final h = hours[index];
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2D3D) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(h['hour'],
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    )),
                const SizedBox(height: 8),
                Icon(h['icon'], color: h['color'], size: 26),
                const SizedBox(height: 8),
                Text(
                  '${(h['temp'] as double).toStringAsFixed(0)}°',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeekForecast(List<Map<String, dynamic>> days, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2D3D) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10)],
      ),
      child: Column(
        children: days.asMap().entries.map((entry) {
          final i = entry.key;
          final d = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(d['day'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          )),
                    ),
                    Icon(d['icon'], color: d['color'], size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        d['desc'],
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Text(
                      '${(d['low'] as double).toStringAsFixed(0)}°',
                      style: TextStyle(color: Colors.blue.shade400, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(d['high'] as double).toStringAsFixed(0)}°',
                      style: TextStyle(color: Colors.orange.shade600, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (i < days.length - 1)
                Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAgriMetrics(WeatherData weather, bool isDark) {
    final metrics = [
      {'label': 'Soil Moisture', 'value': '42%', 'icon': Icons.grass, 'color': Colors.green, 'sub': 'Optimal for sowing'},
      {'label': 'UV Index', 'value': '7 (High)', 'icon': Icons.wb_sunny, 'color': Colors.orange, 'sub': 'Shade crops if needed'},
      {'label': 'Dew Point', 'value': '22°C', 'icon': Icons.water, 'color': Colors.lightBlue, 'sub': 'Risk of fungal growth'},
      {'label': 'Evaporation', 'value': '5.2 mm', 'icon': Icons.thermostat, 'color': Colors.red, 'sub': 'Irrigate in evening'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final m = metrics[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (m['color'] as Color).withAlpha(15),
            border: Border.all(color: (m['color'] as Color).withAlpha(60)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(m['icon'] as IconData, color: m['color'] as Color, size: 18),
                  const SizedBox(width: 6),
                  Text(m['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      )),
                ],
              ),
              const SizedBox(height: 4),
              Text(m['value'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: m['color'] as Color,
                  )),
              Text(m['sub'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  )),
            ],
          ),
        );
      },
    );
  }
}
