import 'package:flutter/material.dart';
import 'package:radio_group_builder/radio_group_builder.dart';

/// Starts the interactive vertical and horizontal demonstrations.
void main() => runApp(const App());

/// The example application, styled like the radio_group_v2 demonstration.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radio Group Builder',
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: Scaffold(
        appBar: AppBar(title: const Text('Radio Group Builder')),
        body: const SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(25.0),
            child: Column(
              children: [
                GroupDemo<String>(
                  title: 'Vertical string values',
                  values: [
                    'String 1',
                    'String 2',
                    'String 3',
                    'String 4',
                    'String 5',
                  ],
                  decoration: RadioGroupDecoration(
                    labelStyle: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w800,
                    ),
                    spacing: 4.0,
                  ),
                ),
                Divider(height: 50.0),
                GroupDemo<Text>(
                  title: 'Horizontal widget values',
                  values: [
                    Text('Widget 1'),
                    Text('Widget 2'),
                    Text('Widget 3'),
                    Text('Widget 4'),
                    Text('Widget 5'),
                  ],
                  orientation: RadioGroupOrientation.horizontal,
                  indexOfDefault: 0,
                  decoration: RadioGroupDecoration(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    toggleable: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An independently owned controller and selection board for one demo group.
class GroupDemo<T> extends StatefulWidget {
  const GroupDemo({
    super.key,
    required this.title,
    required this.values,
    this.orientation = RadioGroupOrientation.vertical,
    this.indexOfDefault = -1,
    this.decoration = const RadioGroupDecoration(),
  });

  /// Heading above the selection board.
  final String title;

  /// String or widget values matching the original example.
  final List<T> values;

  /// Layout used by this demonstration.
  final RadioGroupOrientation orientation;

  /// Initial selected choice, without an initial onChanged callback.
  final int indexOfDefault;

  /// Styling for this demonstration.
  final RadioGroupDecoration decoration;

  @override
  State<GroupDemo<T>> createState() => _GroupDemoState<T>();
}

class _GroupDemoState<T> extends State<GroupDemo<T>> {
  /// Stable controller owned by this demo, rather than recreated during build.
  final RadioGroupController<T> _controller = RadioGroupController<T>();

  /// Value last delivered to onChanged. Silent changes intentionally leave it.
  String _automatic = 'No callback yet';

  /// Value last obtained by pressing Fetch Selected.
  String _requested = 'Not fetched yet';

  /// Makes widget-valued choices readable on the selection board.
  String _displayValue(T? value) {
    if (value == null) return 'None';
    if (value is Text) return value.data ?? value.toString();
    return value.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
        SelectedValueBoard(automatic: _automatic, requested: _requested),
        RadioGroupBuilder<T>(
          controller: _controller,
          values: widget.values,
          orientation: widget.orientation,
          indexOfDefault: widget.indexOfDefault,
          decoration: widget.decoration,
          onChanged: (value) =>
              setState(() => _automatic = _displayValue(value)),
        ),
        _actionButtonsBuilder(),
      ],
    );
  }

  /// Mirrors V2's three actions and adds silent selection for comparison.
  Widget _actionButtonsBuilder() {
    return Padding(
      padding: const EdgeInsets.only(top: 12.5),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12.5,
        runSpacing: 12.5,
        children: [
          FilledButton(
            onPressed: () => _controller.value = null,
            child: const Text('Select None'),
          ),
          FilledButton(
            onPressed: () => _controller.selectAt(widget.values.length - 1),
            child: const Text('Select Last'),
          ),
          FilledButton(
            onPressed: () => setState(() {
              _requested = _displayValue(_controller.value);
            }),
            child: const Text('Fetch Selected'),
          ),
          OutlinedButton(
            onPressed: () => _controller.selectSilentlyAt(0),
            child: const Text('Select First Silently'),
          ),
        ],
      ),
    );
  }
}

/// Compares callback-driven selection with an explicitly fetched value.
class SelectedValueBoard extends StatelessWidget {
  const SelectedValueBoard({
    super.key,
    required this.automatic,
    required this.requested,
  });

  /// Most recent onChanged value.
  final String automatic;

  /// Most recent value read by the Fetch Selected button.
  final String requested;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.5),
      child: Column(
        children: [
          const Text('Selected Value'),
          const SizedBox(height: 8.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _valueBuilder('onChanged():', automatic)),
              const SizedBox(width: 12.5),
              Expanded(
                child: _valueBuilder('"Fetch Selected" button:', requested),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Keeps both columns readable on narrow screens.
  Widget _valueBuilder(String title, String value) {
    return Column(children: [Text(title), Text(value)]);
  }
}
