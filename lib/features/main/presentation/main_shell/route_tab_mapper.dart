part of 'main_shell_screen.dart';

// Pure route → shell-tab mapping (spec: bottom nav has three branches —
// Learn (home/categories), Bakhed, Profile). Kept beside the shell so the
// mapper and the branch list can never drift apart.

@visibleForTesting
int? shellTabIndexForPath(String path) {
  if (path == '/' || path == '/categories') return 0;
  if (path == '/bakhed') return 1;
  if (path == '/profile') return 2;
  return null;
}
