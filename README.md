# Radio Group Builder

Build labeled radio buttons from a list using Flutter's native `RadioGroup`.
Includes vertical and wrapping horizontal layouts, custom labels, reusable
styling, and a typed controller for value/index selection and silent updates.
Flutter handles radio keyboard navigation and group semantics.

Requires **Flutter 3.35.0+ and Dart 3.9.0+**. This is a Flutter package implemented
in Dart; it has no native plugin code or runtime dependencies beyond Flutter.

## Installation

```yaml
dependencies:
  radio_group_builder: ^0.1.0
```

```dart
import 'package:radio_group_builder/radio_group_builder.dart';
```

## Usage

Create controllers in your State, outside `build`, and dispose them in `dispose`.

```dart
final controller = RadioGroupController<String>();

// Inside build:
RadioGroupBuilder<String>(
  controller: controller,
  values: ['Choice 1', 'Choice 2', 'Choice 3'],
  indexOfDefault: 0,
  onChanged: (value) {
    debugPrint('Selected: $value');
  },
  decoration: const RadioGroupDecoration(
    spacing: 8,
    activeColor: Colors.amber,
    labelStyle: TextStyle(color: Colors.blue),
    toggleable: true,
  ),
)

// Programmatic selection:
controller.value = 'Choice 3';
controller.selectAt(0);
controller.value = null; // Or selectAt(-1).
final selected = controller.value;
final index = controller.selectedIndex; // -1 when nothing is selected.
controller.setValueSilently('Choice 2');
controller.selectSilentlyAt(0);

// Inside the owning State's dispose:
controller.dispose();
```

A controller is optional. Without one, the builder manages and disposes its own
controller, preserving selection across ordinary parent rebuilds. A controller
can be attached to only one builder at a time.

## Labels and horizontal layout

```dart
RadioGroupBuilder<int>(
  values: [1, 2, 3],
  labelBuilder: (value) => Text('Option $value'),
  orientation: RadioGroupOrientation.horizontal,
  decoration: const RadioGroupDecoration(spacing: 12, runSpacing: 8),
  enabledBuilder: (value) => value != 2,
)
```

Widget values are displayed directly when `labelBuilder` is omitted. Other
values use `toString()` with `decoration.labelStyle`. For application data,
prefer stable IDs or model values with a custom label builder. Values must be
unique by equality and non-null; null represents no selection.

`enabled: false` disables user interaction with the whole group. The optional
`enabledBuilder` disables individual choices. Programmatic selection still works.
Custom labels should be descriptive, non-interactive widgets; radios provide the
keyboard focus targets, and labels also respond to pointer taps.

## Selection lifecycle

- A non-null controller value takes precedence over `indexOfDefault` on attach.
- Defaults apply silently on attachment; changing the default index on an
  existing builder does not reset selection.
- Selecting the same value again has no effect, unless a user toggles a selected
  choice with `toggleable: true`, which clears it and reports null.
- Normal selection calls `onChanged` once. Silent selection updates the UI and
  controller listeners but skips `onChanged`.
- Updating the choices preserves a still-present selection. Removing the selected
  choice clears it silently during the widget update.
- A detached controller retains its value and supports value assignment.
  `selectedIndex`, `selectAt`, and `selectSilentlyAt` require an attached builder.
- Invalid values throw `ArgumentError`; invalid indices throw `RangeError`;
  sharing or reusing a disposed controller throws `StateError`.

The controller is a `ChangeNotifier`, so it can also drive a `ListenableBuilder`.
Choice-list reconciliation during widget updates is silent and does not notify
controller listeners. Dispose an external controller when its owner is disposed.

## Example and migration

[The example](example/lib/main.dart) mirrors the V2 demo: vertical string values,
horizontal widget values, callback/fetched selection boards, and Select None,
Select Last, and Fetch Selected buttons. It also demonstrates silent selection.

See [MIGRATION.md](MIGRATION.md) for a guide on migrating from `radio_group_v2`.

---

If you found this helpful, please consider supporting development through
[Buy Me a Coffee](https://www.buymeacoffee.com/babincc),
[PayPal](https://paypal.me/cssbabin), or [Venmo](https://venmo.com/u/babincc).
