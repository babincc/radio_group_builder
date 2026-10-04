part of '../../radio_group_builder.dart';

/// Creates labeled choices inside Flutter's native [RadioGroup].
///
/// Values must be non-null and unique by equality. Widget values are displayed
/// directly; other values become Text labels unless labelBuilder is provided.
/// Flutter manages the radios' keyboard navigation and group semantics.
class RadioGroupBuilder<T> extends StatefulWidget {
  /// Creates a vertical list or horizontal wrapping group of radio buttons.
  ///
  /// [indexOfDefault] is applied only when attaching with no [controller]
  /// value. Later changes to this index do not reset the user's selection.
  RadioGroupBuilder({
    super.key,
    required List<T> values,
    this.controller,
    this.labelBuilder,
    this.onChanged,
    this.indexOfDefault = -1,
    this.orientation = RadioGroupOrientation.vertical,
    this.decoration = const RadioGroupDecoration(),
    this.enabled = true,
    this.enabledBuilder,
  }) : values = List<T>.unmodifiable(values) {
    // Validate in release builds too: ambiguous values break native grouping.
    if (values.any((value) => value == null) ||
        values.toSet().length != values.length) {
      throw ArgumentError.value(
        values,
        'values',
        'Use unique, non-null values.',
      );
    }
    if (indexOfDefault < -1 || indexOfDefault >= values.length) {
      throw RangeError.range(
        indexOfDefault,
        -1,
        values.length - 1,
        'indexOfDefault',
      );
    }
  }

  /// Choices in display order, copied to prevent in-place list mutations.
  final List<T> values;

  /// Optional externally owned selection controller.
  final RadioGroupController<T>? controller;

  /// Creates a custom label for each choice.
  final Widget Function(T value)? labelBuilder;

  /// Called once for each changed selection, except silent controller changes.
  final ValueChanged<T?>? onChanged;

  /// Initial selected index, or -1 for no selection.
  final int indexOfDefault;

  /// Vertical stacking or horizontal wrapping.
  final RadioGroupOrientation orientation;

  /// Styling for the controls, labels, and layout.
  final RadioGroupDecoration decoration;

  /// Whether users can interact with the group. Controllers still work.
  final bool enabled;

  /// Optionally disables individual choices in an otherwise enabled group.
  final bool Function(T value)? enabledBuilder;

  @override
  State<RadioGroupBuilder<T>> createState() => _RadioGroupBuilderState<T>();
}

/// Owns controller coupling and delegates radio behavior to Flutter.
class _RadioGroupBuilderState<T> extends State<RadioGroupBuilder<T>> {
  /// Either the supplied controller or one owned by this state.
  late RadioGroupController<T> _controller;

  /// Tracks whether this state must dispose the controller.
  late bool _ownsController;

  /// Guards cleanup if controller attachment fails during initialization.
  bool _attached = false;

  @override
  void initState() {
    super.initState();
    _attachController();
  }

  /// Applies an initial default silently and subscribes to selection changes.
  void _attachController({T? previousValue}) {
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        RadioGroupController<T>(
          value: widget.values.contains(previousValue) ? previousValue : null,
        );
    _controller._attach(this, widget.values, widget.onChanged);
    if (_controller.value == null && widget.indexOfDefault >= 0) {
      _controller._value = widget.values[widget.indexOfDefault];
    }
    _controller.addListener(_selectionChanged);
    _attached = true;
  }

  /// Detaches external controllers and disposes only locally owned ones.
  void _releaseController() {
    if (!_attached) return;
    _attached = false;
    _controller.removeListener(_selectionChanged);
    _controller._detach(this);
    if (_ownsController) _controller.dispose();
  }

  @override
  void didUpdateWidget(covariant RadioGroupBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      final previousValue = _controller.value;
      _releaseController();
      _attachController(previousValue: previousValue);
    } else {
      _controller._update(widget.values, widget.onChanged);
    }
  }

  /// Controller listeners rebuild for both normal and silent changes.
  void _selectionChanged() => setState(() {});

  @override
  void dispose() {
    _releaseController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_attached) return const SizedBox.shrink();
    return RadioGroup<T>(
      groupValue: _controller.value,
      onChanged: (value) => _controller.value = value,
      child: widget.orientation == RadioGroupOrientation.vertical
          ? _verticalListBuilder()
          : _horizontalListBuilder(),
    );
  }

  /// Builds a column with gaps only between choices.
  Widget _verticalListBuilder() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int index = 0; index < widget.values.length; index++) ...[
          if (index > 0) SizedBox(height: widget.decoration.spacing),
          _radioItemBuilder(widget.values[index]),
        ],
      ],
    );
  }

  /// Uses natural row widths, allowing choices to wrap onto additional lines.
  Widget _horizontalListBuilder() {
    return Wrap(
      alignment: widget.decoration.horizontalAlignment,
      spacing: widget.decoration.spacing,
      runSpacing: widget.decoration.runSpacing,
      children: widget.values.map(_radioItemBuilder).toList(),
    );
  }

  /// Builds one native radio and its clickable label.
  Widget _radioItemBuilder(T value) {
    final enabled =
        widget.enabled && (widget.enabledBuilder?.call(value) ?? true);
    return MergeSemantics(
      child: Row(
        mainAxisSize: widget.orientation == RadioGroupOrientation.horizontal
            ? MainAxisSize.min
            : MainAxisSize.max,
        mainAxisAlignment: widget.decoration.verticalAlignment,
        children: [
          _buttonBuilder(value, enabled),
          Flexible(child: _labelBuilder(value, enabled)),
        ],
      ),
    );
  }

  /// Native radios inherit selection and callbacks from the enclosing group.
  Widget _buttonBuilder(T value, bool enabled) {
    final decoration = widget.decoration;
    return Radio<T>(
      value: value,
      enabled: enabled,
      toggleable: decoration.toggleable,
      activeColor: decoration.activeColor,
      fillColor: decoration.fillColor,
      focusColor: decoration.focusColor,
      hoverColor: decoration.hoverColor,
      overlayColor: decoration.overlayColor,
      splashRadius: decoration.splashRadius,
      visualDensity: decoration.visualDensity,
      materialTapTargetSize: decoration.materialTapTargetSize,
    );
  }

  /// Labels share selection behavior but do not add a second keyboard stop.
  Widget _labelBuilder(T value, bool enabled) {
    final label =
        widget.labelBuilder?.call(value) ??
        (value is Widget
            ? value
            : Text(
                value.toString(),
                style: widget.decoration.labelStyle,
                softWrap: true,
              ));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: enabled ? () => _selectLabel(value) : null,
      child: Padding(padding: widget.decoration.labelPadding, child: label),
    );
  }

  /// Matches Radio.toggleable and reports deselection as null exactly once.
  void _selectLabel(T value) {
    if (_controller.value == value) {
      if (widget.decoration.toggleable) _controller.value = null;
    } else {
      _controller.value = value;
    }
  }
}

/// Describes how choices are arranged in a [RadioGroupBuilder].
enum RadioGroupOrientation {
  /// Stacks choices in a column.
  vertical,

  /// Places choices side by side and wraps at the available width.
  horizontal,
}
