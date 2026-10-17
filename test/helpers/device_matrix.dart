import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A screen configuration a learner's phone can present: logical size,
/// an optional on-screen keyboard and a system text scale.
class TestDevice {
  const TestDevice(
    this.name,
    this.size, {
    this.keyboardHeight = 0,
    this.textScale = 1.0,
  });

  final String name;

  /// Logical (dp) size of the whole screen.
  final Size size;

  /// Logical height the on-screen keyboard covers; 0 when closed.
  final double keyboardHeight;
  final double textScale;

  static const double _pixelRatio = 3.0;

  /// Apply this device to [tester]; everything is reset after the test.
  void apply(WidgetTester tester) {
    tester.view.physicalSize = size * _pixelRatio;
    tester.view.devicePixelRatio = _pixelRatio;
    setKeyboard(tester, open: keyboardHeight > 0);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  /// Open or close an on-screen keyboard of [height] logical pixels.
  static void setKeyboard(
    WidgetTester tester, {
    required bool open,
    double height = 300,
  }) {
    tester.view.viewInsets = FakeViewPadding(
      bottom: open ? height * _pixelRatio : 0,
    );
  }

  @override
  String toString() => name;
}

/// Phones and tablets every key screen must lay out on without overflow.
const List<TestDevice> deviceMatrix = [
  TestDevice('small phone 360x640', Size(360, 640)),
  TestDevice('regular phone 393x852', Size(393, 852)),
  TestDevice(
    'regular phone, keyboard open',
    Size(393, 852),
    keyboardHeight: 300,
  ),
  TestDevice('tall phone 412x915', Size(412, 915)),
  TestDevice('tablet 800x1280', Size(800, 1280)),
  TestDevice('regular phone, text x1.3', Size(393, 852), textScale: 1.3),
];

/// Pump [frames] fixed steps instead of pumpAndSettle, which never returns
/// on screens with looping animations.
Future<void> pumpFrames(
  WidgetTester tester, {
  int frames = 10,
  Duration step = const Duration(milliseconds: 200),
}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(step);
  }
}
