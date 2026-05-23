import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/cache/hive_service.dart';
import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() async {
  // Ensure framework visual bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive offline-first cache layers
  await HiveService.init();

  runApp(
    const ProviderScope(
      child: FarmSaathiApp(),
    ),
  );
}

class FarmSaathiApp extends ConsumerWidget {
  const FarmSaathiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch active locale from our localization state notifier
    final activeLocale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'FarmSaathi',
      debugShowCheckedModeBanner: false,
      
      // Routing configuration
      routerConfig: AppRouter.router,
      
      // Dynamic Light & Dark Mode configurations following system settings
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      // Localizations delegation for Hindi, English & Marathi compatibility
      locale: Locale(activeLocale.name),
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('mr'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
