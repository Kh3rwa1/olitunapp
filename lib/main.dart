import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router/app_router.dart';
import 'core/config/appwrite_config.dart';
import 'core/observability/crash_reporting.dart';
import 'core/storage/hive_service.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/local_settings_provider.dart';
import 'l10n/generated/app_localizations.dart';

@visibleForTesting
Locale appLocaleForLanguage(String languageCode) {
  switch (languageCode) {
    case 'sat':
      return const Locale('sat');
    case 'en':
    default:
      return const Locale('en');
  }
}

Future<void> main() async {
  try {
    await runZonedGuarded(
      () async {
        WidgetsFlutterBinding.ensureInitialized();

        // Fail fast if Appwrite config is missing; release builds must not silently
        // point at the wrong backend or an empty project.
        AppwriteConfig.validate();
        FlutterError.onError = (details) {
          FlutterError.presentError(details);
          CrashReporting.recordFlutterError(details);
        };

        final prefs = await initStorage();

        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
        );

        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);

        await CrashReporting.init();

        runApp(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: const OlitunApp(),
          ),
        );
      },
      (error, stack) {
        debugPrint('Uncaught zone error: $error');
        CrashReporting.recordError(error, stack);
      },
    );
  } catch (e, stack) {
    debugPrint('Fatal initialization error: $e\n$stack');
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.red.shade900,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Initialization Failed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      e.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OlitunApp extends ConsumerWidget {
  const OlitunApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final languageCode = ref.watch(appLanguageProvider);

    return MaterialApp.router(
      title: 'Olitun',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _getThemeMode(themeMode),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: appLocaleForLanguage(languageCode),
      routerConfig: router,
    );
  }

  ThemeMode _getThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
