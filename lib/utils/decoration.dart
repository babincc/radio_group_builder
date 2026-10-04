part of '../radio_group_builder.dart';

/// Defines the spacing, labels, and appearance of a [RadioGroupBuilder].
///
/// Unspecified colors use Flutter's RadioTheme and Material theme defaults.
@immutable
class RadioGroupDecoration {
  /// Creates reusable styling for a radio group.
  const RadioGroupDecoration({
    this.spacing = 0.0,
    this.runSpacing = 0.0,
    this.verticalAlignment = MainAxisAlignment.start,
    this.horizontalAlignment = WrapAlignment.center,
    this.labelStyle,
    this.toggleable = false,
    this.activeColor,
    this.fillColor,
    this.focusColor,
    this.hoverColor,
    this.overlayColor,
    this.splashRadius,
    this.visualDensity = VisualDensity.compact,
    this.materialTapTargetSize = MaterialTapTargetSize.shrinkWrap,
    this.labelPadding = const EdgeInsets.only(right: 12.0),
  }) : assert(spacing >= 0.0),
       assert(runSpacing >= 0.0),
       assert(splashRadius == null || splashRadius >= 0.0);

  /// Space between adjacent choices in either orientation.
  final double spacing;

  /// Space between horizontal rows when the choices wrap.
  final double runSpacing;

  /// Alignment of the button and label in each vertical row.
  final MainAxisAlignment verticalAlignment;

  /// Alignment of the choices in a horizontal wrap.
  final WrapAlignment horizontalAlignment;

  /// Style applied to automatically generated text labels.
  final TextStyle? labelStyle;

  /// Allows pressing the selected choice again to clear the selection.
  final bool toggleable;

  /// Selected radio color, unless overridden by fillColor.
  final Color? activeColor;

  /// Radio fill colors resolved from WidgetState values.
  final WidgetStateProperty<Color?>? fillColor;

  /// Ink color when the radio has keyboard focus.
  final Color? focusColor;

  /// Ink color when the pointer hovers over the radio.
  final Color? hoverColor;

  /// State-dependent ink overlay colors.
  final WidgetStateProperty<Color?>? overlayColor;

  /// Radius of the radio's ink response.
  final double? splashRadius;

  /// Density of the radio control.
  final VisualDensity? visualDensity;

  /// Size of the radio's Material tap target.
  final MaterialTapTargetSize? materialTapTargetSize;

  /// Padding around each label, including custom widget labels.
  final EdgeInsetsGeometry labelPadding;
}
