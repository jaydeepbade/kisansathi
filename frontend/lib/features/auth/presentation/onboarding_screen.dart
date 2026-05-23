import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/cache/hive_service.dart';
import '../../../core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedRole = 'Farmer'; // Default role

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Empowering Smart Farming',
      subtitle: 'कृषि विकास की ओर',
      description: 'Get hyper-local weather alerts, AI crop disease scanning, and mandi predictions instantly at your fingertips.',
      icon: Icons.agriculture,
      color: AppColors.primary,
    ),
    OnboardingData(
      title: 'Direct Local Marketplace',
      subtitle: 'किसानों का अपना बाजार',
      description: 'Sell your produce directly to buyers with zero middlemen. Get fair prices and receive instant bank payments.',
      icon: Icons.storefront,
      color: AppColors.secondary,
    ),
    OnboardingData(
      title: 'AI Advisory & Insights',
      subtitle: 'कृत्रिम बुद्धिमत्ता सलाह',
      description: 'Access real-time crop disease diagnosis and automated, expert-vetted recommendations to double your yields.',
      icon: Icons.psychology,
      color: AppColors.primary,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    // Save selected role in Hive settings box
    HiveService.saveString('user_role', _selectedRole);
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation header (Skip button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_currentPage < 3)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _currentPage = 3; // Direct to role selector page
                        });
                      },
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Core PageView (onboarding slides + role selector page)
            Expanded(
              child: _currentPage < 3
                  ? PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        final page = _pages[index];
                        return _buildOnboardingPage(page, isDark);
                      },
                    )
                  : _buildRoleSelectorPage(isDark),
            ),

            // Navigation controls / Indicators
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _currentPage < 3
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Page Dot Indicators
                        Row(
                          children: List.generate(
                            _pages.length,
                            (index) => _buildDotIndicator(index == _currentPage),
                          ),
                        ),
                        // Next button
                        ElevatedButton(
                          onPressed: () {
                            if (_currentPage < _pages.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeIn,
                              );
                            } else {
                              setState(() {
                                _currentPage = 3;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(120, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Next', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: _finishOnboarding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Proceed to Verification',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.primary.withAlpha(51),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingData page, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Graphic container replacing Lottie with a gorgeous native vector representation
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              color: page.color.withAlpha(isDark ? 40 : 25),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft background shapes
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: page.color.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: page.color.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Glowing centered visual icon
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Icon(
                        page.icon,
                        size: 110,
                        color: page.color,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelectorPage(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Who are you?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your role to personalize the app',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 32),
          _buildRoleCard('Farmer', 'किसान', 'Sell produce, scan crop diseases, check mandi rates, and receive AI advisories.', Icons.agriculture, isDark),
          const SizedBox(height: 16),
          _buildRoleCard('Buyer', 'खरीदार', 'Explore high-quality agricultural yield directly from verified farmers.', Icons.shopping_basket, isDark),
          const SizedBox(height: 16),
          _buildRoleCard('Admin', 'प्रशासक', 'Verify Aadhaar cards, oversee local markets, and manage notifications.', Icons.admin_panel_settings, isDark),
        ],
      ),
    );
  }

  Widget _buildRoleCard(String role, String translation, String description, IconData icon, bool isDark) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withAlpha(isDark ? 40 : 15) 
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : (isDark ? Colors.white10 : Colors.grey.shade100),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        role,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($translation)',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
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
}

class OnboardingData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}
