import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ntam_congress_demo/features/home/home_screen.dart';

/// Home Quick Access lives in a shrink-wrapped [GridView] inside a
/// [CustomScrollView]. The grid only builds tiles in view, so the shortcut
/// text may be missing until the outer Home scrollable is dragged.
Finder _homeContentScrollable() {
  return find.descendant(
    of: find.byType(HomeScreen),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          widget.axisDirection == AxisDirection.down &&
          widget.physics is! NeverScrollableScrollPhysics,
    ),
  );
}

Future<void> tapHomeShortcut(
  WidgetTester tester,
  String label, {
  bool settle = true,
}) async {
  final shortcut = find.descendant(
    of: find.byType(HomeScreen),
    matching: find.text(label),
  );
  final scrollable = _homeContentScrollable();

  var attempts = 0;
  while (shortcut.hitTestable().evaluate().isEmpty && attempts < 50) {
    await tester.drag(scrollable, const Offset(0, -240));
    await tester.pump();
    attempts += 1;
  }

  await tester.pumpAndSettle();
  await tester.tap(shortcut.hitTestable());
  if (settle) {
    await tester.pumpAndSettle();
    return;
  }
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
