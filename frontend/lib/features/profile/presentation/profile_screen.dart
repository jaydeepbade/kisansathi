import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/cache/hive_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _pushNotifications = true;
  final String _maskedAccount = 'State Bank of India - ******4928';

  void _changeLanguage(AppLocale locale) {
    ref.read(localeProvider.notifier).setLocale(locale);
    
    // Save language setting to Hive settings box
    HiveService.saveString('app_lang', locale.name);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          locale == AppLocale.en
              ? 'Language updated to English!'
              : locale == AppLocale.hi
                  ? 'भाषा बदलकर हिंदी कर दी गई है!'
                  : 'भाषा बदलून मराठी करण्यात आली आहे!',
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleLogout() async {
    // Clear Hive offline caches
    await HiveService.clearAll();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signed out successfully (सफलतापूर्वक लॉगआउट किया गया)'),
          backgroundColor: Colors.black,
        ),
      );
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context, ref);
    final activeLocale = ref.watch(localeProvider);

    // Default farmer details
    final farmerName = HiveService.getString('user_name') ?? 'Rajesh Kumar';
    final farmLocation = HiveService.getString('user_location') ?? 'Pune, Maharashtra';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.getTranslate('nav_profile'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Farmer Bio Card (Farm Size, Crops badges, verified tick)
            _buildFarmerProfileCard(farmerName, farmLocation, isDark, loc),
            const SizedBox(height: 12),

            // 2. Settings Panel: Language toggle (EN/HI/MR)
            _buildLanguageSettingsCard(activeLocale, isDark, loc),
            const SizedBox(height: 12),

            // 3. Banking Info Card
            _buildBankInfoCard(isDark, loc),
            const SizedBox(height: 12),

            // 4. Settings & Preferences
            _buildSettingsSection(isDark, loc),
            const SizedBox(height: 24),

            // 5. Logout CTA Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: OutlinedButton(
                onPressed: _handleLogout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text(
                      loc.getTranslate('logout'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmerProfileCard(String name, String location, bool isDark, AppLocalizations loc) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                // Profile Avatar
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary.withAlpha(51),
                  child: const Icon(Icons.person, color: AppColors.primary, size: 40),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, color: AppColors.primary, size: 18),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '📍 $location',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          loc.getTranslate('aadhaar_verified'),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Farm stats (Size, crops badges)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.getTranslate('farm_size'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '4.5 Acres (एकड़)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.getTranslate('crops_grown'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: const [
                          _CropBadge(label: 'Tomato'),
                          _CropBadge(label: 'Wheat'),
                          _CropBadge(label: 'Onion'),
                        ],
                      ),
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

  Widget _buildLanguageSettingsCard(AppLocale activeLocale, bool isDark, AppLocalizations loc) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.getTranslate('lang_settings'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // English Chip
                Expanded(
                  child: _buildLangButton(
                    label: 'English',
                    locale: AppLocale.en,
                    isActive: activeLocale == AppLocale.en,
                  ),
                ),
                const SizedBox(width: 8),
                // Hindi Chip
                Expanded(
                  child: _buildLangButton(
                    label: 'हिंदी',
                    locale: AppLocale.hi,
                    isActive: activeLocale == AppLocale.hi,
                  ),
                ),
                const SizedBox(width: 8),
                // Marathi Chip
                Expanded(
                  child: _buildLangButton(
                    label: 'मराठी',
                    locale: AppLocale.mr,
                    isActive: activeLocale == AppLocale.mr,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangButton({
    required String label,
    required AppLocale locale,
    required bool isActive,
  }) {
    return InkWell(
      onTap: () => _changeLanguage(locale),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.grey.shade400,
            width: isActive ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBankInfoCard(bool isDark, AppLocalizations loc) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.account_balance, color: Colors.blue),
        ),
        title: Text(
          loc.getTranslate('bank_account'),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            _maskedAccount,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        trailing: const Icon(Icons.lock_outline, size: 16),
      ),
    );
  }

  Widget _buildSettingsSection(bool isDark, AppLocalizations loc) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              loc.getTranslate('settings'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            activeThumbColor: AppColors.primary,
            title: Text(
              loc.getTranslate('notification_settings'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            value: _pushNotifications,
            onChanged: (bool value) {
              setState(() {
                _pushNotifications = value;
              });
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(loc.getTranslate('account_settings')),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: Text(loc.getTranslate('app_theme')),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.mic_none),
            title: Text(loc.getTranslate('voice_assistant')),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(loc.getTranslate('help_support')),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _CropBadge extends StatelessWidget {
  final String label;
  const _CropBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
