from pathlib import Path


def replace(path, old, new, count=1):
    target = Path(path)
    text = target.read_text()
    actual = text.count(old)
    if actual != count:
        raise RuntimeError(f'{path}: expected {count} anchors, found {actual}')
    target.write_text(text.replace(old, new))


replace('lib/main.dart', 'final _optionalStartup = StartupTaskRunner();', '''final _optionalStartup = StartupTaskRunner();
// Audio players must not race a still-running background platform setup.
// Completed failures keep the existing foreground-audio fallback behavior.
final _audioStartup = RequiredStartupTask<void>(() async {
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.olitun.app.channel.bakhed',
      androidNotificationChannelName: 'Bakhed playback',
      androidNotificationChannelDescription:
          'Controls for long Bakhed audio playback',
      androidNotificationOngoing: true,
    );
  } catch (error) {
    AppLogger.debug('Non-essential JustAudioBackground init failed: $error');
  }
});''')
replace('lib/main.dart', '''  runApp(const StartupStatusApp());
  try {''', '''  try {
    runApp(const StartupStatusApp());''')
replace('lib/main.dart', 'final outcomes = await _optionalStartup.runAll({', 'final optionalWork = _optionalStartup.runAll({')
replace('lib/main.dart', '''      'background-audio': () async {
        await JustAudioBackground.init(
          androidNotificationChannelId: 'com.olitun.app.channel.bakhed',
          androidNotificationChannelName: 'Bakhed playback',
          androidNotificationChannelDescription:
              'Controls for long Bakhed audio playback',
          androidNotificationOngoing: true,
        );
      },
''', '')
replace('lib/main.dart', '''    for (final outcome in outcomes) {''', '''    // An audio timeout shows the retry shell, rather than launching players
    // against an unfinished platform. Retry reuses the same pending future.
    await _audioStartup.run(timeout: const Duration(seconds: 8));
    final outcomes = await optionalWork;
    for (final outcome in outcomes) {''')

replace('lib/core/ads/ad_service.dart', '''  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  bool get canServeAds => _isInitialized && consentManager.requestsAllowed;''', '''  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  final ValueNotifier<bool> _readiness = ValueNotifier(false);
  ValueListenable<bool> get readiness => _readiness;
  bool get canServeAds => _readiness.value && consentManager.requestsAllowed;''')
replace('lib/core/ads/ad_service.dart', '''    if (kIsWeb) {
      _isInitialized = true;
      return right<AdError, bool>(true);''', '''    if (kIsWeb) {
      _isInitialized = true;
      _readiness.value = true;
      return right<AdError, bool>(true);''')
replace('lib/core/ads/ad_service.dart', '''      registerOlitunNativeAdFactory();''', '''      registerOlitunNativeAdFactory();
      _readiness.value = true;''')
replace('lib/core/ads/ad_service.dart', '''      AppLogger.debug('AdService: Initialization error: $e\\n$stack');''', '''      _isInitialized = false;
      _readiness.value = false;
      AppLogger.debug('AdService: Initialization error: $e\\n$stack');''')
replace('lib/core/ads/ad_service.dart', '''  void dispose() {
    WidgetsBinding.instance.removeObserver(this);''', '''  void dispose() {
    _isInitialized = false;
    _readiness.value = false;
    WidgetsBinding.instance.removeObserver(this);''')

replace('lib/core/ads/ad_state.dart', '''    final consent = ref.watch(adServiceProvider).consentManager;
    void onConsentChanged() {
      state = state.copyWith(consentAllowsAds: consent.requestsAllowed);
    }

    consent.adsAllowed.addListener(onConsentChanged);
    ref.onDispose(() => consent.adsAllowed.removeListener(onConsentChanged));
    return AdState(consentAllowsAds: consent.requestsAllowed);''', '''    final service = ref.watch(adServiceProvider);
    final consent = service.consentManager;
    void onEligibilityChanged() {
      state = state.copyWith(consentAllowsAds: service.canServeAds);
    }

    consent.adsAllowed.addListener(onEligibilityChanged);
    service.readiness.addListener(onEligibilityChanged);
    ref.onDispose(() {
      consent.adsAllowed.removeListener(onEligibilityChanged);
      service.readiness.removeListener(onEligibilityChanged);
    });
    return AdState(consentAllowsAds: service.canServeAds);''')

path = 'lib/core/startup/startup_status_app.dart'
replace(path, '''    final failed = errorMessage != null;''', '''    final failed = errorMessage != null;
    final theme = ThemeData.dark();
    final colors = theme.colorScheme;''')
replace(path, 'theme: ThemeData.dark(),', 'theme: theme,')
replace(path, '''      home: Scaffold(
        backgroundColor: const Color(0xFF1E1E2C),''', '''      // No Navigator: preserve incoming web paths, queries and OAuth links.
      builder: (context, _) => Scaffold(
        backgroundColor: colors.surface,''')
replace(path, '''                    const Icon(''', '''                    Icon(''')
replace(path, 'color: Color(0xFFFFB74D),', 'color: colors.error,')
replace(path, '''                      style: const TextStyle(
                        color: Colors.white,''', '''                      style: TextStyle(
                        color: colors.onSurface,''')
replace(path, 'style: const TextStyle(color: Colors.white, fontSize: 15),', 'style: TextStyle(color: colors.onSurface, fontSize: 15),')
replace(path, 'backgroundColor: const Color(0xFF6C5CE7),', 'backgroundColor: colors.primary,')
replace(path, 'foregroundColor: Colors.white,', 'foregroundColor: colors.onPrimary,')
replace('scripts/check_color_literals.mjs', '  "lib/main.dart": 2\n', '')
