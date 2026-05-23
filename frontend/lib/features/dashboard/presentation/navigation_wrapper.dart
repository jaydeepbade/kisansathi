import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../marketplace/presentation/marketplace_screen.dart';
import '../../scanner/presentation/scanner_screen.dart';
import '../../analytics/presentation/analytics_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../../core/theme/app_colors.dart';
import 'voice_assistant_widget.dart';

class NavigationIndexNotifier extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  void setIndex(int index) {
    state = index;
  }
}

// Riverpod provider to manage active navigation tab index
final navigationIndexProvider = NotifierProvider<NavigationIndexNotifier, int>(() {
  return NavigationIndexNotifier();
});

class NavigationWrapper extends ConsumerWidget {
  const NavigationWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeIndex = ref.watch(navigationIndexProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Widget> screens = [
      const DashboardScreen(),
      const MarketplaceScreen(),
      const ScannerScreen(),
      const AnalyticsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: activeIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: activeIndex,
          onTap: (index) {
            ref.read(navigationIndexProvider.notifier).setIndex(index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home, color: AppColors.primary),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront, color: AppColors.primary),
              label: 'Market',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_outlined),
              activeIcon: Icon(Icons.camera_alt, color: AppColors.primary),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics, color: AppColors.primary),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person, color: AppColors.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
