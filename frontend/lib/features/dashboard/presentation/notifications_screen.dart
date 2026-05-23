import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context, ref);

    // Dummy notifications data
    final List<Map<String, dynamic>> notifications = [
      {
        'title': 'Heavy Rain Alert',
        'message': 'Expect heavy rainfall in your area tomorrow. Please secure your crops.',
        'time': '10 mins ago',
        'icon': Icons.water_drop,
        'color': Colors.blue,
        'isRead': false,
      },
      {
        'title': 'New Market Price',
        'message': 'Wheat prices have gone up by 5% in the Pune market.',
        'time': '1 hour ago',
        'icon': Icons.trending_up,
        'color': Colors.green,
        'isRead': false,
      },
      {
        'title': 'System Maintenance',
        'message': 'FarmSaathi app will undergo scheduled maintenance tonight at 12 AM.',
        'time': '3 hours ago',
        'icon': Icons.build,
        'color': Colors.orange,
        'isRead': true,
      },
      {
        'title': 'AI Advisory Available',
        'message': 'Your weekly crop health report is ready. Tap to view.',
        'time': '1 day ago',
        'icon': Icons.psychology,
        'color': AppColors.primary,
        'isRead': true,
      },
      {
        'title': 'Govt. Scheme Update',
        'message': 'New subsidies are available for organic fertilizers. Check eligibility.',
        'time': '2 days ago',
        'icon': Icons.account_balance,
        'color': Colors.purple,
        'isRead': true,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notif = notifications[index];
          return _buildNotificationCard(notif, isDark);
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif, bool isDark) {
    return Card(
      elevation: notif['isRead'] ? 1 : 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: notif['isRead'] 
              ? Colors.transparent 
              : AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      color: notif['isRead'] 
          ? (isDark ? AppColors.surfaceDark : Colors.white)
          : (isDark ? AppColors.surfaceDark.withOpacity(0.8) : AppColors.primary.withOpacity(0.05)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: notif['color'].withOpacity(0.1),
              child: Icon(notif['icon'], color: notif['color']),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif['title'],
                          style: TextStyle(
                            fontWeight: notif['isRead'] ? FontWeight.w500 : FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (!notif['isRead'])
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notif['message'],
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notif['time'],
                    style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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
}
