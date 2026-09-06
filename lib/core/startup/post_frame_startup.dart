import 'package:flutter/widgets.dart';

/// Starts nonessential work after the first usable application frame.
/// The callback must handle its asynchronous failures; it is never awaited by
/// the widget tree. Normal rebuilds do not start another initialization pass.
class PostFrameStartup extends StatefulWidget {
  const PostFrameStartup({
    super.key,
    required this.onStart,
    required this.child,
  });

  final VoidCallback onStart;
  final Widget child;

  @override
  State<PostFrameStartup> createState() => _PostFrameStartupState();
}

class _PostFrameStartupState extends State<PostFrameStartup> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onStart();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
