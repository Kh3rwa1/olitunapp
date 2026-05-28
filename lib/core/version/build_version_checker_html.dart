import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:itun/core/logging/app_logger.dart';
import 'build_info.dart';
import 'build_version_status.dart';
import 'build_version_checker.dart';

Stream<BuildVersionStatus> getBuildVersionStream(Ref ref) {
  final controller = StreamController<BuildVersionStatus>();
  controller.add(const BuildVersionMatch()); // Initial placeholder match

  Timer? timer;

  Future<void> checkVersion() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = Uri.base.resolve('build-info.json?t=$timestamp');
      final response = await http.get(url, headers: {'cache': 'no-store'});

      final contentType = response.headers['content-type'] ?? 'unknown';

      if (response.statusCode != 200) {
        AppLogger.debug(
          'Version check failed with status: ${response.statusCode}, Content-Type: $contentType',
        );
        if (!controller.isClosed) {
          controller.add(
            BuildVersionUnknown('fetch-failed: ${response.statusCode}'),
          );
        }
        return;
      }

      // Parse JSON unconditionally
      Map<String, dynamic> data;
      try {
        data = json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        AppLogger.debug(
          'Version check JSON parse failed: $e. Content-Type: $contentType, Body: ${response.body}',
        );
        if (!controller.isClosed) {
          controller.add(const BuildVersionUnknown('parse-failed'));
        }
        return;
      }

      final serverSha = data['sha'] as String?;
      final status = compareSha(BuildInfo.current.sha, serverSha);
      if (!controller.isClosed) {
        controller.add(status);
      }

      if (status is BuildVersionUnknown && status.reason == 'local-dev') {
        // Local dev: stop polling
        timer?.cancel();
      }
    } catch (e) {
      AppLogger.debug('Version check failed with error: $e');
      if (!controller.isClosed) {
        controller.add(BuildVersionUnknown('fetch-failed: $e'));
      }
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
    if (!controller.isClosed) {
      controller.close();
    }
  });

  return controller.stream;
}
