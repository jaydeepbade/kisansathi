import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context, ref);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            loc.getTranslate('analytics_title'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            tabs: [
              Tab(text: loc.getTranslate('price_trends')),
              Tab(text: loc.getTranslate('yield_analytics')),
              Tab(text: loc.getTranslate('future_predictions')),
              Tab(text: loc.getTranslate('sustainability_market')),
            ],
          ),
        ),
        body: Column(
          children: [
            // 1. Summary Stat Cards Grid
            _buildSummaryStatsGrid(loc, isDark),

            // 2. Tab Views holding fl_chart visualizations
            Expanded(
              child: TabBarView(
                children: [
                  _buildPriceTrendsTab(isDark, loc),
                  _buildYieldAnalyticsTab(isDark, loc),
                  _buildFuturePredictionsTab(isDark, loc),
                  _buildSustainabilityTab(isDark, loc),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStatsGrid(AppLocalizations loc, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      child: Row(
        children: [
          // Total Revenue
          Expanded(
            child: _buildStatCard(
              title: loc.getTranslate('total_revenue'),
              value: '₹1,48,500',
              trend: '+12.4% m-o-m',
              trendColor: AppColors.success,
              icon: Icons.account_balance_wallet,
              isDark: isDark,
            ),
          ),
          // Active Listings
          Expanded(
            child: _buildStatCard(
              title: loc.getTranslate('active_listings'),
              value: '5 Active',
              trend: '2 Sold this week',
              trendColor: AppColors.secondary,
              icon: Icons.receipt_long,
              isDark: isDark,
            ),
          ),
          // Margin Premium
          Expanded(
            child: _buildStatCard(
              title: loc.getTranslate('price_premium'),
              value: '+18.4%',
              trend: 'Above mandi rate',
              trendColor: AppColors.success,
              icon: Icons.trending_up,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String trend,
    required Color trendColor,
    required IconData icon,
    required bool isDark,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: AppColors.primary, size: 18),
                const SizedBox(width: 4),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              trend,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: trendColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceTrendsTab(bool isDark, AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '30-Day Mandi Price vs Your Listing (₹)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Showing organic tomato pricing variations across Pune Mandi markets.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),
              // LineChart setup using fl_chart
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 6,
                          getTitlesWidget: (value, meta) {
                            switch (value.toInt()) {
                              case 1:
                                return const Text('May 1', style: TextStyle(fontSize: 9));
                              case 10:
                                return const Text('May 10', style: TextStyle(fontSize: 9));
                              case 20:
                                return const Text('May 20', style: TextStyle(fontSize: 9));
                              case 30:
                                return const Text('May 30', style: TextStyle(fontSize: 9));
                            }
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 1,
                    maxX: 30,
                    minY: 10,
                    maxY: 60,
                    lineBarsData: [
                      // Farmer Listed Price Line (Primary Color)
                      LineChartBarData(
                        spots: const [
                          FlSpot(1, 35),
                          FlSpot(5, 36),
                          FlSpot(10, 38),
                          FlSpot(15, 37),
                          FlSpot(20, 42),
                          FlSpot(25, 43),
                          FlSpot(30, 45),
                        ],
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withAlpha(25),
                        ),
                      ),
                      // Mandi Price Line (Secondary Color)
                      LineChartBarData(
                        spots: const [
                          FlSpot(1, 28),
                          FlSpot(5, 29),
                          FlSpot(10, 31),
                          FlSpot(15, 30),
                          FlSpot(20, 34),
                          FlSpot(25, 32),
                          FlSpot(30, 36),
                        ],
                        isCurved: true,
                        color: AppColors.secondary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Legends
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendIndicator(AppColors.primary, 'Your Average Price (आपका मूल्य)'),
                  const SizedBox(width: 24),
                  _buildLegendIndicator(AppColors.secondary, 'Average Mandi Rate (मंडी मूल्य)'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYieldAnalyticsTab(bool isDark, AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Monthly Harvest Yield Comparison (kg)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Comparing total crop output metrics from previous harvest season.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 28),
              // BarChart setup using fl_chart
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            switch (value.toInt()) {
                              case 1:
                                return const Text('Feb', style: TextStyle(fontSize: 10));
                              case 2:
                                return const Text('Mar', style: TextStyle(fontSize: 10));
                              case 3:
                                return const Text('Apr', style: TextStyle(fontSize: 10));
                              case 4:
                                return const Text('May', style: TextStyle(fontSize: 10));
                            }
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      _buildBarGroup(1, 450, 600, isDark),
                      _buildBarGroup(2, 600, 780, isDark),
                      _buildBarGroup(3, 850, 950, isDark),
                      _buildBarGroup(4, 980, 1200, isDark),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Legends
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendIndicator(AppColors.primary, 'Last Year Yield (पिछला वर्ष)'),
                  const SizedBox(width: 24),
                  _buildLegendIndicator(Colors.green.shade200, 'Current Year Yield (चालू वर्ष)'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendIndicator(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  BarChartGroupData _buildBarGroup(int x, double val1, double val2, bool isDark) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: val1,
          color: isDark ? AppColors.borderDark : Colors.grey.shade400,
          width: 12,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
        BarChartRodData(
          toY: val2,
          color: AppColors.primary,
          width: 12,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }

  Widget _buildFuturePredictionsTab(bool isDark, AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.getTranslate('future_predictions'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'AI-driven forecast for next season\'s crop yields and market demand.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),
              // Dummy graph for future predictions
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(1, 30),
                          FlSpot(2, 45),
                          FlSpot(3, 35),
                          FlSpot(4, 55),
                          FlSpot(5, 50),
                        ],
                        isCurved: true,
                        color: Colors.purple,
                        barWidth: 4,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendIndicator(Colors.purple, 'Projected Market Price'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSustainabilityTab(bool isDark, AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.eco, color: Colors.green, size: 32),
              title: Text(loc.getTranslate('sustainability_score')),
              subtitle: const Text('92/100 - Excellent soil health and low pesticide usage.'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.inventory_2, color: Colors.orange, size: 32),
              title: Text(loc.getTranslate('shelf_life')),
              subtitle: const Text('Tomatoes: ~12 Days with cold storage.'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.trending_up, color: Colors.blue, size: 32),
              title: Text(loc.getTranslate('market_demand')),
              subtitle: const Text('High demand predicted for organic wheat next month.'),
            ),
          ),
        ],
      ),
    );
  }
}
