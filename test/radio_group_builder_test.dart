import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radio_group_builder/radio_group_builder.dart';

/// Mounts test groups under the Material environment required by Radio.
Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('native group, radio and label taps emit one callback', (
    tester,
  ) async {
    final controller = RadioGroupController<String>();
    final changes = <String?>[];
    await tester.pumpWidget(
      app(
        RadioGroupBuilder<String>(
          values: ['First', 'Second'],
          controller: controller,
          onChanged: changes.add,
        ),
      ),
    );
    expect(find.byType(RadioGroup<String>), findsOneWidget);
    await tester.tap(find.text('Second'));
    await tester.pump();
    expect(controller.value, 'Second');
    expect(changes, ['Second']);
    await tester.tap(find.text('Second'));
    expect(changes, ['Second']);
    await tester.tap(find.byType(Radio<String>).first);
    await tester.pump();
    expect(changes, ['Second', 'First']);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('toggleable labels and radios report null once', (tester) async {
    final changes = <String?>[];
    await tester.pumpWidget(
      app(
        RadioGroupBuilder<String>(
          values: ['First'],
          indexOfDefault: 0,
          onChanged: changes.add,
          decoration: const RadioGroupDecoration(toggleable: true),
        ),
      ),
    );
    await tester.tap(find.text('First'));
    await tester.pump();
    expect(changes, [null]);
    await tester.tap(find.byType(Radio<String>));
    await tester.pump();
    await tester.tap(find.byType(Radio<String>));
    await tester.pump();
    expect(changes, [null, 'First', null]);
  });

  testWidgets('silent changes rebuild and notify without callbacks', (
    tester,
  ) async {
    final controller = RadioGroupController<String>();
    final changes = <String?>[];
    var notifications = 0;
    controller.addListener(() => notifications++);
    await tester.pumpWidget(
      app(
        RadioGroupBuilder<String>(
          values: ['First', 'Second'],
          controller: controller,
          onChanged: changes.add,
        ),
      ),
    );
    controller.setValueSilently('Second');
    await tester.pump();
    expect(
      tester
          .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
          .groupValue,
      'Second',
    );
    expect(controller.selectedIndex, 1);
    controller.selectSilentlyAt(0);
    await tester.pump();
    expect(controller.value, 'First');
    expect(notifications, 2);
    expect(changes, isEmpty);
    controller.selectAt(-1);
    await tester.pump();
    expect(controller.selectedIndex, -1);
    expect(changes, [null]);
    expect(() => controller.selectAt(2), throwsRangeError);
    expect(() => controller.selectAt(-2), throwsRangeError);
    expect(() => controller.value = 'Unknown', throwsArgumentError);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('default is silent and controller selection takes precedence', (
    tester,
  ) async {
    final controller = RadioGroupController<String>(value: 'Second');
    final changes = <String?>[];
    await tester.pumpWidget(
      app(
        RadioGroupBuilder<String>(
          controller: controller,
          values: ['First', 'Second'],
          indexOfDefault: 0,
          onChanged: changes.add,
        ),
      ),
    );
    expect(controller.value, 'Second');
    expect(changes, isEmpty);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('reordering preserves value and removal clears silently', (
    tester,
  ) async {
    final controller = RadioGroupController<String>();
    final changes = <String?>[];
    Widget group(List<String> values) => app(
      RadioGroupBuilder<String>(
        values: values,
        controller: controller,
        indexOfDefault: 0,
        onChanged: changes.add,
      ),
    );
    await tester.pumpWidget(group(['First', 'Second']));
    expect(controller.value, 'First');
    await tester.pumpWidget(group(['Second', 'First']));
    expect(controller.selectedIndex, 1);
    await tester.pumpWidget(group(['Second']));
    expect(controller.value, isNull);
    expect(changes, isEmpty);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('controller replacement detaches old controller', (tester) async {
    final first = RadioGroupController<String>();
    final second = RadioGroupController<String>(value: 'Second');
    Widget group(RadioGroupController<String> controller) => app(
      RadioGroupBuilder<String>(
        controller: controller,
        values: ['First', 'Second'],
      ),
    );
    await tester.pumpWidget(group(first));
    first.value = 'First';
    await tester.pumpWidget(group(second));
    expect(first.isAttached, isFalse);
    expect(first.value, 'First');
    expect(second.isAttached, isTrue);
    expect(() => first.selectedIndex, throwsStateError);
    first.value = 'Detached';
    expect(second.value, 'Second');
    await tester.pumpWidget(const SizedBox());
    first.dispose();
    second.dispose();
  });

  testWidgets('internal controller survives ordinary rebuilds', (tester) async {
    Widget group(int index) => app(
      RadioGroupBuilder<String>(
        values: ['First', 'Second'],
        indexOfDefault: index,
      ),
    );
    await tester.pumpWidget(group(0));
    await tester.tap(find.text('Second'));
    await tester.pumpWidget(group(0));
    expect(
      tester
          .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
          .groupValue,
      'Second',
    );
  });

  testWidgets('disabled choices reject radio and label taps', (tester) async {
    final controller = RadioGroupController<String>();
    await tester.pumpWidget(
      app(
        RadioGroupBuilder<String>(
          controller: controller,
          values: ['First', 'Second'],
          enabledBuilder: (value) => value != 'Second',
        ),
      ),
    );
    await tester.tap(find.text('Second'));
    await tester.tap(find.byType(Radio<String>).last);
    expect(controller.value, isNull);
    controller.value = 'Second';
    await tester.pump();
    expect(controller.value, 'Second');
    await tester.pumpWidget(
      app(
        RadioGroupBuilder<String>(
          controller: controller,
          values: ['First', 'Second'],
          enabled: false,
        ),
      ),
    );
    await tester.tap(find.text('First'));
    expect(controller.value, 'Second');
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('native keyboard navigation skips disabled choices and wraps', (
    tester,
  ) async {
    final controller = RadioGroupController<int>();
    await tester.pumpWidget(
      app(
        RadioGroupBuilder<int>(
          controller: controller,
          values: [1, 2, 3],
          indexOfDefault: 0,
          enabledBuilder: (value) => value != 2,
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(controller.value, 3);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(controller.value, 1);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('widget labels and wrapping layout work at narrow widths', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        Center(
          child: SizedBox(
            width: 150,
            child: RadioGroupBuilder<Text>(
              values: const [
                Text('Widget 1'),
                Text('Widget 2'),
                Text('Widget 3'),
              ],
              orientation: RadioGroupOrientation.horizontal,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Widget 1'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Widget 3')).dy,
      greaterThan(tester.getTopLeft(find.text('Widget 1')).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom labels and decoration are applied', (tester) async {
    await tester.pumpWidget(
      app(
        RadioGroupBuilder<int>(
          values: [1, 2],
          labelBuilder: (value) => Text('Choice $value'),
          decoration: const RadioGroupDecoration(
            activeColor: Colors.amber,
            spacing: 12,
            toggleable: true,
          ),
        ),
      ),
    );
    expect(find.text('Choice 1'), findsOneWidget);
    final radio = tester.widget<Radio<int>>(find.byType(Radio<int>).first);
    expect(radio.activeColor, Colors.amber);
    expect(radio.toggleable, isTrue);
  });

  testWidgets('empty lists are supported', (tester) async {
    await tester.pumpWidget(app(RadioGroupBuilder<String>(values: [])));
    expect(find.byType(Radio<String>), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('controller can reattach after unmount and retain selection', (
    tester,
  ) async {
    final controller = RadioGroupController<String>();
    Widget group() => app(
      RadioGroupBuilder<String>(
        values: ['First', 'Second'],
        controller: controller,
      ),
    );
    await tester.pumpWidget(group());
    controller.value = 'Second';
    await tester.pumpWidget(const SizedBox());
    expect(controller.isAttached, isFalse);
    expect(controller.value, 'Second');
    await tester.pumpWidget(group());
    expect(controller.isAttached, isTrue);
    expect(controller.selectedIndex, 1);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('radio semantics include the descriptive label', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      app(
        RadioGroupBuilder<String>(
          values: ['First', 'Second'],
          indexOfDefault: 0,
        ),
      ),
    );
    final node = tester.getSemantics(find.bySemanticsLabel('First'));
    // Retain the matcher available on our minimum Flutter 3.35 SDK.
    expect(
      node,
      // ignore: deprecated_member_use
      containsSemantics(
        label: 'First',
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
    semantics.dispose();
  });

  test('invalid values/defaults and disposed controller use are rejected', () {
    expect(
      () => RadioGroupBuilder<String>(values: ['Same', 'Same']),
      throwsArgumentError,
    );
    expect(
      () => RadioGroupBuilder<String?>(values: [null]),
      throwsArgumentError,
    );
    expect(
      () => RadioGroupBuilder<String>(values: ['First'], indexOfDefault: -2),
      throwsRangeError,
    );
    expect(
      () => RadioGroupBuilder<String>(values: ['First'], indexOfDefault: 1),
      throwsRangeError,
    );
    final controller = RadioGroupController<String>();
    expect(() => controller.selectAt(0), throwsStateError);
    controller.dispose();
    expect(() => controller.value = 'First', throwsStateError);
  });
}
