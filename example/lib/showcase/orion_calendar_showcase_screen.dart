import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground for [OrionCalendar]: an inline month, and a read-only field
/// that opens the same grid in a popover.
class OrionCalendarShowcaseScreen extends StatefulWidget {
  /// Creates the calendar showcase.
  const OrionCalendarShowcaseScreen({super.key});

  @override
  State<OrionCalendarShowcaseScreen> createState() =>
      _OrionCalendarShowcaseScreenState();
}

class _OrionCalendarShowcaseScreenState
    extends State<OrionCalendarShowcaseScreen> {
  DateTime _inline = DateTime(2026, 3, 16);
  DateTime? _picked;
  final TextEditingController _field = TextEditingController();
  final OrionPopoverController _popover = OrionPopoverController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String text = _picked == null
        ? ''
        : MaterialLocalizations.of(context).formatMediumDate(_picked!);
    if (_field.text != text) {
      _field.text = text;
    }
  }

  @override
  void dispose() {
    _field.dispose();
    _popover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrionThemedScaffold(
      title: 'Calendar',
      builder: (BuildContext context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            OrionShowcaseSection(
              title: 'Month',
              subtitle: 'The parent owns the day. The month glides.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  OrionCalendar(
                    key: const Key('showcase-calendar-inline'),
                    value: _inline,
                    onChanged: (DateTime day) => setState(() => _inline = day),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Day: ${_inline.year}-${_inline.month}-${_inline.day}',
                    key: const Key('showcase-calendar-readout'),
                  ),
                ],
              ),
            ),
            OrionShowcaseSection(
              title: 'Picker',
              subtitle: 'A read-only field opens the month.',
              child: OrionPopover(
                controller: _popover,
                placement: OrionPopoverPlacement.bottomStart,
                // Tapping the field scrolls its caret into view. That scroll must
                // not dismiss the month the tap just opened.
                dismissOnScroll: false,
                triggerBuilder:
                    (BuildContext context, OrionPopoverController controller) {
                      return OrionTextField(
                        key: const Key('showcase-calendar-field'),
                        controller: _field,
                        readOnly: true,
                        label: 'Date',
                        hint: 'Pick a date',
                        suffix: const Icon(Icons.calendar_today_outlined),
                        onTap: () {
                          controller.toggle();
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                      );
                    },
                content: SizedBox(
                  width: 320,
                  child: OrionCalendar(
                    key: const Key('showcase-calendar-popover'),
                    value: _picked,
                    initialMonth: DateTime(2026, 3),
                    onChanged: (DateTime day) {
                      setState(() => _picked = day);
                      _popover.hide();
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
