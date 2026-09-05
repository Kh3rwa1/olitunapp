# Changelog

All notable changes to Olitun will be documented in this file.

This project uses conventional commits and release-please to keep release notes
and tags consistent.

## [1.4.0](https://github.com/Kh3rwa1/olitunapp/compare/olitun-v1.3.0...olitun-v1.4.0) (2026-09-05)


### Features

* 3-section multilingual layout & fix quiz skip blank screen ([#205](https://github.com/Kh3rwa1/olitunapp/issues/205)) ([56de77b](https://github.com/Kh3rwa1/olitunapp/commit/56de77b5a944aaca00af0518abfe54ad94c74a5f))
* **a11y:** full Santali l10n parity, WCAG AA semantics, 48dp tap targets, and CI parity gate (#Phase3) ([#197](https://github.com/Kh3rwa1/olitunapp/issues/197)) ([f689913](https://github.com/Kh3rwa1/olitunapp/commit/f68991390d66880e4f475a1b53250f9baae59cc8))
* **admin:** enhance multilingual UI/UX with dedicated Bengali & Indic translations manager and live previews ([#210](https://github.com/Kh3rwa1/olitunapp/issues/210)) ([2febfe4](https://github.com/Kh3rwa1/olitunapp/commit/2febfe46913704a9df9d52c05d2e4105348a05cb))
* **admin:** phase 5 admin content review workflow ([#187](https://github.com/Kh3rwa1/olitunapp/issues/187)) ([9f5561f](https://github.com/Kh3rwa1/olitunapp/commit/9f5561f9cfc805599439c7379d7af8280dd0c323))
* **audio:** add Sarvam AI audio for all 14 vocabulary decks (307 blocks) and sync to Appwrite ([#175](https://github.com/Kh3rwa1/olitunapp/issues/175)) ([58aa7b8](https://github.com/Kh3rwa1/olitunapp/commit/58aa7b8f72c369feebf1e9a871d92f19238a1750))
* **audio:** complete 100% Sarvam AI audio generation for all 415 words and 250 sentences ([#176](https://github.com/Kh3rwa1/olitunapp/issues/176)) ([9b75e9a](https://github.com/Kh3rwa1/olitunapp/commit/9b75e9a472e2456aa62ffa9f681f42b93009c930))
* **audio:** integrate Sarvam AI audio across all sentence lessons, grammar decks, stories and resilient web player ([#174](https://github.com/Kh3rwa1/olitunapp/issues/174)) ([1de10ac](https://github.com/Kh3rwa1/olitunapp/commit/1de10acc3cc2fb2547b563f8bce53901a98717ae))
* **audio:** Sarvam TTS generation function (Phase 4) — server-side teaching-language audio with idempotency and review gating ([#186](https://github.com/Kh3rwa1/olitunapp/issues/186)) ([0e0f96d](https://github.com/Kh3rwa1/olitunapp/commit/0e0f96dbc1f0198e07cdcb665dbec5ffc4ceedfa))
* **audio:** unified playback controller, audio track data layer, and AudioBundle playback chain ([#185](https://github.com/Kh3rwa1/olitunapp/issues/185)) ([3469245](https://github.com/Kh3rwa1/olitunapp/commit/34692451377f25dcb0bae7a0bc79201ef538a9fc))
* **auth,notifications:** mandatory login without skip and multi-slot habit reminders (1.3.0+24) ([#245](https://github.com/Kh3rwa1/olitunapp/issues/245)) ([d76b6a5](https://github.com/Kh3rwa1/olitunapp/commit/d76b6a5e70a5079486c51a122fe14508dae0b935))
* **ci:** add ratcheting 600-line gate and decompose learner-facing trio ([#191](https://github.com/Kh3rwa1/olitunapp/issues/191)) ([1a20a78](https://github.com/Kh3rwa1/olitunapp/commit/1a20a783e65bacabd6bcd4c743ef0b3c6787c2ef))
* close the 10/10 gap — a11y depth, shared-layer l10n, anti-farming, review-unlock removal ([#224](https://github.com/Kh3rwa1/olitunapp/issues/224)) ([59e267a](https://github.com/Kh3rwa1/olitunapp/commit/59e267a75c84888711b2a22177d066179cdbdea6))
* complete Indic transliteration engine with aspirated digraphs and zero-leakage language isolation ([#204](https://github.com/Kh3rwa1/olitunapp/issues/204)) ([e8f5e4e](https://github.com/Kh3rwa1/olitunapp/commit/e8f5e4e16881a5d4066bebfe3fbd6e10702724fa))
* **content:** integrate Sarvam AI audio, folktales, 250 sentences, 415 words, and profile UI fixes ([#173](https://github.com/Kh3rwa1/olitunapp/issues/173)) ([5fb9999](https://github.com/Kh3rwa1/olitunapp/commit/5fb999971ef6f71366a3717b1e55503f9c58f0f6))
* **content:** phase 6 segment-based stories and offline downloads ([#164](https://github.com/Kh3rwa1/olitunapp/issues/164)) ([cd5690e](https://github.com/Kh3rwa1/olitunapp/commit/cd5690e7c69da51ceb275672090a03b98dbbea90))
* **design-system:** add Santali cultural palette, semantic duo migration, WCAG contrast suite, and docs/DESIGN_SYSTEM.md (#PR2.3) ([#196](https://github.com/Kh3rwa1/olitunapp/issues/196)) ([96ba376](https://github.com/Kh3rwa1/olitunapp/commit/96ba37666b15a5543139418ca5f90bc535599ef2))
* **design-tokens:** add spacing/radius tokens, semantic color migration, and color literal CI gate (#PR2.2) ([#195](https://github.com/Kh3rwa1/olitunapp/issues/195)) ([516079f](https://github.com/Kh3rwa1/olitunapp/commit/516079f2f9e71939dbfc028864d888706e614989))
* google sheet automated affirmation sync and wisdom UI cleanup ([#137](https://github.com/Kh3rwa1/olitunapp/issues/137)) ([3a7d68c](https://github.com/Kh3rwa1/olitunapp/commit/3a7d68c4e575168c305f165f834dca76c1068b7e))
* **growth:** viral social share cards, milestone sharing, modular badges grid, and file length ratchet (Phase 5) ([#199](https://github.com/Kh3rwa1/olitunapp/issues/199)) ([d016e8a](https://github.com/Kh3rwa1/olitunapp/commit/d016e8a9cbaccc342e4786e2a3c18405189da238))
* **hardening:** atomic rate limiting, verified identity, cache-first SWR, fail-closed signing & action pinning ([#132](https://github.com/Kh3rwa1/olitunapp/issues/132)) ([a179efa](https://github.com/Kh3rwa1/olitunapp/commit/a179efaa604982786e42c8197ffc7e9dbdeaf5ed))
* **hardening:** production hardening for priorities 0A, 0B, 1A, and 1B ([#258](https://github.com/Kh3rwa1/olitunapp/issues/258)) ([65ed919](https://github.com/Kh3rwa1/olitunapp/commit/65ed91960919fa03a5042718da4e67c3583d5001))
* **i18n:** multilingual foundation — language axes, onboarding v2, hi/bn/or locales ([#183](https://github.com/Kh3rwa1/olitunapp/issues/183)) ([6eeb59b](https://github.com/Kh3rwa1/olitunapp/commit/6eeb59bdd11b2621949cfce397cc8ab0469b9b1a))
* **languages:** multi-language engine platform play, script metadata registry, and indigenous languages showcase (Phase 6) ([#200](https://github.com/Kh3rwa1/olitunapp/issues/200)) ([c257600](https://github.com/Kh3rwa1/olitunapp/commit/c25760078ba099ff686282d6b470c20745b8aa9e))
* localized content & audio schema (Phase 2) ([#184](https://github.com/Kh3rwa1/olitunapp/issues/184)) ([0d948ce](https://github.com/Kh3rwa1/olitunapp/commit/0d948ceeb97bc0a39820ad2f05ec484842c22948))
* **monetization:** add ads to lesson blocks player, content grid, quiz list, and increase timeline ad frequency ([#169](https://github.com/Kh3rwa1/olitunapp/issues/169)) ([a596c78](https://github.com/Kh3rwa1/olitunapp/commit/a596c78ec6a0486c753ffb352a63caede94303f2))
* **monetization:** add native ad between Today's Wisdom and Start Here card ([#167](https://github.com/Kh3rwa1/olitunapp/issues/167)) ([067f44f](https://github.com/Kh3rwa1/olitunapp/commit/067f44fda84d29a3ea9060906b1ada9c7d3e43ce))
* **monetization:** add Native Ads to Quiz Complete, Out of Hearts, Mistake Reviews, Paywall & Binti Guru ([#170](https://github.com/Kh3rwa1/olitunapp/issues/170)) ([64cc520](https://github.com/Kh3rwa1/olitunapp/commit/64cc5202a858b36bae96a8428ca17a4f8b7d7cb7))
* **monetization:** add native and banner ads across all screens (lesson timeline, content details, translator, profile, settings, rhymes) ([#168](https://github.com/Kh3rwa1/olitunapp/issues/168)) ([f8eac51](https://github.com/Kh3rwa1/olitunapp/commit/f8eac5190d4e12c046f27929e6855f8cace33edc))
* **monetization:** Google AdMob monetization integration ([#165](https://github.com/Kh3rwa1/olitunapp/issues/165)) ([956682f](https://github.com/Kh3rwa1/olitunapp/commit/956682f4ec8e9cc4e14f34e417ef5fdf72e3cef9))
* **monetization:** maximize Home Screen ad revenue with multiple native ads & sticky banner ([#166](https://github.com/Kh3rwa1/olitunapp/issues/166)) ([462835f](https://github.com/Kh3rwa1/olitunapp/commit/462835f7eabfa820a9ae1702728634c522c02e0a))
* **monetization:** modular paywall architecture, file length ratchet, and comprehensive testing suite (Phase 4) ([#198](https://github.com/Kh3rwa1/olitunapp/issues/198)) ([f0690bc](https://github.com/Kh3rwa1/olitunapp/commit/f0690bc3b598c0af4ddd8dcf3a3ac17dcbc0791f))
* multilingual Indic script transliteration and audio-loaded quiz engine ([#203](https://github.com/Kh3rwa1/olitunapp/issues/203)) ([733cd2a](https://github.com/Kh3rwa1/olitunapp/commit/733cd2aab31c55cbfbc162a3d46e1b72e238d6d5))
* **notifications:** add offline daily streak and habit reminders ([#241](https://github.com/Kh3rwa1/olitunapp/issues/241)) ([dacfad4](https://github.com/Kh3rwa1/olitunapp/commit/dacfad4b5c935ed06c33f7ba8f76743cfd6aa561))
* **observability:** add telemetry ring buffer, diagnostics sheet and health tooling (Phase 7) ([#201](https://github.com/Kh3rwa1/olitunapp/issues/201)) ([b8359f0](https://github.com/Kh3rwa1/olitunapp/commit/b8359f077f7deb1517621a33d99cb0a954766f10))
* **observability:** configure Sentry DSN, preconnect, and build defaults ([#240](https://github.com/Kh3rwa1/olitunapp/issues/240)) ([aab0f11](https://github.com/Kh3rwa1/olitunapp/commit/aab0f1159c64ccbcf2cadd9ed89c529fb53aa3d2))
* **observability:** scrub PII from Sentry events before upload ([#238](https://github.com/Kh3rwa1/olitunapp/issues/238)) ([cfc9aaa](https://github.com/Kh3rwa1/olitunapp/commit/cfc9aaa0140fdfdaac4a5ed38c14d097f95bf012))
* **onboarding:** AAA agency redesign — ambient canvas, staggered cards, segmented progress ([#236](https://github.com/Kh3rwa1/olitunapp/issues/236)) ([f8f0a59](https://github.com/Kh3rwa1/olitunapp/commit/f8f0a591b05780748f5227deaff42e77f80340d8))
* **onboarding:** enforce mandatory learning language selection and enhance walkthrough UX ([#230](https://github.com/Kh3rwa1/olitunapp/issues/230)) ([5d9737d](https://github.com/Kh3rwa1/olitunapp/commit/5d9737dd4960d9180dc581493f62f872ecdc3d9c))
* **onboarding:** set Santali as permanent indigenous language and enforce mandatory mother tongue selection ([#231](https://github.com/Kh3rwa1/olitunapp/issues/231)) ([16b4cea](https://github.com/Kh3rwa1/olitunapp/commit/16b4cea23ba4e4cd7c579e3bc743e36328a75e4e))
* **profile:** localize streak strings, real quiz titles, milestone dedup, idle pulse ([#151](https://github.com/Kh3rwa1/olitunapp/issues/151)) ([d736ba2](https://github.com/Kh3rwa1/olitunapp/commit/d736ba26b899fe649ad31fa90811e1e5b81c304a))
* **pwa:** elevate PWA to AAA+ standard with dark mode splash, rich manifest, live update toast, and smart install prompt ([#212](https://github.com/Kh3rwa1/olitunapp/issues/212)) ([e1952ce](https://github.com/Kh3rwa1/olitunapp/commit/e1952ce839fbe1b258df4ab0457acd4b04b71b6d))
* **quiz:** phase 7 audio quizzes and learning paths ([#188](https://github.com/Kh3rwa1/olitunapp/issues/188)) ([7893bc7](https://github.com/Kh3rwa1/olitunapp/commit/7893bc71a623a12e9b6feea69d6e9ff6d4f4d626))
* **typography:** consolidate to bundled Inter and OlChiki variable fonts and add CI gate ([#193](https://github.com/Kh3rwa1/olitunapp/issues/193)) ([#194](https://github.com/Kh3rwa1/olitunapp/issues/194)) ([6db0eb7](https://github.com/Kh3rwa1/olitunapp/commit/6db0eb772b9c4b6c5d93349e816712554090369b))
* **ui:** spring + stagger motion system across core screens ([#227](https://github.com/Kh3rwa1/olitunapp/issues/227)) ([5666b6c](https://github.com/Kh3rwa1/olitunapp/commit/5666b6c367f2f3679b42ffaba3a828723a873637))
* unlock 100% free learning access and elevate content and UI to 10/10 ([#171](https://github.com/Kh3rwa1/olitunapp/issues/171)) ([322b93e](https://github.com/Kh3rwa1/olitunapp/commit/322b93e99bbc700d6b058d461584b9262348abd9))


### Bug Fixes

* **a11y:** single-tappable CTA and silent decorative result icons ([#265](https://github.com/Kh3rwa1/olitunapp/issues/265)) ([a85bef3](https://github.com/Kh3rwa1/olitunapp/commit/a85bef39a0f26da749d4dc87445f58daecf33e19))
* **admin, affirmations:** finalize 10/10 financial metrics, truthful refunds, and browser affirmation sharing ([#140](https://github.com/Kh3rwa1/olitunapp/issues/140)) ([b24aac1](https://github.com/Kh3rwa1/olitunapp/commit/b24aac1cd27a26b1af2b9e9e548a78760f067c9b))
* **admin:** 10/10 production hardening for purchases, refunds, pagination, csv export, and affirmation sharing ([#141](https://github.com/Kh3rwa1/olitunapp/issues/141)) ([b16e2eb](https://github.com/Kh3rwa1/olitunapp/commit/b16e2ebfe225fcd6db455cbe5d712ec3733a2cc4))
* **admin:** 10/10 production hardening for purchases, refunds, responsive tables, and web sharing ([#142](https://github.com/Kh3rwa1/olitunapp/issues/142)) ([b492218](https://github.com/Kh3rwa1/olitunapp/commit/b492218c30fdb0c256fd502d605acaee0d61e3e2))
* **admin:** finalize 10-of-10 reliability, revenue metrics, safe CSV, and accessibility ([#139](https://github.com/Kh3rwa1/olitunapp/issues/139)) ([5921a00](https://github.com/Kh3rwa1/olitunapp/commit/5921a0011ee284e516be240ec487d81d43fb189f))
* **android:** target SDK 36, bump version code 21, and include native debug symbols ([#237](https://github.com/Kh3rwa1/olitunapp/issues/237)) ([cf9ddea](https://github.com/Kh3rwa1/olitunapp/commit/cf9ddead64defaed082b13d6bff8f1c7eaa5f4a3))
* **audio:** add proguard keep rules for just_audio/exoplayer and harden AudioService with MediaItem tags ([#179](https://github.com/Kh3rwa1/olitunapp/issues/179)) ([04cec0b](https://github.com/Kh3rwa1/olitunapp/commit/04cec0b3a9afc61f2b206be26eb5b81626447315))
* **audio:** add web cross-origin and HTML5 audio fallback, bump cache schema version to 5 ([#178](https://github.com/Kh3rwa1/olitunapp/issues/178)) ([8a413d1](https://github.com/Kh3rwa1/olitunapp/commit/8a413d184e515ddaf51e82440ac36db07e4ee821))
* **audio:** dismiss stuck media notification after short clips finish ([#225](https://github.com/Kh3rwa1/olitunapp/issues/225)) ([1e866cd](https://github.com/Kh3rwa1/olitunapp/commit/1e866cdd8b180ee84548f76bca5b461f55062c5f))
* **audio:** preserve audioUrl in content block models and bundled seeds ([#177](https://github.com/Kh3rwa1/olitunapp/issues/177)) ([e06d652](https://github.com/Kh3rwa1/olitunapp/commit/e06d6521aff4b48593852c22e0c8424fc488d0a3))
* **auth:** mobile Google login exchanges token callback for a real session ([#234](https://github.com/Kh3rwa1/olitunapp/issues/234)) ([e7df4a7](https://github.com/Kh3rwa1/olitunapp/commit/e7df4a78723026522e987b3f74ffd696154baf89))
* **auth:** resilient account deletion and production endpoint defaults ([#242](https://github.com/Kh3rwa1/olitunapp/issues/242)) ([e39ae8f](https://github.com/Kh3rwa1/olitunapp/commit/e39ae8fd26981385948b4536f4e402d5271a09a0))
* **auth:** resolve stuck login screen by refreshing auth state and wiring router refreshListenable (1.3.0+25) ([#246](https://github.com/Kh3rwa1/olitunapp/issues/246)) ([b0c9ab2](https://github.com/Kh3rwa1/olitunapp/commit/b0c9ab25358a6765d61466602d03513c32ebe386))
* **auth:** set local session flag upon mobile OAuth and OTP session creation ([#229](https://github.com/Kh3rwa1/olitunapp/issues/229)) ([e6ff13d](https://github.com/Kh3rwa1/olitunapp/commit/e6ff13d12a1a8afcb9071dfde9d92eb8218ca16a))
* **auth:** switch to token OAuth on web and persist active session secret ([#228](https://github.com/Kh3rwa1/olitunapp/issues/228)) ([52ee553](https://github.com/Kh3rwa1/olitunapp/commit/52ee553c1c8fca35938b62a865a986d887f9a895))
* **bakhed:** curated featured, robust categories, cover-art fallback, heard badge ([#152](https://github.com/Kh3rwa1/olitunapp/issues/152)) ([71bd753](https://github.com/Kh3rwa1/olitunapp/commit/71bd7537cf80f2248eea11544ef35013ba07f654))
* **compat,recovery:** dual-write ledger wire format and subsumed refund resume ([#270](https://github.com/Kh3rwa1/olitunapp/issues/270)) ([0e0730f](https://github.com/Kh3rwa1/olitunapp/commit/0e0730f66c2e596305b7fca1a255255f6adcf7de))
* **content:** enforce premium lesson publication boundary ([#256](https://github.com/Kh3rwa1/olitunapp/issues/256)) ([6de56f4](https://github.com/Kh3rwa1/olitunapp/commit/6de56f45e3a2a0f89f7695ef2f7cbd21dc3659e1))
* **content:** resolve multilingual meaning and transliteration in content hero and vocab ([#209](https://github.com/Kh3rwa1/olitunapp/issues/209)) ([adb5646](https://github.com/Kh3rwa1/olitunapp/commit/adb56468f9fe985b74ea8f5b93d534417ff243b7))
* **core:** provide resilient production defaults in AppwriteConfig for APK startup ([#211](https://github.com/Kh3rwa1/olitunapp/issues/211)) ([6388dd8](https://github.com/Kh3rwa1/olitunapp/commit/6388dd8f45865dfe0e5eaddb8debb9cdf66cdbfb))
* **crdt:** implement vector checkpoint CRDT for progress compaction and recoverable admin refund state machine ([#260](https://github.com/Kh3rwa1/olitunapp/issues/260)) ([d0ab233](https://github.com/Kh3rwa1/olitunapp/commit/d0ab23390c2569556e562874f9936ccacdda4cad))
* e2e test runner, node-appwrite SDK alignment, signing verification, and release gates ([#134](https://github.com/Kh3rwa1/olitunapp/issues/134)) ([f7a0f12](https://github.com/Kh3rwa1/olitunapp/commit/f7a0f129030c442d5d68f7a46b53cbaf1cb6e7f6))
* **first-session:** localized continue action and explained quiz recovery states ([#262](https://github.com/Kh3rwa1/olitunapp/issues/262)) ([d43ed6d](https://github.com/Kh3rwa1/olitunapp/commit/d43ed6db32641a41592f6a9b7407efd7a17c3330))
* harden checkout, account deletion, and offline queue isolation ([#247](https://github.com/Kh3rwa1/olitunapp/issues/247)) ([3f4010d](https://github.com/Kh3rwa1/olitunapp/commit/3f4010ddb727063929f5b089625455d5e52e683f))
* harden consent, offline sync, entitlements and release checks ([#250](https://github.com/Kh3rwa1/olitunapp/issues/250)) ([a88217a](https://github.com/Kh3rwa1/olitunapp/commit/a88217a869afb1d8861d4f73ce60e2f76620cd24))
* harden deletion, payment reporting, quiz rewards and lesson recovery ([#249](https://github.com/Kh3rwa1/olitunapp/issues/249)) ([b6394a7](https://github.com/Kh3rwa1/olitunapp/commit/b6394a7824beaba1f01f50cf70bf8e8a0859c523))
* **home:** affirmation share screenshot dead in release builds ([#160](https://github.com/Kh3rwa1/olitunapp/issues/160)) ([6f2e46c](https://github.com/Kh3rwa1/olitunapp/commit/6f2e46c5435716917d63b1adf9f88d29d5344fa7))
* **home:** truthful audio state, in-flow offline banner, l10n, persona, all-done state ([#153](https://github.com/Kh3rwa1/olitunapp/issues/153)) ([90aab43](https://github.com/Kh3rwa1/olitunapp/commit/90aab43bd43fd1895dfbc8cf586b8d36dd598b7f))
* **i18n:** eliminate English leakage in non-English learning modes across sentences and vocabulary ([#213](https://github.com/Kh3rwa1/olitunapp/issues/213)) ([2db67dc](https://github.com/Kh3rwa1/olitunapp/commit/2db67dc7c1491e795820a6f7f7456eb0b0ee4245))
* improve learning UX, accessibility, and performance evaluation ([#248](https://github.com/Kh3rwa1/olitunapp/issues/248)) ([7b6dc70](https://github.com/Kh3rwa1/olitunapp/commit/7b6dc70e48c2235742817dd008132c09704f2b36))
* **integration:** dynamically match prompts and ensureVisible before tap in Quiz flow E2E ([#135](https://github.com/Kh3rwa1/olitunapp/issues/135)) ([3665f90](https://github.com/Kh3rwa1/olitunapp/commit/3665f90c8305ae1d76db1c90c410715d7e5ff130))
* **logic:** correct data-loss, quiz-integrity, star-economy and WCAG bugs ([#218](https://github.com/Kh3rwa1/olitunapp/issues/218)) ([aad1347](https://github.com/Kh3rwa1/olitunapp/commit/aad134750fe5919d363d3c68f22da6f6391559ee))
* **offline:** verify download files exist before reporting them ([#264](https://github.com/Kh3rwa1/olitunapp/issues/264)) ([f99f892](https://github.com/Kh3rwa1/olitunapp/commit/f99f8920e63a5ee14de1818d5b767c48248c026e))
* **onboarding:** resume legacy flow from persisted draft after interruption ([#263](https://github.com/Kh3rwa1/olitunapp/issues/263)) ([fb22665](https://github.com/Kh3rwa1/olitunapp/commit/fb2266545303e2ffaaac1a0bf0af02074b08dad8))
* **onboarding:** skip path, restart resume, slimmer step 5 ([#233](https://github.com/Kh3rwa1/olitunapp/issues/233)) ([d5ac9b0](https://github.com/Kh3rwa1/olitunapp/commit/d5ac9b07da6edb6e947e324554a48a16d8ae3e85))
* **payments:** disable unsafe refund writes and contain stale disputes ([#257](https://github.com/Kh3rwa1/olitunapp/issues/257)) ([ed98cae](https://github.com/Kh3rwa1/olitunapp/commit/ed98cae85ee193c7ce454edf85b07944cb2fa953))
* **payments:** guard entitlement transitions against stale callbacks and races ([#252](https://github.com/Kh3rwa1/olitunapp/issues/252)) ([72d7b56](https://github.com/Kh3rwa1/olitunapp/commit/72d7b56361b84123bc6d18f7e999fb494a65b339))
* **profile,payments:** bind persistent origin sequences to progress events and guarantee atomic refund recovery ([#261](https://github.com/Kh3rwa1/olitunapp/issues/261)) ([c363d2f](https://github.com/Kh3rwa1/olitunapp/commit/c363d2f0b2eb7106c445c26d3ea6f5aeda835951))
* **profile:** honest streak states, calendar-week strip, nav scrim and a11y ([#145](https://github.com/Kh3rwa1/olitunapp/issues/145)) ([121c18e](https://github.com/Kh3rwa1/olitunapp/commit/121c18e545ccbf6ce60dd7899ec0ca7683412386))
* **profile:** real member-since, day detail sheet, milestone clarity ([#150](https://github.com/Kh3rwa1/olitunapp/issues/150)) ([8023f8d](https://github.com/Kh3rwa1/olitunapp/commit/8023f8dc5aa3f4e054e11924abda28325a581a78))
* **progress:** folded-ledger merge with contiguous checkpoints ([#268](https://github.com/Kh3rwa1/olitunapp/issues/268)) ([2a7891f](https://github.com/Kh3rwa1/olitunapp/commit/2a7891f6eac8dea1b8da99df9c1c549772f2f260))
* **progress:** make resets survive cloud synchronization ([#254](https://github.com/Kh3rwa1/olitunapp/issues/254)) ([b7e18f5](https://github.com/Kh3rwa1/olitunapp/commit/b7e18f51501efb03ba4c636ade0958078e18ad20))
* **quiz:** fix audio desynchronization and support multilingual quiz display ([#226](https://github.com/Kh3rwa1/olitunapp/issues/226)) ([9863710](https://github.com/Kh3rwa1/olitunapp/commit/9863710a51db78f38b0a2d96b09856934474a038))
* **quiz:** prevent bottom overflow and fix vertical squished text in quiz feedback panel ([#172](https://github.com/Kh3rwa1/olitunapp/issues/172)) ([a79d783](https://github.com/Kh3rwa1/olitunapp/commit/a79d783b39f558ce20e3da14c474c00d11b77c85))
* **quiz:** prevent question card answer spoiler, polish out-of-hearts UI, and fix review mistakes layout ([#244](https://github.com/Kh3rwa1/olitunapp/issues/244)) ([ef642c2](https://github.com/Kh3rwa1/olitunapp/commit/ef642c22b3062b1b9d8ef93250b0d9e5eadf973e))
* real atomic slot reservation rate limit and e2e release gates ([#133](https://github.com/Kh3rwa1/olitunapp/issues/133)) ([0beed0d](https://github.com/Kh3rwa1/olitunapp/commit/0beed0dfb53e19d71a3e3b10ba93a7318336347b))
* **refunds:** operation identity, recovery guarantees, and admin recording workflow ([#269](https://github.com/Kh3rwa1/olitunapp/issues/269)) ([390b96d](https://github.com/Kh3rwa1/olitunapp/commit/390b96df57a7b30856e25d372c7af44a99642241))
* **release:** require cert fingerprint, tag tested commits, and handle staging secrets ([#136](https://github.com/Kh3rwa1/olitunapp/issues/136)) ([0827882](https://github.com/Kh3rwa1/olitunapp/commit/0827882206efba771f11b4791fbbc8028da29ef1))
* resolve complete multilingual translation dictionaries across all sentences and words ([#208](https://github.com/Kh3rwa1/olitunapp/issues/208)) ([ac6e554](https://github.com/Kh3rwa1/olitunapp/commit/ac6e554f8f03e17832b0651cb356098d83fde27f))
* sanitize multilingual lesson blocks, eliminate rigid box, and isolate Indic languages ([#207](https://github.com/Kh3rwa1/olitunapp/issues/207)) ([07d0b53](https://github.com/Kh3rwa1/olitunapp/commit/07d0b53a8b218d77bf48514f0e72231733c9f9a6))
* **security,payments,ci:** resolve P1/P2 web session security, stale cache fallback, version drift & CI gating ([#124](https://github.com/Kh3rwa1/olitunapp/issues/124)) ([cd13202](https://github.com/Kh3rwa1/olitunapp/commit/cd132026e23c9dc45a04cad01793616d49e38f0c))
* **security:** resolve production-hardening authorization, compaction, dispute, and refund defects ([#259](https://github.com/Kh3rwa1/olitunapp/issues/259)) ([a3dd34c](https://github.com/Kh3rwa1/olitunapp/commit/a3dd34c435614d9b380e856457cc19e85dfe4f6d))
* **sync:** support request header key and default fallback endpoint/project ([#138](https://github.com/Kh3rwa1/olitunapp/issues/138)) ([c1e1b46](https://github.com/Kh3rwa1/olitunapp/commit/c1e1b465db3c4ead02e1572e45b94949ed63990b))
* **translator:** execute via SDK with session auth + real function id ([#162](https://github.com/Kh3rwa1/olitunapp/issues/162)) ([fb453f7](https://github.com/Kh3rwa1/olitunapp/commit/fb453f7a284733a578034873c9cd44cf252457c7))
* **translator:** free unlimited translation; restore app response shape ([#221](https://github.com/Kh3rwa1/olitunapp/issues/221)) ([4386e3c](https://github.com/Kh3rwa1/olitunapp/commit/4386e3c94f85c23f4ce4e47091eef59450c60ff4))
* **translator:** self-heal legacy cache rows that returned empty translations ([#222](https://github.com/Kh3rwa1/olitunapp/issues/222)) ([37abda4](https://github.com/Kh3rwa1/olitunapp/commit/37abda48d158cb029dfd2043b96946c7777a301b))
* **ui:** contrast + text-scale hardening across learner surfaces ([#232](https://github.com/Kh3rwa1/olitunapp/issues/232)) ([4207f2e](https://github.com/Kh3rwa1/olitunapp/commit/4207f2e5c19b06b5dd7b69f479fc1c9e4f364a88))
* **ui:** remove debug TEXT type badge from lesson detail hero header ([#206](https://github.com/Kh3rwa1/olitunapp/issues/206)) ([ad37ce0](https://github.com/Kh3rwa1/olitunapp/commit/ad37ce09cd711b5233dbcc6a3036b56799186629))
* **web:** restore trusted media playback policy and category accessibility ([#255](https://github.com/Kh3rwa1/olitunapp/issues/255)) ([1c12bbd](https://github.com/Kh3rwa1/olitunapp/commit/1c12bbd24d03b826697f0769de418c2364aa9054))
* **web:** support direct /admin and hash #/admin routing without welcome redirect ([#235](https://github.com/Kh3rwa1/olitunapp/issues/235)) ([f8c0948](https://github.com/Kh3rwa1/olitunapp/commit/f8c09483d0c15f38f5d3597588aba3304fd38728))


### Performance Improvements

* bundle Google Fonts locally, decode-cap cover images ([#163](https://github.com/Kh3rwa1/olitunapp/issues/163)) ([d6f090e](https://github.com/Kh3rwa1/olitunapp/commit/d6f090e11088fcfe2b98f7c394bceee91104acc6))

## [1.3.0](https://github.com/Kh3rwa1/olitunapp/compare/olitun-v1.2.2...olitun-v1.3.0) (2026-08-09)


### Features

* **hardening:** raise whole app to 10/10 engineering standard with encrypted account-deletion recovery ([#118](https://github.com/Kh3rwa1/olitunapp/pull/118)) ([6dce98f](https://github.com/Kh3rwa1/olitunapp/commit/6dce98f39bc21eab4c20708a41151a517e34fb43))
* **security,auth,ci:** complete 10/10 hardening, fail-closed auth, and release gates ([#116](https://github.com/Kh3rwa1/olitunapp/issues/116)) ([a3195d6](https://github.com/Kh3rwa1/olitunapp/commit/a3195d6e493f3d740a78e217ac4ad5e2effb4ab4))

## [1.2.2](https://github.com/Kh3rwa1/olitunapp/compare/olitun-v1.2.1...olitun-v1.2.2) (2026-08-09)


### Bug Fixes

* **auth/ci:** complete auth service client tests, branch protection docs, and workflow cleanup ([#114](https://github.com/Kh3rwa1/olitunapp/issues/114)) ([2574735](https://github.com/Kh3rwa1/olitunapp/commit/25747355b8fae110ee8cb27763e1e812cf1abe51))

## [1.2.1](https://github.com/Kh3rwa1/olitunapp/compare/olitun-v1.2.0...olitun-v1.2.1) (2026-08-09)


### Bug Fixes

* **hardening:** close final auth session and lesson cache gaps ([c6878f5](https://github.com/Kh3rwa1/olitunapp/commit/c6878f5ae4a70ef06024d05e2b55501721a33b9f))

## [1.2.0](https://github.com/Kh3rwa1/olitunapp/compare/olitun-v1.1.1...olitun-v1.2.0) (2026-08-09)


### Features

* add admin access management ([79f22d1](https://github.com/Kh3rwa1/olitunapp/commit/79f22d1242ce39149ebb4b83bcf94b5a18cef21a))
* add Browse All card to Alphabets and Numbers category screens ([ee842c1](https://github.com/Kh3rwa1/olitunapp/commit/ee842c19ec35a0e7273aeac5f3f4533b5f4fecb6))
* add database cleanup tool for duplicate letters and numbers ([0617567](https://github.com/Kh3rwa1/olitunapp/commit/061756766fa934f7e032bdfe38ad602b68158328))
* add learning analytics events ([ee1c831](https://github.com/Kh3rwa1/olitunapp/commit/ee1c831f91277887ac7f81fca2947481b3e744ae))
* add meta passthrough to ContentBlock, fix rich media save & format ([42365a2](https://github.com/Kh3rwa1/olitunapp/commit/42365a270c28559402bdd41f816271709176eab4))
* **admin:** add ContentTypeBadge overlay to Bakhed hub cover thumbnails ([73b46ba](https://github.com/Kh3rwa1/olitunapp/commit/73b46bae50db0f8cdeb9f3b2ec65f2f255a2dd74))
* **admin:** add ContentTypeBadge overlay to grid view cards ([b9167a1](https://github.com/Kh3rwa1/olitunapp/commit/b9167a1cbff10c9922af40b51c397507f346727f))
* **admin:** add ContentTypeBadge to AdminContentListScreen rows ([7e78beb](https://github.com/Kh3rwa1/olitunapp/commit/7e78bebfb36d3bdf5d9cfcc0a7b404dcb3968714))
* **admin:** add ContentTypeBadge to lesson block editor cards ([37e5d79](https://github.com/Kh3rwa1/olitunapp/commit/37e5d7914f7e75ec3281615c728cc5e7e743dcf9))
* **admin:** Add dedicated Add Category/Banner buttons and fix Purple color preset mapping ([4efda19](https://github.com/Kh3rwa1/olitunapp/commit/4efda19d741649151eb8fe9d30a9d49113cb53b8))
* **admin:** add learning analytics dashboard ([3eb442d](https://github.com/Kh3rwa1/olitunapp/commit/3eb442d2af4df1d4385be5ba2737bc8081cdc800))
* **admin:** dynamic sidebar, universal media uploader & centered max-width edit popups ([0e4fed6](https://github.com/Kh3rwa1/olitunapp/commit/0e4fed642dd0c1ef0dbcbde4ef049685700db23f))
* **admin:** enable CategoryCard tap-navigation, add Sentences option to CategoryFormSheet icons list ([7f396b4](https://github.com/Kh3rwa1/olitunapp/commit/7f396b467d78607a870294694eae72e9bff009c2))
* **admin:** implement ContentTypeBadge and resolver with tests ([b391a9d](https://github.com/Kh3rwa1/olitunapp/commit/b391a9d36f01fc452f8163322bd0c577cb0a17d1))
* **admin:** improve lesson management UX with search, labels, and breadcrumbs ([7d91428](https://github.com/Kh3rwa1/olitunapp/commit/7d91428b3552005604e887e89642130271aa07c1))
* **admin:** improve mobile responsiveness and auto-close sidebar drawer ([d5dbc94](https://github.com/Kh3rwa1/olitunapp/commit/d5dbc9409e79737a7fd100ee4b15c18e75ca71c1))
* **admin:** introduce CoverThumbnail widget for unified image and video cover rendering ([859f910](https://github.com/Kh3rwa1/olitunapp/commit/859f91062bedb2966f558f2033d805c07e1a9c75))
* **admin:** MaterialBanner and destructive action guard for stale builds ([9f76c3d](https://github.com/Kh3rwa1/olitunapp/commit/9f76c3d809178d130b58bc2f16a95a49406068e5))
* **admin:** migrate hub and CMS list cards to CoverThumbnail widget ([f365ae8](https://github.com/Kh3rwa1/olitunapp/commit/f365ae81fe9df17476d1018c797d9882c11d7fe3))
* **admin:** polish admin grid parity and add QoL missing status dots ([84dbe31](https://github.com/Kh3rwa1/olitunapp/commit/84dbe315ba7349593f3b04931c9e5c8baf496a82))
* **admin:** polish analytics dashboard controls ([b026492](https://github.com/Kh3rwa1/olitunapp/commit/b02649224be82f167551c782632cbf7ed4d7687b))
* **admin:** premium admin panel overhaul with B startup aesthetics ([f1261b1](https://github.com/Kh3rwa1/olitunapp/commit/f1261b14ae3026c1707d22e6cf9571fa3f2f303a))
* **admin:** remove redundant general Lessons tab from sidebar ([3a00ae2](https://github.com/Kh3rwa1/olitunapp/commit/3a00ae23f38f3405ce2d4f7a6a81be0dc7591b96))
* **admin:** share analytics csv exports ([696c41f](https://github.com/Kh3rwa1/olitunapp/commit/696c41fb2fd47bfa6dea65c0f6c95f072c062ae7))
* **admin:** Unified premium glassmorphic redesign and universal media input field ([dc34680](https://github.com/Kh3rwa1/olitunapp/commit/dc346803a9ad4ce3bd9ea7b13f69717e54e67556))
* **admin:** Unify admin list screens and harden data-loss safeguards ([63f0cea](https://github.com/Kh3rwa1/olitunapp/commit/63f0cea1785c7862b844bb982722c898032c9327))
* **admin:** unify dynamic words/sentences subcategories management, enable tap selection, and remove block editor redirection ([fb74df1](https://github.com/Kh3rwa1/olitunapp/commit/fb74df13cddac66d00867925760fb0775d10e9aa))
* **admin:** unify terminology from Lessons to Subcategories for custom categories ([42a83a4](https://github.com/Kh3rwa1/olitunapp/commit/42a83a45e02cd5f20856b5a80881e7cc23461e58))
* **admin:** upgrade and simplify subcategory filtering and form creation flow ([a164a25](https://github.com/Kh3rwa1/olitunapp/commit/a164a256da81a1fa9603b72efd23deade90336c0))
* **admin:** upgrade lesson block editor to universal rich form ([32e6143](https://github.com/Kh3rwa1/olitunapp/commit/32e614345eaf3e913f24b61a67cf9c078da5f62d))
* **analytics:** wire learning events and rollups ([85fc0b3](https://github.com/Kh3rwa1/olitunapp/commit/85fc0b35acf42650c6f98a712ee19b749e62b710))
* **bakhed:** add updateCategory string-based controller method ([bf65737](https://github.com/Kh3rwa1/olitunapp/commit/bf6573798505bd6b09a35bb6417536eb909a5ffe))
* **bakhed:** editor state supports image/video cover switching with deferred deletion ([e0fbfaf](https://github.com/Kh3rwa1/olitunapp/commit/e0fbfaf16428a3f34d13415158a2ce182ee30454))
* **bakhed:** finalize audio playback and duration fixes ([57d5748](https://github.com/Kh3rwa1/olitunapp/commit/57d5748aa35a3c832660c56f485e8715880ac3d7))
* **bakhed:** propagate Appwrite error codes through repository layer ([d4fc8de](https://github.com/Kh3rwa1/olitunapp/commit/d4fc8de1907ae30afd1564f72ed453749e0a5c08))
* **bakhed:** propagate audio durationMs from MediaUploader to editor state ([f170216](https://github.com/Kh3rwa1/olitunapp/commit/f170216cc247762a884fffbdecc14412cdaa5701))
* **bakhed:** replace category dropdown with string-based autocomplete field ([f642bed](https://github.com/Kh3rwa1/olitunapp/commit/f642bedae86402e3b734b840b68d9063ea0436ad))
* **bakhed:** two-tab cover picker for image or video selection in editor ([5156969](https://github.com/Kh3rwa1/olitunapp/commit/5156969bb3d7fad9a8463c046a136e327722723f))
* complete weekly learning circles, mistake review, and badges implementation, update Appwrite setup script, and configure backend ([2a79809](https://github.com/Kh3rwa1/olitunapp/commit/2a79809ce90f8f97475b696009c023fdc3deaf98))
* configure Path URL Strategy and resolve OAuth redirect loop on Web ([d9bfb22](https://github.com/Kh3rwa1/olitunapp/commit/d9bfb22fe1ac9ee882d6fe2cef43c4588a1affbe))
* enhance CSV export schema and support exporting lesson blocks ([61e1232](https://github.com/Kh3rwa1/olitunapp/commit/61e1232c2d9cc6eedeeb4dfa8b3f5309b2ee9cc6))
* **gamified:** implement smart dynamic quiz mapping, glowing milestone styling lints, and vocab/sentence seeder expansions ([f583e1b](https://github.com/Kh3rwa1/olitunapp/commit/f583e1b956507604b252f168cedacabb2b8eecb4))
* harden gamification and learner progress systems ([433009e](https://github.com/Kh3rwa1/olitunapp/commit/433009e529d13a5f93a3dd3067bdb0da5e302bbf))
* **hardening:** 10/10 production hardening completed on hardening/production-10-of-10 ([4d8b398](https://github.com/Kh3rwa1/olitunapp/commit/4d8b398727b7effbb5c6f31a1cb690b3f2a4a59f))
* **home:** consolidate and throttle category list refreshes with HomePrefetchNotifier ([4ee9ed0](https://github.com/Kh3rwa1/olitunapp/commit/4ee9ed0c4ec035fec0c4d8ae0c11ff489c21a6a6))
* implement dynamic theme colors and premium UX refinements ([2dd2f60](https://github.com/Kh3rwa1/olitunapp/commit/2dd2f608dc667d28cfe5f06c71131ce3eda3bfd4))
* implement P0 secure payment flow, user-scoped entitlements, and app hardening (Phases 1-9) ([6bd46f8](https://github.com/Kh3rwa1/olitunapp/commit/6bd46f853935c08bd5f07da3f0a200a62df16e7a))
* implement targeted purge in words seeder and fix formatting ([9cfd080](https://github.com/Kh3rwa1/olitunapp/commit/9cfd080209ea4270f280088e7b0424cdee9d83ce))
* implement transparent anonymous session creation for guest mode to enable public read syncing on startup ([80144dd](https://github.com/Kh3rwa1/olitunapp/commit/80144dd00e251315f0cafc7b773d4f92acef5818))
* **infra:** update appwrite_setup and snapshot scripts for hardened payment collections and indexes ([335dc37](https://github.com/Kh3rwa1/olitunapp/commit/335dc373c3f2228bdce008bed60bab846c2d3bdf))
* **learn:** implement responsive bento grid layout and tiles ([f9f0554](https://github.com/Kh3rwa1/olitunapp/commit/f9f0554f23c7625db61e19fa345b1d83e4fa2646))
* **learn:** integrate opaque gesture detector for tracing navigation ([73d065d](https://github.com/Kh3rwa1/olitunapp/commit/73d065d375a1781c915c004003e47f258054ee27))
* **learn:** scaffold parameterized ContentGridScreen widget ([c323744](https://github.com/Kh3rwa1/olitunapp/commit/c323744edfd06ee131785f668a1abd7c12e0fddf))
* **learn:** wire immediate pronunciation audio play with haptics ([86fc892](https://github.com/Kh3rwa1/olitunapp/commit/86fc8927da6021294528e31b2be5dc1535965724))
* **lessons:** cinematic edge-to-edge media header and premium card animations ([98e9ef1](https://github.com/Kh3rwa1/olitunapp/commit/98e9ef16c122bc61a31318fdad2fd52a9ff3c4df))
* **lessons:** dynamic color decoration for Quiz Blocks based on category brand colors ([0999548](https://github.com/Kh3rwa1/olitunapp/commit/0999548fdaf889896a775af6f3457376215c805c))
* **lessons:** dynamically color lesson detail components with brand colors and remove unused export file ([ccf7b8f](https://github.com/Kh3rwa1/olitunapp/commit/ccf7b8fff59f5d8cb6fb6c181b99460d6b2e32a4))
* **lessons:** enforce strict category-specific brand colors on detail screens ([cfab46d](https://github.com/Kh3rwa1/olitunapp/commit/cfab46dda274cb635231b267e32a306fd322fb59))
* **lessons:** implement LessonBlockDetailScreen to make all text blocks interactive with rich slider view ([e7ab1eb](https://github.com/Kh3rwa1/olitunapp/commit/e7ab1eb3b5fd8d1b6db0016ee062ee3670a42a4a))
* **lessons:** map Words category to primary neon green brand color ([fc329da](https://github.com/Kh3rwa1/olitunapp/commit/fc329dabe2b1c86d5c22581dc1d4f6bb6b96ca04))
* **lessons:** resolve word routing mismatches and seed all vocabulary ([2dd7b15](https://github.com/Kh3rwa1/olitunapp/commit/2dd7b1550eb1e22ce6d333b440b2965fd44a33a2))
* **lessons:** support full-bleed edge-to-edge media in LetterDetailScreen and NumberDetailScreen ([f1baf4e](https://github.com/Kh3rwa1/olitunapp/commit/f1baf4e9908f17ab8efffa8836b9c98920517a74))
* **lessons:** support rich hero media ([54e527f](https://github.com/Kh3rwa1/olitunapp/commit/54e527f18a54c7f04119e8c00c2598db071823a2))
* **lessons:** transition detail screens to static collapsing app bar swiping layout ([b8933de](https://github.com/Kh3rwa1/olitunapp/commit/b8933de0de162caf59b371d42902202ca4418f21))
* **lessons:** unify all lesson category themes to premium neon green, center cards vertically/horizontally, add shimmering backdrop gradient, and fix syntax errors ([dd74f25](https://github.com/Kh3rwa1/olitunapp/commit/dd74f25c384e4462c7133b7c584a5de7f5c57fa3))
* **lessons:** unify detailed lesson screen to neon green, remove custom tracing buttons, and implement automatic tracing transition on swipe-up ([da9f68c](https://github.com/Kh3rwa1/olitunapp/commit/da9f68c4d1241ae026074ad6c677e199f85c788f))
* **media-picker:** support video uploads with autoplay preview and duration warning ([30081b6](https://github.com/Kh3rwa1/olitunapp/commit/30081b69baff01beb571fe9080900a72dc59838e))
* migrate learner screens to universal content system, align admin navigation, restore premium lesson UI, fix guest session syncing, and stabilize all unit tests ([4eb8b2b](https://github.com/Kh3rwa1/olitunapp/commit/4eb8b2b5268c4312938d7d6d26e5e1ae70f0adda))
* migrate to active Appwrite project, restore welcome grid, and optimize homescreen scrolling performance ([6c13d0c](https://github.com/Kh3rwa1/olitunapp/commit/6c13d0c277e5182367e67f088bd7d9d6c35432c4))
* **mobile:** Add premium glassmorphic thumbnail rendering to Rhyme cards ([bcb0058](https://github.com/Kh3rwa1/olitunapp/commit/bcb005869656466c234da3052ab7a84a78265eae))
* **model:** add coverMediaType to ContentItem and RhymeModel with serialization round-trip ([c51b7f0](https://github.com/Kh3rwa1/olitunapp/commit/c51b7f09d7a0f91b3338632e2a28675d1a19766f))
* **monetization:** implement daily affirmations, paywall, binti wait… ([50d2b99](https://github.com/Kh3rwa1/olitunapp/commit/50d2b991fe66b0e6c7bdfb3de97d967627ad5401))
* **monetization:** implement daily affirmations, paywall, binti waitlist, dynamic onboarding goals, and policy documentation ([0f76aa2](https://github.com/Kh3rwa1/olitunapp/commit/0f76aa2689b342ee07f6add4c59a82fb8b2c52b5))
* polish mobile learning UI ([5efb3af](https://github.com/Kh3rwa1/olitunapp/commit/5efb3af3172a0a0a89a32fd3b306fd13b959c581))
* polish unified admin list screen and resolve minor code review issues ([1cf7173](https://github.com/Kh3rwa1/olitunapp/commit/1cf7173e5648d7d84d96080878c3ce16a5327c0a))
* **practice:** add Phase 3 and Phase 4 practice feature files and deterministic goldens ([4be7b12](https://github.com/Kh3rwa1/olitunapp/commit/4be7b12772c49946419bf3b763d4921637751df2))
* **practice:** add typing practice toggle to settings screen ([0cca37f](https://github.com/Kh3rwa1/olitunapp/commit/0cca37f754ba4bdd326227b69d48daef9e90a56e))
* **practice:** comprehensive a11y for keyboard, panel, and settings ([3451755](https://github.com/Kh3rwa1/olitunapp/commit/3451755d63d237af8eef0d63736e19bf10ec1822))
* **practice:** fix tracing guide rendering, set 50% autoadvance, and add analytics tracing score tracking ([707ae74](https://github.com/Kh3rwa1/olitunapp/commit/707ae74b401bb7adcf85a940c8f10848ee205d9d))
* **practice:** implement recordPracticeCompletion stats and analytics integration ([11f92de](https://github.com/Kh3rwa1/olitunapp/commit/11f92deb7d8f3d38e6f8acc81d634fa8477c0510))
* **practice:** integrate typing practice into ContentDetailScreen ([c8af54c](https://github.com/Kh3rwa1/olitunapp/commit/c8af54c47bfdfdbd8acd1792f17f58d5fb07740f))
* **practice:** integrate typing practice into LessonBlockDetailScreen for word/sentence blocks only ([982b269](https://github.com/Kh3rwa1/olitunapp/commit/982b26931cab568dc300c5a8c1acd6b159e35758))
* **practice:** wire TypingPracticeController to recordPracticeCompletion (fires once per session) ([877705e](https://github.com/Kh3rwa1/olitunapp/commit/877705eb46a2d833aa442e4e22e835861c1bbdf2))
* **profile:** premium $200B startup visual upgrade to profile and milestones subsystems ([46150d1](https://github.com/Kh3rwa1/olitunapp/commit/46150d1aac4a18ea81f570aae1e475333b6c5efc))
* **quiz:** add try-catch error handling & logging for quiz completion persistence ([d8a9cd4](https://github.com/Kh3rwa1/olitunapp/commit/d8a9cd4b892eb19098c30be814b430dd45395db0))
* **quiz:** extract QuizScoringRules to centralize scoring & passing rules ([7ec2892](https://github.com/Kh3rwa1/olitunapp/commit/7ec28923b16bc6b605e61910418bc1380882f6ba))
* **quiz:** out-of-hearts fail state ([7139b6a](https://github.com/Kh3rwa1/olitunapp/commit/7139b6a94c3f9badce57b3810fd6a282a5d35cdf))
* **quiz:** shuffle question and option order per session ([8851326](https://github.com/Kh3rwa1/olitunapp/commit/8851326f7e165f198fdafa62bfb4c1575b901b3c))
* redesign and upgrade splash screen to AAA+ visual quality and fix navigation freeze ([b36f0a1](https://github.com/Kh3rwa1/olitunapp/commit/b36f0a1a6fa7df0ceeef5274637dbad56996e9aa))
* Redesign Bakhed CMS Hub & editor, resolve Sohrai category migration, and add race-condition test coverage ([b6b9d3d](https://github.com/Kh3rwa1/olitunapp/commit/b6b9d3d2ab436a15a873be916c0162e5d682854f))
* redesign lesson detail screen and fix blank edit details sheet layout ([9ba4300](https://github.com/Kh3rwa1/olitunapp/commit/9ba43000d077e4f15ccb653ed09b93874a22e870))
* refactor admin words & sentences to use CustomScrollView, fix timezone parsing, onboarding navigation & pop screen locks ([d724104](https://github.com/Kh3rwa1/olitunapp/commit/d724104e4ec9c571316df2506afec5ea4e1aff11))
* refactor block editor to be universal and support all media types universally ([56459cb](https://github.com/Kh3rwa1/olitunapp/commit/56459cbcac57f3a3900c9702476af28fcc952a43))
* **release:** 10/10 Verified Production Release Candidate ([c8ce4a8](https://github.com/Kh3rwa1/olitunapp/commit/c8ce4a894f6d26c8c8336bf29bb911c4755d4d53))
* **release:** 10/10 verified release candidate with atomic locks, fail-closed account deletion, backend tests, and decoupled CI ([0f928ad](https://github.com/Kh3rwa1/olitunapp/commit/0f928ad5c236a3ab34cc85e8eec99f967b2ddd8f))
* remove streak shield complexity ([44539d9](https://github.com/Kh3rwa1/olitunapp/commit/44539d997b56b678c1f72a0b5190da33df09a8b2))
* remove weekly learning circles feature ([a39e3e0](https://github.com/Kh3rwa1/olitunapp/commit/a39e3e05e7afb47d8516fc95820f3a667826b0fc))
* responsive grid layout (3 cols phone, 4 cols tablet) for ContentGridScreen ([67d299b](https://github.com/Kh3rwa1/olitunapp/commit/67d299bcdf521198f48a627be0567085ce9d807f))
* **rhymes, lessons:** implement local caching and production diagnostics for rhymes, add dynamic responsive grids and glassmorphic completion bar ([195e0a4](https://github.com/Kh3rwa1/olitunapp/commit/195e0a47eb8d664ff3608a256e2176f06e06ca2c))
* **rhymes:** add tagsList array column with dual-write + backfill ([65e8898](https://github.com/Kh3rwa1/olitunapp/commit/65e8898a02b4920f181906af8995e40d78fb5bd6))
* **router:** configure standalone letter and number routes with all sentinel ([90052a3](https://github.com/Kh3rwa1/olitunapp/commit/90052a31abdc9f493e21cf11dd7e30dd65fe2773))
* **schema:** add coverMediaType enum attribute to rhymes schema fixture ([f02195e](https://github.com/Kh3rwa1/olitunapp/commit/f02195ec46a575194ee5fd32fb1add56ee652a63))
* **seeder:** expand default vocabulary and sentence data lists to 20+ items per category ([2d02dff](https://github.com/Kh3rwa1/olitunapp/commit/2d02dff130e08582349676451b8b37e8e7a87a6c))
* **sentences:** clear collection before seeding to purge legacy categories ([4d44a60](https://github.com/Kh3rwa1/olitunapp/commit/4d44a6040c3f44d57d8747f06d4d173a480c5d35))
* **storage:** configure cover_videos storage bucket ([428baf3](https://github.com/Kh3rwa1/olitunapp/commit/428baf3efa14808432dfff6c4ca778d775a39e5f))
* **ui:** unify detail screen layouts to match number card design ([6674167](https://github.com/Kh3rwa1/olitunapp/commit/66741678dc90425230839a1e2dbeca810c5d9693))
* unify admin categories to subcategories/lessons view and resolve subcategory filtering ([0e121d0](https://github.com/Kh3rwa1/olitunapp/commit/0e121d07ab20e50901f3146cd9dd0d2b3d128e1c))
* Upgrade Bakhed audio player details screen to premium interactive hub ([f33d5b6](https://github.com/Kh3rwa1/olitunapp/commit/f33d5b6475977845b64dcfa6313804ccb7ab2298))
* upgraded UI, timezone-safe daily missions, and 80% listening th… ([68efffb](https://github.com/Kh3rwa1/olitunapp/commit/68efffb9cb5020aced1e0dfa5f77e85d1796b54f))
* upgraded UI, timezone-safe daily missions, and 80% listening threshold ([65e0773](https://github.com/Kh3rwa1/olitunapp/commit/65e0773bc0caec8f1d0b17207d57eda20b3eb07c))
* **uploads:** deleteIfUnreferenced guard prevents deletion of actively-referenced files ([9dbb59e](https://github.com/Kh3rwa1/olitunapp/commit/9dbb59eec730d1d55d77696f97a2b610db1ccb59))
* **uploads:** route video uploads to cover_videos bucket via ContentMediaKind.video ([339f876](https://github.com/Kh3rwa1/olitunapp/commit/339f87614ee31f436469e1e9e69a5a348f3e8052))
* **uploads:** synchronous audio duration probe in MediaUploader (web + native) ([661bf46](https://github.com/Kh3rwa1/olitunapp/commit/661bf46e34ef0ead30944ebc1f09d4ed8c6f2da5))
* **uploads:** validate video file size, mime, and duration before upload ([40fd781](https://github.com/Kh3rwa1/olitunapp/commit/40fd781585700af480b5a749f503c6691a6e42b7))
* **ux:** implement premium skeleton loaders, conditional HUD stats, and milestone/completion haptics ([df0beaa](https://github.com/Kh3rwa1/olitunapp/commit/df0beaa0f914938f7e98ff04c6a33ab1ee6f3395))
* **version:** build SHA mismatch detector with 5-min polling and cache-busting ([cc8f10f](https://github.com/Kh3rwa1/olitunapp/commit/cc8f10f39df868d1fc9df1960c76dbaabf1d9641))
* **web:** harden pwa install experience ([a9625f6](https://github.com/Kh3rwa1/olitunapp/commit/a9625f6204a35e037759e947380bdd4c7ff862f8))
* **web:** inject build SHA and timestamp and generate build-info.json ([2c0f713](https://github.com/Kh3rwa1/olitunapp/commit/2c0f7132f47c326a1389bb5e0868df836a444cd4))
* wire grid to subcategory drilldown with deep study button and global admin row-click ([8179318](https://github.com/Kh3rwa1/olitunapp/commit/8179318b0e77b5affa22c04bd616b379f34ab10e))


### Bug Fixes

* add missing AppLogger import in lesson_repository_impl ([a9ed60c](https://github.com/Kh3rwa1/olitunapp/commit/a9ed60cfa30ea7c52be1990ffa134dcfa62be6c2))
* **admin:** capture dialog context in _bulkDelete and audit remaining unsafe pop patterns ([e983ac3](https://github.com/Kh3rwa1/olitunapp/commit/e983ac37ee412498799d978ecfd2c3268189afd9))
* **admin:** capture dialog context in _bulkPublish to prevent parent route pop on fast async resolution ([b059b44](https://github.com/Kh3rwa1/olitunapp/commit/b059b447dae2686233a9cfe05906247a21e4aee7))
* **admin:** capture dialog context in _editItem to prevent parent route pop on fast async resolution ([5c0cc7c](https://github.com/Kh3rwa1/olitunapp/commit/5c0cc7cd03bea8bd6b4184828047b12c2e781080))
* **admin:** ensure custom categories always route to their dedicated Subcategories dashboard regardless of chosen icon ([5831329](https://github.com/Kh3rwa1/olitunapp/commit/58313290a104471039f1b86d0359f925ff71f223))
* **admin:** preserve block metadata on synthesis and add targeted repair script ([c1bae34](https://github.com/Kh3rwa1/olitunapp/commit/c1bae34ca4d8b50c91f9a3392ec339827f054a9c))
* **admin:** resolve flutter analyze issues for lesson content screen ([0c3c8e5](https://github.com/Kh3rwa1/olitunapp/commit/0c3c8e5b9254866bb00ef3746ecae1805674c603))
* **admin:** sync sidebar category ID parameter and restore edit blocks button on cards ([309d3c4](https://github.com/Kh3rwa1/olitunapp/commit/309d3c499a7073e26f61b2b94c35d098bd066978))
* **admin:** unblock media picker + universal block sheet ([7fb9d7a](https://github.com/Kh3rwa1/olitunapp/commit/7fb9d7abf6a62765dabf6bea4cff0813cd345fb0))
* **audio:** support audio pronunciation playback from GlyphBlock in grid UI and admin panel ([e76b3fc](https://github.com/Kh3rwa1/olitunapp/commit/e76b3fc3e2c71d90a053d414e2865e773c87869f))
* **audio:** support CORS cross-origin playback in just_audio web and prevent layout thrashing on StreamBuilders ([4686e6b](https://github.com/Kh3rwa1/olitunapp/commit/4686e6bc508e90fc88c51c2c30239d66325de6bc))
* auto-save lesson blocks and guard back-navigation to prevent data loss ([ca0dbf0](https://github.com/Kh3rwa1/olitunapp/commit/ca0dbf0143291f441135e4bd4506d16635d5efd5))
* **bakhed:** backfill audio reference for orphaned document 2b8e3972 ([83a6df0](https://github.com/Kh3rwa1/olitunapp/commit/83a6df0d2b61bffd246adb22eb7236ccb1d9f27d))
* **bakhed:** backfill audio reference for stale-client incident on 2b8e3972 ([5879c8b](https://github.com/Kh3rwa1/olitunapp/commit/5879c8b1466bd56464d6c310867f303185e481ba))
* **bakhed:** capture dialog context to prevent parent route pop on fast async delete ([0250b47](https://github.com/Kh3rwa1/olitunapp/commit/0250b471c86310db79336cb7c12df60a98217d55))
* **bakhed:** coerce tags to legacy 50-char string to unblock saves ([b553a48](https://github.com/Kh3rwa1/olitunapp/commit/b553a4830ff3e10669357eb8ac81bfaffaeace7e))
* **bakhed:** defer media deletions until save commits to prevent orphaned refs ([cc3a415](https://github.com/Kh3rwa1/olitunapp/commit/cc3a4150b9b259125a05b74d95d677be4401cee6))
* **bakhed:** handle 404 on load as new draft instead of fatal error ([0ca8b8e](https://github.com/Kh3rwa1/olitunapp/commit/0ca8b8eb78294a0f488fa8fb846391f34b26bed0))
* **bakhed:** lift TextEditingController out of dialog builder to prevent rebuild data loss ([328446d](https://github.com/Kh3rwa1/olitunapp/commit/328446d99b5c0e74938451d957b9800b5943f7ed))
* **bakhed:** resolve audio playback failure on mobile and preview player on admin panel ([94e8c42](https://github.com/Kh3rwa1/olitunapp/commit/94e8c42218d4605d431bc0da336c753e1440d52e))
* **bakhed:** toRhymeModel preserves category name instead of substituting document ID ([16bda8d](https://github.com/Kh3rwa1/olitunapp/commit/16bda8df11aa88a08543e9f1b49c70bdf672bb8d))
* **bakhed:** wire MediaPickerField upload state to global inflight guard (closes production race) ([0d6fa77](https://github.com/Kh3rwa1/olitunapp/commit/0d6fa77d3a28087e1e2da46c64ef68a6a1d3a263))
* **build:** adapt SW patch for Flutter SDK format change ([74a1838](https://github.com/Kh3rwa1/olitunapp/commit/74a183876b93f909af12568c7c21133ce661e9af))
* **build:** handle Flutter SDK versions that omit flutter_bootstrap.js entirely ([4b77fe5](https://github.com/Kh3rwa1/olitunapp/commit/4b77fe5e1a3c3bfa34c0263fae117e3348fc3cf5))
* **categories:** guard StateNotifier updates with mounted check in CategoryNotifier ([0a5248a](https://github.com/Kh3rwa1/olitunapp/commit/0a5248af75f76283b4005fcd5b254f7255eeee40))
* **categories:** resolve dangling library doc comment warning in remote datasource ([e389a3e](https://github.com/Kh3rwa1/olitunapp/commit/e389a3e77830680b79f08a864491af4ff00ec89d))
* **ci:** fix index snapshotting, enforce strict main CI secret checks, and align setup schema attributes ([f3a18b9](https://github.com/Kh3rwa1/olitunapp/commit/f3a18b97e093997aaba1f7330b58fb85d2920590))
* **ci:** omit size property when null in schema snapshot and log full git diff on schema drift failure ([e915fbc](https://github.com/Kh3rwa1/olitunapp/commit/e915fbc1ed319b38a521bf60667149c14a281491))
* **client:** prevent custom categories with alphabet icons from hijacking standard alphabet routing in user app ([f055ed3](https://github.com/Kh3rwa1/olitunapp/commit/f055ed327b2ee01beaf205a5f7f9cc160f95f5fa))
* correct standard Santali number names and automate keeper corrections ([6f8ea94](https://github.com/Kh3rwa1/olitunapp/commit/6f8ea946ecb028099132c7f99dc70b931907c32f))
* CSV export functionality on Web ([bf3d1ec](https://github.com/Kh3rwa1/olitunapp/commit/bf3d1ec6e95a3b4ad896ccd180b1a3cfa31435fb))
* **guest:** resolve redundant static analysis lints in guest and offline fallback repositories ([83f0ce7](https://github.com/Kh3rwa1/olitunapp/commit/83f0ce761261912b315ec28c279b02a327822d86))
* **hardening:** add getLessonById unit tests, expand reconciliation suite, and update readiness report ([843fbb8](https://github.com/Kh3rwa1/olitunapp/commit/843fbb87c6875b5f19c6929c08dd5b217566366c))
* **hardening:** complete 10/10 production hardening for account deletion, razorpay idempotency, appwrite permissions, purchase entitlements, and CI/CD ([3da7463](https://github.com/Kh3rwa1/olitunapp/commit/3da7463600829d065bf011b290d82eb1ad4ce934))
* **hardening:** complete post-merge test isolation and formatting ([d5cd018](https://github.com/Kh3rwa1/olitunapp/commit/d5cd0182462597fe377063c4c11a9650ea05f929))
* **hardening:** enforce status code and empty body checks in account deletion, fail-closed web session missing timestamp, non-tautological admin permissions test, and exponential backoff with jitter ([8aafbca](https://github.com/Kh3rwa1/olitunapp/commit/8aafbca4a0a4df342d219031360475f464416039))
* **hardening:** fix admin team permission builder, account deletion server verification, analytics queue mutex, and web session TTL ([81724a4](https://github.com/Kh3rwa1/olitunapp/commit/81724a49ac717565ea6de8a5ca7403883d41354c))
* **hardening:** isolate SharedPreferences mock state in flutter_test_config and format codebase ([23b020d](https://github.com/Kh3rwa1/olitunapp/commit/23b020ddf414087f180035c567dfb1f55beb72ff))
* **hardening:** resolve type checks, AppwriteException parameters, and package imports ([8866fc6](https://github.com/Kh3rwa1/olitunapp/commit/8866fc6209e5169226cd019d09178f8dc6f900a0))
* **home:** resolve Next Best Action card routing and fix vertical text clipping in buttons ([fd960d5](https://github.com/Kh3rwa1/olitunapp/commit/fd960d520bf0ebe25746cee5a623c1b85684bdd6))
* Ignore deprecated onReorder warning for cross-version SDK compatibility ([42c2e81](https://github.com/Kh3rwa1/olitunapp/commit/42c2e811de70d4403fa15d9e68e3b5fa520ee3a8))
* **infra:** log and ensure PUT collection permissions update runs on existing collections in appwrite_setup ([2a5b204](https://github.com/Kh3rwa1/olitunapp/commit/2a5b204984190f8a861e7c379074ffe39e1026c2))
* **l10n:** resolve all linter info warnings and optimize constructors to const ([3f816c9](https://github.com/Kh3rwa1/olitunapp/commit/3f816c9b277d41c6e93be69a53d4039abeb098c6))
* **lessons:** convert ref.read to ref.watch inside lesson content widgets to ensure reactivity and show arrow buttons on bento cells ([896b06d](https://github.com/Kh3rwa1/olitunapp/commit/896b06d1f898e055faa8007d90cf4e6ed5af8289))
* **lessons:** fallback to subcategory hero media url in LessonDetailScreen when lesson has no hero media ([1a61209](https://github.com/Kh3rwa1/olitunapp/commit/1a612099c674b7d337590038c5b969d5f9978258))
* **lessons:** preserve pronunciation audio for non-audio blocks ([a1d4f89](https://github.com/Kh3rwa1/olitunapp/commit/a1d4f898567f1d092b4c9f94847820e196dff85f))
* **lessons:** render custom block media universally ([c71f581](https://github.com/Kh3rwa1/olitunapp/commit/c71f581c23c3e7d476116f0aa7cf0aa7f54b32dc))
* make client-side seeders safe, idempotent, and canonical-aligned ([7a9c935](https://github.com/Kh3rwa1/olitunapp/commit/7a9c935dd1d2e0c2c362e7739114eb8119cbd425))
* make ContentBlock parser backwards-compatible with legacy block fields to prevent vanishing content ([33f3b8a](https://github.com/Kh3rwa1/olitunapp/commit/33f3b8aa3d1a5138e9ce172a374682af08bb6ae3))
* **media-picker:** dispose video controllers on value change and widget teardown ([8b46c27](https://github.com/Kh3rwa1/olitunapp/commit/8b46c276377752996523cc303594dcaffb352b6c))
* **media:** repair lottie + animated svg rendering ([e5f500d](https://github.com/Kh3rwa1/olitunapp/commit/e5f500d7f3f12703a67cf3abc8d5305bba67bc0e))
* **media:** resolve SVG and HTML block rendering issues, fallback lesson hero media to blocks ([1a4561f](https://github.com/Kh3rwa1/olitunapp/commit/1a4561f73ebf9bed773a566e6f92c43fa0528191))
* **mobile:** resolve hero image sizing and infinite setState loop on content detail screens ([b315a16](https://github.com/Kh3rwa1/olitunapp/commit/b315a16c2558062c7edef2a40a4304c0b2d659c2))
* **payments:** enforce atomic delete-then-recreate stale lock takeover, owner-token lock release, and fix payment.failed order check ([199c9f7](https://github.com/Kh3rwa1/olitunapp/commit/199c9f7884a4ea65fbdc35c40f2380461d8ab3c7))
* **payments:** fix highestEpoch activeLockDoc assignment in razorpayWebhook ([bfa045c](https://github.com/Kh3rwa1/olitunapp/commit/bfa045ca0e025894209712d94720d7c6d02a7aff))
* **payments:** implement crash-recovery TTL lock takeover, lock deletion warning logging, and fail-closed claim repair response ([fefdc37](https://github.com/Kh3rwa1/olitunapp/commit/fefdc3700c95db287b17d572ab3904dd349454bb))
* **payments:** implement cross-epoch stale worker fencing, 60s TTL safety margin, and server-side O(1) descending epoch discovery ([6636f68](https://github.com/Kh3rwa1/olitunapp/commit/6636f685c62a8180085b225561bb809a91e8cbbc))
* **payments:** implement per-payment atomic lock, payment claim retry repair, and expand 12-test suite ([f10dce4](https://github.com/Kh3rwa1/olitunapp/commit/f10dce4ceffa4e2b5cd2801979e7f0e7ab48c4e2))
* **payments:** implement true database atomic primitive via monotonic epoch lock document creation ([241e825](https://github.com/Kh3rwa1/olitunapp/commit/241e8259f5213156385a2e52cb9bee6f45535e44))
* **payments:** replace destructive delete-recreate lock with atomic versioned CAS monotonic lock ([9cd29bb](https://github.com/Kh3rwa1/olitunapp/commit/9cd29bbf54728aa9f3976ba17c0831a3748c4d4d))
* **presentation:** resolve hero media visibility on mobile detail screens and category lessons list screen ([a1f4826](https://github.com/Kh3rwa1/olitunapp/commit/a1f48268a4b5c636f929bcee2626d1ad6ab6f1f3))
* **profile:** resolve text truncation on streak calendar card and optimize layouts ([026afb0](https://github.com/Kh3rwa1/olitunapp/commit/026afb0788afdebdf9f1ccf0d29416fff532f6f5))
* properly resolve categoryId for subcategory creation in admin panel ([34a4fdc](https://github.com/Kh3rwa1/olitunapp/commit/34a4fdc931d104e30f3f23bda2638cbcdc2f2b7c))
* **quiz:** enclose if statement in a block for curly_braces_in_flow_control_structures ([fa05c31](https://github.com/Kh3rwa1/olitunapp/commit/fa05c3119cb680a5329a09c8812d182b60db039c))
* **quiz:** move startQuiz trigger out of build to ref.listen ([1fdf183](https://github.com/Kh3rwa1/olitunapp/commit/1fdf183f81c6b9ee09d6bce94d615a793068bfec))
* refactor ContentItem.toAppwrite to map and emit exact schema-defined attributes for each specific ContentKind to eliminate all unknown-attribute errors ([f7e9dd6](https://github.com/Kh3rwa1/olitunapp/commit/f7e9dd6c57526e2fbcef2b16ed6e43dde73f59d1))
* **release:** comprehensive production hardening, account deletion response verification, web session TTL, and backend reconciliation ([1059744](https://github.com/Kh3rwa1/olitunapp/commit/10597447087091d82ffd979dcd4b8f2206b6d22c))
* remove kind field from Appwrite payload to align with collection schemas and prevent unknown-attribute errors ([a10d806](https://github.com/Kh3rwa1/olitunapp/commit/a10d8069e239825bf719cbd78441d3de29e95487))
* **repo:** add fallback seed content items to ContentRepository for guest/offline support ([af46224](https://github.com/Kh3rwa1/olitunapp/commit/af46224a6504904b84e68d0eadf9d3961b2fa4d7))
* **repo:** align static fallback category IDs to support cat_vocab and cat_sentences robustly in offline mode ([e65154d](https://github.com/Kh3rwa1/olitunapp/commit/e65154d8107823921089f331462166161af095d5))
* **repo:** use camelCase in content toAppwrite payload and categoryId query to match Appwrite database schema ([c738f7b](https://github.com/Kh3rwa1/olitunapp/commit/c738f7bd887e3748e59a8c61c85b0bebc5f85815))
* resolve all flutter analyze --fatal-infos issues ([4617eda](https://github.com/Kh3rwa1/olitunapp/commit/4617edacc68fc28078a7afbba637d9a52b8e35b3))
* resolve avoid_redundant_argument_values and prefer_const_declarations warnings ([00b4563](https://github.com/Kh3rwa1/olitunapp/commit/00b456366e269eaae4b0ed611f5865b4c8aba584))
* resolve avoid_redundant_argument_values and unused_field issues in media fields ([743597e](https://github.com/Kh3rwa1/olitunapp/commit/743597e833a270128952f25c5bb94867207709a9))
* resolve detailed lesson screen overflows & admin metadata blank screen crashes ([556b172](https://github.com/Kh3rwa1/olitunapp/commit/556b172769ca17fdc6107da0e898562ff75de155))
* resolve flutter analyze fatal info warnings for null-aware map spreading and deprecated ReorderableListView onReorder calls ([289ef43](https://github.com/Kh3rwa1/olitunapp/commit/289ef431c1836102bc7f9da05131807bf1598f3a))
* resolve guest flow smoke test failures and optimize loading dela… ([76d5640](https://github.com/Kh3rwa1/olitunapp/commit/76d564066bb2270e48082231aa94a807ba8cd1c2))
* resolve guest flow smoke test failures and optimize loading delays in test environment ([1a6cda2](https://github.com/Kh3rwa1/olitunapp/commit/1a6cda2b5dd832401c67bfccd832a87a44a1e97d))
* resolve settings screen freeze and theme toggling issues under Santali locale ([241d3a1](https://github.com/Kh3rwa1/olitunapp/commit/241d3a140ac1f07ef892b1024e190e5b9816ef03))
* Resolve static analysis warning in premium player and rhymes test ([42c0f53](https://github.com/Kh3rwa1/olitunapp/commit/42c0f53e7095ddb5ae5de2edfb83ff3345241905))
* resolve subcategory drilldown fallback regression and restore deep study paths ([59ee854](https://github.com/Kh3rwa1/olitunapp/commit/59ee854e64f86acaa03ce7f13cd0d275a1e4877e))
* restore lesson slider UI, fix categoryId on subcategory creation, resolve lint warnings ([9b285cc](https://github.com/Kh3rwa1/olitunapp/commit/9b285cc39ac89f0468de45b00a67c3a494bce36a))
* restore per-lesson carousel routing for Alphabets and Numbers subcategories ([32769cd](https://github.com/Kh3rwa1/olitunapp/commit/32769cdf1877e2b021c8dd26534aface1cc5229e))
* revert Appwrite project ID back to correct production ID 699495910038e39622c5 ([014797c](https://github.com/Kh3rwa1/olitunapp/commit/014797c95e56e0644be1346bc8cec21a6112bf3c))
* rewire admin block editor to universal content system ([5dc1f39](https://github.com/Kh3rwa1/olitunapp/commit/5dc1f39b0867ed48a97b2bfdef5c522af30f8411))
* **schema:** align all fixture indexes with appwrite_setup and restore size null mapping to eliminate main CI schema drift ([34bc2da](https://github.com/Kh3rwa1/olitunapp/commit/34bc2da1fc7cf10b037ad8c206c198de9aff9395))
* **schema:** restore size: null attribute mapping and include all 39 database collections in snapshot script ([e1dfee3](https://github.com/Kh3rwa1/olitunapp/commit/e1dfee32c069453305f224345b1c8b3798048ddb))
* **security:** atomic payment ID claims, dispute event names, out-of-order failed event protection, and backend Node test suite ([983571e](https://github.com/Kh3rwa1/olitunapp/commit/983571e50e439cbade2a5c1ed66d0498c0d9b35b))
* **security:** bind order IDs, fail-closed verification, razorpayWebhook, appwrite.json, and CI fixes ([60be930](https://github.com/Kh3rwa1/olitunapp/commit/60be93088038c9fd62272299702888113f339df1))
* **security:** constant-time HMAC, cumulative refund policy, payment_claims schema, and CI coverage enforcement ([ba631b9](https://github.com/Kh3rwa1/olitunapp/commit/ba631b9b237f7ab7d81d4c33f34f5224099fae06))
* **security:** course_purchases schema alignment, out-of-order refund protection, and strict schema validation ([c90e3d1](https://github.com/Kh3rwa1/olitunapp/commit/c90e3d10342b6ab70934281a5c3217f8c6da4bf1))
* **security:** exact refund_claims schema match, interrupted claim recovery resume, and fail-closed authoritative total ([f864c1e](https://github.com/Kh3rwa1/olitunapp/commit/f864c1ed609a455fd7af0396c712c74782fcd953))
* **security:** expand delete-account scopes, deploy reconcileOrphanedDeletions function, and fix cleanup_complete state recovery gap ([fbc297b](https://github.com/Kh3rwa1/olitunapp/commit/fbc297b132ee296349d04ddbc1bda864a2b80973))
* **security:** fail-closed claim creation, safe idempotent claim recovery, exact dispute mappings, and backend Node integration tests ([e493f9d](https://github.com/Kh3rwa1/olitunapp/commit/e493f9d86061668a64c77665417ed53dc4b19db7))
* **security:** harden account deletion, remediate Gitleaks findings, add payment reconciliation and CodeQL race condition fixes ([203d727](https://github.com/Kh3rwa1/olitunapp/commit/203d727dbb75ea5efe590aba6048a023c6b55c9b))
* **security:** re-fetch optimistic lock in refund processing and dispute won lifecycle guard ([692f2fa](https://github.com/Kh3rwa1/olitunapp/commit/692f2faf8f918da73a53051cd80078603a648f85))
* **security:** sanitize delete-account logging, add strict staging URL parser, and deploy payment reconciliation function ([3d3fcdb](https://github.com/Kh3rwa1/olitunapp/commit/3d3fcdb466cfd51ff6becbf417a9d6b61da8c3d4))
* **security:** two-phase refund claim state machine, authoritative refund calculation, and refund_claims schema ([91054dd](https://github.com/Kh3rwa1/olitunapp/commit/91054dd53251d62487836fb363bbf0336d99c42c))
* **seeder:** wrap QuizSeeder.seed in try-catch to handle missing quizzes table robustly ([e71aa93](https://github.com/Kh3rwa1/olitunapp/commit/e71aa936f8b2da31fdca36614aea411f1e4d70fe))
* show admin bakhed in release app ([502ea89](https://github.com/Kh3rwa1/olitunapp/commit/502ea890cb43124c0957b0bd2f6440eff9b902de))
* **storage:** Fix Flutter Web file upload error in MediaUploader ([51aa77d](https://github.com/Kh3rwa1/olitunapp/commit/51aa77d90786fc8fc20fbee270fc326fb3b32e05))
* **storage:** repair image/lottie/webp uploads — bucket config + error surfacing ([e61af1d](https://github.com/Kh3rwa1/olitunapp/commit/e61af1d8bbe2ada3f5d50797d10ac228a0035681))
* **style:** remove unused imports in category lessons and tests ([154d51f](https://github.com/Kh3rwa1/olitunapp/commit/154d51f0c144a8ea852394c7ecb78f133ae4c7e0))
* support offline category IDs in subcategory drill-down detection ([2963c85](https://github.com/Kh3rwa1/olitunapp/commit/2963c85afbaa9bd63c3f2808680f5793b1908df9))
* **test:** add mediaUploaderProvider override to pre-existing E2E test ([ffac0dd](https://github.com/Kh3rwa1/olitunapp/commit/ffac0dd2d8d3f52b6f16f1dfb1f25bccd3193515))
* **test:** mock category notifier in lesson detail screen test ([fd3bf74](https://github.com/Kh3rwa1/olitunapp/commit/fd3bf7414a77d0d0f80200fac6b20f6c4f0dc4c4))
* **test:** resolve Flutter category model test assertion, add ambiguous payment guard and complete schema validation ([8fe684d](https://github.com/Kh3rwa1/olitunapp/commit/8fe684d56815966bc6b8556da82ab33db3120f5b))
* **test:** use const for adminTeam in permission invariant test ([e4f0705](https://github.com/Kh3rwa1/olitunapp/commit/e4f0705926b3a898d4b4bcdd0710f65a22dd5256))
* **tooling:** omit indexes key from snapshot output when empty to prevent schema drift diffs ([1d3673f](https://github.com/Kh3rwa1/olitunapp/commit/1d3673f68ecba995080bf0a2f080b5bbc26e674f))
* **ui:** disable global TextField fill on AI Translator screen to fix broken transparent container ([9f8379f](https://github.com/Kh3rwa1/olitunapp/commit/9f8379fa9a538d255ea53555c85077c87655bde8))
* update site ignore list to exclude .gradle, *.apk, and test dirs ([4b5c306](https://github.com/Kh3rwa1/olitunapp/commit/4b5c3063d8b99f738f15595d2274786dd92838ff))
* use NoTransitionPage for admin panel shell routes to prevent screen transition overlap lingering ([3ae1f30](https://github.com/Kh3rwa1/olitunapp/commit/3ae1f301a4826210d6ba501ef429ace969c880d1))
* **web:** capture initial web hash fragment early in main to prevent /welcome redirect ([181af83](https://github.com/Kh3rwa1/olitunapp/commit/181af837c601676f01827476ec97593570978272))
* **webhook:** atomic refund deduplication and dependency injection in Node payment tests ([05a5387](https://github.com/Kh3rwa1/olitunapp/commit/05a5387ca86aa7fd6caef78054e738d373fda6ed))
* **web:** polish pwa loading screen ([60db8ae](https://github.com/Kh3rwa1/olitunapp/commit/60db8ae8473c3cf367b8cd9bf46f8144451ab6c0))
* **web:** post-build SW patch removes flutter_bootstrap.js from cache manifest ([025173b](https://github.com/Kh3rwa1/olitunapp/commit/025173bc14a2a68cdebca0ef9992ce4a14c8a471))
* **web:** skip navigation to '/' on Web success to allow page redirect ([9da665a](https://github.com/Kh3rwa1/olitunapp/commit/9da665a8e16a265313eed0ed9954ef17e80c25b5))
* **web:** support key parameter in Web OAuth redirect parameters to prevent welcome screen redirect ([01f8d4c](https://github.com/Kh3rwa1/olitunapp/commit/01f8d4c1e95fb132056a9b59fe96fdfc6a9bc0ce))


### Performance Improvements

* **home:** add repaint boundaries and verify const usage ([50073b7](https://github.com/Kh3rwa1/olitunapp/commit/50073b778a2780efaa904383034df33c3cc71710))
* **learn:** cache audio service and register WidgetsBindingObserver lifecycle ([a0e3ebb](https://github.com/Kh3rwa1/olitunapp/commit/a0e3ebb1393604db6e555738fce32dfc364c5a94))
* **practice:** RepaintBoundary + select() to optimize keystroke rebuilds ([c20d46e](https://github.com/Kh3rwa1/olitunapp/commit/c20d46e2dcb49e6c034d14e6bd9355a4b3a0aba1))
* **quiz:** derive quizzesByIdProvider for O(1) map cached lookups ([e5f451c](https://github.com/Kh3rwa1/olitunapp/commit/e5f451c80d73ae9d15aedefe3438fe558cab8a68))
* remove decorative background glows on home ([65ce477](https://github.com/Kh3rwa1/olitunapp/commit/65ce477c533c7ecdb58fb77b0e886a3cd1511593))
* remove repeating bento stat card animations to completely fix scroll jank ([5285806](https://github.com/Kh3rwa1/olitunapp/commit/52858066862479c46bcecdebe99c6a1b71d9c8ae))

## [Unreleased]

### Added
- **Production Hardening (10/10)**:
  - Appwrite explicit permissions model (`createPublicContent`, `createOwnerPrivateRow`, `createAdminOnlyRow`, `createFunctionManagedRow`, `updateDataPreservingPermissions`).
  - Server-authoritative account deletion function with multi-collection data purge and financial ledger anonymization (`functions/delete-account/`).
  - Durable, non-expiring mutation outbox (`MutationOutboxService`) with dedicated Hive storage and backoff jitter.
  - Stale-while-revalidate fallback protection (`StaleWhileRevalidateRepository`) to preserve cached entitlements during offline/network failure.
  - Production error screen sanitization and fail-soft startup for non-essential audio and crash reporting services.
  - Hardened open-redirect protection on web routing.
  - Decoupled CI/CD workflows (`flutter-ci.yml` and `staging-health.yml`).
  - Comprehensive documentation (`PRODUCTION_HARDENING_REPORT.md`, `APPWRITE_PERMISSIONS.md`, `ACCOUNT_DELETION.md`, `PAYMENT_STATE_MACHINE.md`, `DATA_CLASSIFICATION.md`, `INCIDENT_RESPONSE.md`, `ROLLBACK.md`, `STAGING_SETUP.md`).
- Daily Affirmations system: Appwrite `daily_affirmations` collection, dynamic CMS panel for CRUD, deterministic daily selection, play/listen audio, mark-as-read analytics, and Watermarked WhatsApp Share.
- Course Unlock and Paywall infrastructure: `course_purchases` collection, local `razorpay_flutter` payments, `in_app_review` feedback integration, custom course preview bounds, and dynamic pricing.
- Binti Guru booking/waitlist: `binti_guru_waitlist` collection, segmented tab switch in Bakhed screen, booking form sheet, user dashboard bookings view, and admin marketplace lead dashboard with quick Call/WhatsApp integrations.
- Dynamic Onboarding Goals: Admin goals editor CMS with title customization, custom icons list, dynamic retrieval from Appwrite `app_settings` setting `onboarding_goals`, and user preferences persistence via `learning_goals` array.
- Scheduled daily cleanup function `cleanupAnalyticsEvents` to automatically prune learning analytics older than 90 days.
- Scheduled weekly backup function `backupCollections` to export core curriculum and config collections to `admin_backups` bucket with 12-file rolling retention.

### Changed
- Home screen simplified to three core blocks: `TodayAffirmationCard`, `NextBestActionCard`, and `TodayMissionCard` to reduce visual noise.
- Mistake review card relocated from Home to post-quiz Quiz Result screen.
- Global `app_colors.dart` slimmed from ~14KB to under 5KB, retaining semantic tokens.
- Standard categories upgraded to structured unlockable courses.
- Verification & OTP screen redirects optimized to transition to `/onboarding`.
- Flattened rhyme subcategories into tag arrays/chips on the rhymes collection and UI.
- Reorganized Admin sidebar into exactly 4 semantic groups (Overview, Content, Monetization, Operations, Media) to consolidate administration operations.

### Removed
- Legacy collections creation logic: `weekly_circles`, `circle_members`, `circle_events`, `weekly_circle_recaps`, and `streak_shields` are no longer created.
- Weekly Learning Circles feature
- Streak Shield gamification
- Decorative home glows (performance)
- Notifications placeholder
- Rhymes subcategory CRUD/UI forms and providers.
- Video players, dependencies (`video_player`, `cached_video_player_plus`), and video media field uploads.
- Unused dependencies `path`, `record`, and `permission_handler`.
- Unused Premium translation hub (`ai_magic_hub.dart`).
- Bento stats layout (`home_bento_widgets.dart` shim and directory).
- Legacy mobile learning preview card slider (`learning_path_preview.dart`).
- Deprecated `rhyme_categories` collection, repositories, providers, CRUD screens, seeding scripts, and sidebar entries.
- Dedicated CRUD sub-screens from Gamification panel for seed-only collections (`bravo_messages`, `reward_messages`, `quiz_feedback_messages`, `mission_templates`).

### Kept
- Protected the Translate feature (`magic_translate_dialog.dart` explicitly preserved across mobile, backend, and admin, including Admin translation tool and backend caches/rate-limits).

## 1.1.1

- Hardened the learning product with production gamification, admin operations,
  analytics, Bakhed learning content, and Android/web release checks.
