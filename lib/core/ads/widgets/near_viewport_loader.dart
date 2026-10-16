import 'package:flutter/widgets.dart';

/// Defers an ad request until its slot is within about one screen of being
/// visible. Requests for slots nobody scrolls to never become impressions,
/// so they only drag down the AdMob match and show rates.
mixin NearViewportLoader<T extends StatefulWidget> on State<T> {
  ScrollPosition? _watchedPosition;
  VoidCallback? _pendingLoad;

  /// Runs [load] now if the slot is near the viewport (or not inside a
  /// scrollable at all), otherwise once scrolling brings it close.
  void loadWhenNearViewport(VoidCallback load) {
    _stopWatching();
    final position = Scrollable.maybeOf(context)?.position;
    if (position == null || _isNearViewport()) {
      load();
      return;
    }
    _pendingLoad = load;
    _watchedPosition = position..addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) {
      _stopWatching();
      return;
    }
    if (!_isNearViewport()) return;
    final load = _pendingLoad;
    _stopWatching();
    load?.call();
  }

  bool _isNearViewport() {
    final box = context.findRenderObject();
    final scrollable = Scrollable.maybeOf(context);
    if (box is! RenderBox || !box.hasSize || scrollable == null) return true;
    final viewport = scrollable.context.findRenderObject();
    if (viewport is! RenderBox || !viewport.hasSize) return true;

    final offset = box.localToGlobal(Offset.zero, ancestor: viewport);
    final vertical = scrollable.position.axis == Axis.vertical;
    final start = vertical ? offset.dy : offset.dx;
    final extent = vertical ? viewport.size.height : viewport.size.width;
    final size = vertical ? box.size.height : box.size.width;
    return start < extent * 2 && start + size > -extent;
  }

  void _stopWatching() {
    _watchedPosition?.removeListener(_onScroll);
    _watchedPosition = null;
    _pendingLoad = null;
  }

  @override
  void dispose() {
    _stopWatching();
    super.dispose();
  }
}
