import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radio_group_builder_example/main.dart';

void main() {
  testWidgets('demo selection boards, silent actions, and disposal work', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const App());
    expect(find.text('String 1'), findsOneWidget);
    expect(find.text('Widget 1'), findsOneWidget);
    await tester.tap(find.text('Select Last').first);
    await tester.pump();
    expect(find.text('String 5'), findsNWidgets(2));
    await tester.tap(find.text('Fetch Selected').first);
    await tester.pump();
    expect(find.text('String 5'), findsNWidgets(3));
    await tester.tap(find.text('Select First Silently').first);
    await tester.pump();
    expect(find.text('String 5'), findsNWidgets(3));
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
