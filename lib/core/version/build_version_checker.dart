import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'build_version_status.dart';
import 'build_version_checker_platform.dart' as platform;
import 'browser_reload.dart' as reload_impl;

// Expose the polling interval so it can be customized or accessed in tests
Duration buildVersionPollInterval = const Duration(minutes: 5);

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

final buildVersionStatusProvider = StreamProvider<BuildVersionStatus>(
  platform.getBuildVersionStream,
);

void reloadBrowser() {
  reload_impl.reloadBrowser();
}
