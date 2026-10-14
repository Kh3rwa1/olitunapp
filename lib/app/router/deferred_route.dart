import 'package:flutter/material.dart';

/// Loads a deferred library once and caches the result.
///
/// [load] is typically a `loadLibrary` tear-off of a `deferred as` import.
class DeferredLibrary {
  DeferredLibrary(this._load);

  final Future<void> Function() _load;
  Future<void>? _pending;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> ensureLoaded() {
    return _pending ??= _load().then((_) => _isLoaded = true).catchError((
      Object error,
    ) {
      // Allow a retry after a failed download.
      _pending = null;
      throw error;
    });
  }
}

/// Builds [builder] once [library] is loaded, showing a small progress
/// indicator while the deferred code is downloaded (web) or initialized.
class DeferredRoute extends StatefulWidget {
  const DeferredRoute({
    super.key,
    required this.library,
    required this.builder,
  });

  final DeferredLibrary library;
  final WidgetBuilder builder;

  @override
  State<DeferredRoute> createState() => _DeferredRouteState();
}

class _DeferredRouteState extends State<DeferredRoute> {
  late Future<void> _future = widget.library.ensureLoaded();

  void _retry() {
    setState(() {
      _future = widget.library.ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.library.isLoaded) return widget.builder(context);
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: IconButton(
                tooltip: MaterialLocalizations.of(
                  context,
                ).refreshIndicatorSemanticLabel,
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _retry,
              ),
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return widget.builder(context);
      },
    );
  }
}
