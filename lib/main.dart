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
import 'core/accessibility/app_experience_scope.dart';
import 'core/config/appwrite_config.dart';
import 'core/observability/app_observability.dart';
import 'core/observability/crash_reporting.dart';
import 'core/startup/startup_status_app.dart';
import 'core/startup/startup_tasks.dart';
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

final _storageStartup = RequiredStartupTask(initStorage);
final _optionalStartup = StartupTaskRunner();
bool _startupInProgress = false;

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      if (kIsWeb) {
        initialWebHash = Uri.base.fragment;
      }
      // Binding and runApp must share the same error zone, including retries.
      WidgetsFlutterBinding.ensureInitialized();
      configureUrlStrategy();
      await _startApplication();
    },
    (error, stack) {
      AppLogger.debug('Uncaught zone error: $error');
      CrashReporting.recordError(error, stack);
    },
  );
}

Future<void> _startApplication() async {
  if (_startupInProgress) return;
  _startupInProgress = true;
  runApp(const StartupStatusApp());
  try {
    SecureHttpOverrides.initialize();
    AppwriteConfig.validate();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      CrashReporting.recordFlutterError(details);
    };

    // A timeout keeps the underlying storage operation alive. A retry waits
    // for that same operation instead of opening a second set of Hive boxes.
    final prefs = await _storageStartup.run();
    final outcomes = await _optionalStartup.runAll({
      'display': () async {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
      },
      'crash-reporting': CrashReporting.init,
      'background-audio': () async {
        await JustAudioBackground.init(
          androidNotificationChannelId: 'com.olitun.app.channel.bakhed',
          androidNotificationChannelName: 'Bakhed playback',
          androidNotificationChannelDescription:
              'Controls for long Bakhed audio playback',
          androidNotificationOngoing: true,
        );
      },
      'ads': () async {
        final result = await AdService.instance.initialize(
          consentManager: ConsentManager(prefs),
        );
        result.fold(
          (_) => throw StateError('Ad service initialization failed'),
          (_) {},
        );
      },
      'notifications': () async {
        final service = NotificationService.instance;
        await service.initialize();
        if (!service.isInitialized) {
          throw StateError('Notification service initialization failed');
        }
        if (prefs.getBool('notifications_enabled') ?? true) {
          final hour = (prefs.getInt('reminder_hour') ?? 20).clamp(0, 23);
          final minute = (prefs.getInt('reminder_minute') ?? 0).clamp(0, 59);
          final name = prefs.getString('notification_frequency') ?? 'high';
          final frequency = NotificationFrequency.values.firstWhere(
            (value) => value.name == name,
            orElse: () => NotificationFrequency.high,
          );
          await service.scheduleAllReminders(
            frequency: frequency,
            hour: hour,
            minute: minute,
          );
        }
      },
    });
    for (final outcome in outcomes) {
      AppLogger.debug(
        'Startup ${outcome.name}: ${outcome.status.name} '
        'after ${outcome.elapsed.inMilliseconds}ms',
      );
    }

    runApp(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        observers: const [DailyMissionsObserver(), AppProviderObserver()],
        child: const OlitunApp(),
      ),
    );
  } catch (error, stack) {
    AppLogger.debug('Fatal initialization error: $error\n$stack');
    runApp(
      StartupStatusApp(
        errorMessage: kReleaseMode
            ? 'Olitun could not finish starting. Please try again. '
                  'If this continues, restart the app.'
            : error.toString(),
        onRetry: _startApplication,
      ),
    );
  } finally {
    _startupInProgress = false;
  }
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
      builder: (context, child) =>
          AppExperienceScope(child: child ?? const SizedBox()),
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
