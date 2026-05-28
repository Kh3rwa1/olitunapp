import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:itun/core/logging/app_logger.dart';
import 'build_info.dart';
import 'build_version_status.dart';

const buildVersionPollInterval = Duration(minutes: 5);

BuildVersionStatus compareSha(String? clientSha, String? serverSha) {
  if (clientSha == null || clientSha.isEmpty || clientSha == 'unknown') {
    return const BuildVersionUnknown('local-dev');
  }
  if (clientSha.contains('-dirty')) {
    return const BuildVersionUnknown('local-dev');
  }
  if (serverSha == null || serverSha.isEmpty) {
    return const BuildVersionUnknown('malformed-response');
  }
  if (clientSha == serverSha) {
    return const BuildVersionMatch();
  }
  return BuildVersionStale(serverSha);
}

final buildVersionStatusProvider = StreamProvider<BuildVersionStatus>((ref) {
  if (!kIsWeb) {
    // Mobile platforms: emit match and complete
    return Stream.value(const BuildVersionMatch());
  }

  final controller = StreamController<BuildVersionStatus>();
  controller.add(const BuildVersionMatch()); // Initial placeholder match

  Timer? timer;

  Future<void> checkVersion() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = Uri.base.resolve('build-info.json?t=$timestamp');
      final response = await http.get(url, headers: {'cache': 'no-store'});

      if (response.statusCode != 200) {
        AppLogger.debug('Version check failed with status: ${response.statusCode}');
        controller.add(BuildVersionUnknown('fetch-failed: ${response.statusCode}'));
        return;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final serverSha = data['sha'] as String?;
      final status = compareSha(BuildInfo.current.sha, serverSha);
      controller.add(status);

      if (status is BuildVersionUnknown && status.reason == 'local-dev') {
        // Local dev: stop polling
        timer?.cancel();
      }
    } catch (e) {
      AppLogger.debug('Version check failed with error: $e');
      controller.add(BuildVersionUnknown('fetch-failed: $e'));
    }
  }

  // Run initial check immediately
  checkVersion();

  // Setup periodic polling
  timer = Timer.periodic(buildVersionPollInterval, (_) {
    checkVersion();
  });

  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });

  return controller.stream;
});
