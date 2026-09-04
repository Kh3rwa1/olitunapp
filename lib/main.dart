import 'package:itun/core/logging/app_logger.dart';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'app/router/app_router.dart';
import 'app/router/url_strategy.dart';
import 'core/config/appwrite_config.dart';
import 'core/observability/app_observability.dart';
import 'core/observability/crash_reporting.dart';
import 'core/storage/hive_service.dart';
import 'core/theme/app_theme.dart';
import 'core/network/secure_http_overrides.dart';
import 'shared/providers/local_settings_provider.dart';
import 'shared/offline/content_mutation_replay.dart';
import 'l10n/generated/app_localizations.dart';
import 'core/ads/ad_service.dart';
import 'core/ads/consent_manager.dart';
import 'core/notifications/notification_service.dart';
import 'features/home/presentation/providers/daily_missions_observer.dart';

@visibleForTesting
Locale appLocaleForLanguage(String languageCode) {
  switch (languageCode) {
    case 'sat':
      return const Locale('sat');
    case 'hi':
      return const Locale('hi');
    case 'bn':
      return const Locale('bn');
    case 'or':
      return const Locale('or');
    case 'en':
    default:
      return const Locale('en');
  }
}

Future<void> main() async {
  if (kIsWeb) {
    initialWebHash = Uri.base.fragment;
  }
  configureUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  runZonedGuarded(
    () async {
      try {
        // Enforce strict production TLS certificate validation.
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

        try {
          await CrashReporting.init();
        } catch (e) {
          AppLogger.debug('Non-essential CrashReporting init failed: $e');
        }

        try {
          await JustAudioBackground.init(
            androidNotificationChannelId: 'com.olitun.app.channel.bakhed',
            androidNotificationChannelName: 'Bakhed playback',
            androidNotificationChannelDescription:
                'Controls for long Bakhed audio playback',
            androidNotificationOngoing: true,
          );
        } catch (e) {
          AppLogger.debug('Non-essential JustAudioBackground init failed: $e');
        }

        // Initialize Google AdMob & UMP GDPR consent flow
        try {
          final consentManager = ConsentManager(prefs);
          await AdService.instance.initialize(consentManager: consentManager);
        } catch (e) {
          AppLogger.debug('Non-essential AdService init failed: $e');
        }

        // Initialize daily streak & study reminder notifications
        try {
          await NotificationService.instance.initialize();
          final notificationsEnabled =
              prefs.getBool('notifications_enabled') ?? true;
          if (notificationsEnabled) {
            final hour = prefs.getInt('reminder_hour') ?? 20;
            final minute = prefs.getInt('reminder_minute') ?? 0;
            await NotificationService.instance.scheduleDailyStreakReminder(
              hour: hour,
              minute: minute,
            );
          }
        } catch (e) {
          AppLogger.debug('Non-essential NotificationService init failed: $e');
        }

        runApp(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            observers: const [DailyMissionsObserver(), AppProviderObserver()],
            child: const OlitunApp(),
          ),
        );
      } catch (e, stack) {
        AppLogger.debug('Fatal initialization error: $e\n$stack');
        runApp(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: const Color(0xFF1E1E2C),
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFFFB74D),
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Unable to Start Application',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          kReleaseMode
                              ? 'Olitun could not connect to necessary services. Please verify your internet connection and try again.'
                              : e.toString(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: main,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry Startup'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF6C5CE7,
                            ), // white on #6C5CE7 = 4.76:1 (WCAG pass)
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
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
    },
    (error, stack) {
      AppLogger.debug('Uncaught zone error: $error');
      CrashReporting.recordError(error, stack);
    },
  );
}

class OlitunApp extends ConsumerWidget {
  const OlitunApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps the offline content mutation replay listener alive for the
    // app's lifetime (startup pass + connectivity-regained replays).
    ref.watch(mutationReplayInitProvider);
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
      builder: (context, child) {
        // Honor OS text scaling up to 1.5x — large enough for low-vision
        // readability, capped so dense designed layouts never shear/overflow.
        // Above 1.5x the fix is layout work, not infinite scale.
        final mediaQuery = MediaQuery.of(context);
        final effectiveScale = mediaQuery.textScaler.scale(100.0) / 100.0;
        final scaler = effectiveScale > 1.5
            ? const TextScaler.linear(1.5)
            : mediaQuery.textScaler;
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: scaler),
          child: child ?? const SizedBox(),
        );
      },
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
