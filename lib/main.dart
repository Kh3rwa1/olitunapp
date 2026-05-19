import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'app/router/app_router.dart';
import 'core/config/appwrite_config.dart';
import 'core/observability/crash_reporting.dart';
import 'core/storage/hive_service.dart';
import 'core/theme/app_theme.dart';
import 'core/network/secure_http_overrides.dart';
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

        // Enforce production SSL/TLS and certificate pinning overrides
        SecureHttpOverrides.initialize();

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

        await JustAudioBackground.init(
          androidNotificationChannelId: 'com.olitun.app.channel.bakhed',
          androidNotificationChannelName: 'Bakhed playback',
          androidNotificationChannelDescription:
              'Controls for long Bakhed audio playback',
          androidNotificationOngoing: true,
        );

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
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        FallbackMaterialLocalizationsDelegate(),
        FallbackCupertinoLocalizationsDelegate(),
        FallbackWidgetsLocalizationsDelegate(),
      ],
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

class FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'sat';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return SynchronousFuture<MaterialLocalizations>(
      const FallbackMaterialLocalizations(),
    );
  }

  @override
  bool shouldReload(FallbackMaterialLocalizationsDelegate old) => false;
}

class FallbackMaterialLocalizations extends DefaultMaterialLocalizations {
  const FallbackMaterialLocalizations();
}

class FallbackCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'sat';

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    return SynchronousFuture<CupertinoLocalizations>(
      const FallbackCupertinoLocalizations(),
    );
  }

  @override
  bool shouldReload(FallbackCupertinoLocalizationsDelegate old) => false;
}

class FallbackCupertinoLocalizations extends DefaultCupertinoLocalizations {
  const FallbackCupertinoLocalizations();
}

class FallbackWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const FallbackWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'sat';

  @override
  Future<WidgetsLocalizations> load(Locale locale) async {
    return SynchronousFuture<WidgetsLocalizations>(
      const FallbackWidgetsLocalizations(),
    );
  }

  @override
  bool shouldReload(FallbackWidgetsLocalizationsDelegate old) => false;
}

class FallbackWidgetsLocalizations extends DefaultWidgetsLocalizations {
  const FallbackWidgetsLocalizations();
}
