part of '../../radio_group_builder.dart';

/// Reads and changes the selection of one [RadioGroupBuilder].
///
/// Create this controller outside build and dispose it when its owner is
/// disposed. A detached controller retains its value; index operations require
/// an attached builder. Silent changes still notify listeners and update the UI,
/// but do not call the builder's onChanged callback.
class RadioGroupController<T> extends ChangeNotifier {
  /// Creates a controller with an optional initial selection.
  RadioGroupController({T? value}) : _value = value;

  /// The current selection, including while the controller is detached.
  T? _value;

  /// A snapshot of the attached builder's choices.
  List<T>? _values;

  /// Identifies the builder that currently owns this controller.
  Object? _owner;

  /// The attached builder's selection callback.
  ValueChanged<T?>? _onChanged;

  /// Prevents a disposed controller from being reused.
  bool _disposed = false;

  /// Whether this controller currently belongs to a mounted builder.
  bool get isAttached => _owner != null;

  /// The selected value, or null when nothing is selected.
  T? get value => _value;

  /// Selects a value and calls onChanged once if the selection changes.
  ///
  /// Throws ArgumentError for a non-null value outside the attached choices.
  set value(T? value) => _setValue(value, silent: false);

  /// The selected index, or -1 when nothing is selected.
  ///
  /// Throws StateError when no builder is attached.
  int get selectedIndex {
    final values = _attachedValues;
    return _value == null ? -1 : values.indexOf(_value as T);
  }

  /// Selects a value without calling the builder's onChanged callback.
  void setValueSilently(T? value) => _setValue(value, silent: true);

  /// Selects a choice by index. Use -1 to clear the selection.
  void selectAt(int index) => value = _valueAt(index);

  /// Selects by index without calling onChanged. Use -1 to clear.
  void selectSilentlyAt(int index) => setValueSilently(_valueAt(index));

  /// Obtains the choices only when an index has a meaningful interpretation.
  List<T> get _attachedValues {
    _checkDisposed();
    if (_values == null) {
      throw StateError(
        'Index operations require an attached RadioGroupBuilder.',
      );
    }
    return _values!;
  }

  /// Checks bounds before looking up an indexed selection.
  T? _valueAt(int index) {
    final values = _attachedValues;
    if (index == -1) return null;
    RangeError.checkValidIndex(index, values, 'index');
    return values[index];
  }

  /// Updates listeners before invoking the optional application callback.
  void _setValue(T? value, {required bool silent}) {
    _checkDisposed();
    if (value != null && _values != null && !_values!.contains(value)) {
      throw ArgumentError.value(value, 'value', 'Not in the radio group.');
    }
    if (_value == value) return;
    _value = value;
    final callback = _onChanged;
    notifyListeners();
    if (!silent) callback?.call(value);
  }

  /// Couples a controller to exactly one builder without requiring GlobalKeys.
  void _attach(Object owner, List<T> values, ValueChanged<T?>? onChanged) {
    _checkDisposed();
    if (_owner != null && !identical(_owner, owner)) {
      throw StateError('A controller cannot control multiple radio groups.');
    }
    if (_value != null && !values.contains(_value)) {
      throw ArgumentError.value(_value, 'value', 'Not in the radio group.');
    }
    _owner = owner;
    _values = List<T>.unmodifiable(values);
    _onChanged = onChanged;
  }

  /// Refreshes choices during a widget update. Removed selections clear silently.
  /// The builder already rebuilds, so no listener is called during this phase.
  void _update(List<T> values, ValueChanged<T?>? onChanged) {
    _values = List<T>.unmodifiable(values);
    _onChanged = onChanged;
    if (_value != null && !values.contains(_value)) _value = null;
  }

  /// Releases the builder while retaining the last selected value.
  void _detach(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _values = null;
    _onChanged = null;
  }

  /// Gives release builds the same lifecycle protection as debug builds.
  void _checkDisposed() {
    if (_disposed) throw StateError('This RadioGroupController is disposed.');
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
