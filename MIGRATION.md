# Migrating from radio_group_v2

`radio_group_builder` uses Flutter's built-in `RadioGroup`, introduced in Flutter
3.35. Upgrade to Flutter 3.35+ / Dart 3.9+ before switching dependencies.

## Dependency and import

Replace `radio_group_v2` with `radio_group_builder: ^0.1.0` in `pubspec.yaml`, then
run `flutter pub get`. Replace the old import with:

```dart
import 'package:radio_group_builder/radio_group_builder.dart';
```

Flutter itself now exports `RadioGroup`; the package widget is deliberately named
`RadioGroupBuilder` so ordinary Material imports work without hiding anything.

## Before and after

```dart
// Before (radio_group_v2):
final controller = RadioGroupController<String>();
RadioGroup<String>(
  controller: controller,
  values: ['First', 'Second'],
  indexOfDefault: 0,
  orientation: RadioGroupOrientation.horizontal,
  decoration: const RadioGroupDecoration(spacing: 10, toggleable: true),
  onChanged: (value) => debugPrint('$value'),
);

// After (radio_group_builder):
final controller = RadioGroupController<String>();
RadioGroupBuilder<String>( // The only change
  controller: controller,
  values: ['First', 'Second'],
  indexOfDefault: 0,
  orientation: RadioGroupOrientation.horizontal,
  decoration: const RadioGroupDecoration(spacing: 10, toggleable: true),
  onChanged: (value) => debugPrint('$value'),
);
```

These snippets represent separate applications using their respective imports.

## API mapping

| V2 API                                                  | Builder API                                      |
| ------------------------------------------------------- | ------------------------------------------------ |
| `RadioGroup<T>`                                         | `RadioGroupBuilder<T>`                           |
| `RadioGroupController<T>`                               | Same name; now extends `ChangeNotifier`          |
| `RadioGroupDecoration`                                  | Same name and existing decoration options        |
| `RadioGroupOrientation`                                 | Same vertical/horizontal enum values             |
| `values`, `labelBuilder`, `onChanged`, `indexOfDefault` | Same names                                       |
| `value`, `selectedIndex`, `selectAt`                    | Same names; use typed controllers                |
| `setValueSilently`, `selectSilentlyAt`                  | Same names                                       |
| `myRadioGroupKey`, `GlobalKey<RadioGroupState<T>>`      | Remove; use a controller and ordinary widget Key |
| V2 custom exceptions                                    | `ArgumentError`, `RangeError`, or `StateError`   |

If you previously accessed selection through `key.currentState`, move those
operations to the controller. Package implementation files are library parts;
import the public `radio_group_builder.dart` entrypoint.

## Behavior changes to account for

1. **Dispose controllers.** Add `controller.dispose()` to your owning State's
   `dispose`. Controllers you supply remain yours; internal ones are automatic.
2. **Callbacks fire once.** V2 could call onChanged more than once on label taps.
   A toggle deselection now consistently reports null. Silent methods continue to
   skip onChanged, while notifying controller listeners and rebuilding the radios.
3. **Defaults are initial values.** A preselected controller value wins over the
   default index. Neither initial selection nor later changes to indexOfDefault
   emit callbacks. Changing that index alone does not reset a mounted builder.
4. **Lists can change.** Reordering keeps the selection by equality. Removing the
   selected value clears it silently without notifying controller listeners.
5. **Values must be unique and non-null.** Duplicate equal values cannot identify
   independent native radios. Null means no selection. Use stable model values
   and labelBuilder instead of recreating widget values on every rebuild.
6. **Controller access is predictable.** Detached controllers keep their value.
   Index operations require attachment and throw StateError otherwise. Invalid
   attached values throw ArgumentError and invalid indices throw RangeError.
   Sharing one controller between simultaneous groups throws StateError.
7. **State survives ordinary rebuilds without keys.** The old auto-generated
   GlobalKey approach and public RadioGroupState are no longer needed.

The builder now exposes a non-null `decoration` with a const default. If your
old code explicitly passes `decoration: null`, omit that argument instead.

## New options

Use `enabled` to disable the group and `enabledBuilder` to disable specific
choices. `RadioGroupDecoration` additionally offers `visualDensity`,
`materialTapTargetSize`, and `labelPadding`. Flutter's native RadioGroup supplies
Tab, arrow-key, and Space behavior for its registered radios.

Try the example's vertical and horizontal groups to compare normal, fetched,
and silent selection before migrating your own screens.
