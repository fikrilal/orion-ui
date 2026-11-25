import 'package:flutter/material.dart';
import 'package:orion_ui/orion_ui.dart';

/// Shared chrome for the Orion showcases: a tabbed demo panel, live controls
/// built from the kit's own components, a labelled matrix row, and a code peek.
///
/// The specimens inside the panels are real Orion components, and so are the
/// controls; the host Material layer provides only the panel and the labels.
class OrionShowcasePanel extends StatefulWidget {
  const OrionShowcasePanel({
    super.key,
    required this.preview,
    required this.code,
  });

  /// The live demo, shown first.
  final Widget preview;

  /// The call the demo stands for, kept behind the Code tab.
  final String code;

  @override
  State<OrionShowcasePanel> createState() => _OrionShowcasePanelState();
}

class _OrionShowcasePanelState extends State<OrionShowcasePanel> {
  bool _showCode = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerLow : scheme.surface,
        borderRadius: BorderRadius.circular(OrionRadii.radius12),
        border: Border.all(
          color: isDark
              ? scheme.outlineVariant.withValues(alpha: 0.15)
              : scheme.outlineVariant.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: OrionSpacing.space16,
            ),
            // The panel's painted surface would sit over the tab ink; a
            // transparent Material above the InkWells keeps the ripple visible.
            child: Material(
              type: MaterialType.transparency,
              child: Row(
                children: [
                  _tab(
                    theme,
                    label: 'Preview',
                    active: !_showCode,
                    onTap: () => setState(() => _showCode = false),
                  ),
                  const SizedBox(width: OrionSpacing.space16),
                  _tab(
                    theme,
                    label: 'Code',
                    active: _showCode,
                    onTap: () => setState(() => _showCode = true),
                  ),
                ],
              ),
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? scheme.outlineVariant.withValues(alpha: 0.15)
                : scheme.outlineVariant.withValues(alpha: 0.30),
          ),
          Padding(
            padding: const EdgeInsets.all(OrionSpacing.space16),
            child: _showCode
                ? OrionShowcaseCode(code: widget.code)
                : widget.preview,
          ),
        ],
      ),
    );
  }

  Widget _tab(
    ThemeData theme, {
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: OrionSpacing.space12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? theme.colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: active
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// A card of live controls, stacked so no control ever reflows.
class OrionShowcaseControls extends StatelessWidget {
  const OrionShowcaseControls({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(OrionSpacing.space16),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerLow : scheme.surface,
        borderRadius: BorderRadius.circular(OrionRadii.radius12),
        border: Border.all(
          color: isDark
              ? scheme.outlineVariant.withValues(alpha: 0.15)
              : scheme.outlineVariant.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(height: OrionSpacing.space16),
            children[index],
          ],
        ],
      ),
    );
  }
}

/// A single-select control: a label above a row of chips.
class OrionShowcaseChoice<T> extends StatelessWidget {
  const OrionShowcaseChoice({
    super.key,
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: OrionSpacing.space8),
          child: Text(label, style: textTheme.labelMedium),
        ),
        Wrap(
          spacing: OrionSpacing.space8,
          runSpacing: OrionSpacing.space8,
          children: [
            for (final T value in values)
              OrionChip(
                key: ValueKey<String>(
                  'showcase-choice-$label-${labelOf(value)}',
                ),
                label: Text(labelOf(value)),
                selected: value == selected,
                onSelected: (bool nowSelected) {
                  if (nowSelected) {
                    onChanged(value);
                  }
                },
              ),
          ],
        ),
      ],
    );
  }
}

/// A labelled boolean control on the kit's own switch.
class OrionShowcaseToggle extends StatelessWidget {
  const OrionShowcaseToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: OrionSpacing.space4),
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        OrionSwitch(
          key: ValueKey<String>('showcase-control-$label'),
          value: value,
          semanticLabel: label,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// A labelled slider on the kit's own slider, with a live value readout.
class OrionShowcaseValueSlider extends StatelessWidget {
  const OrionShowcaseValueSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step,
    this.display,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final double? step;
  final String? display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: OrionSpacing.space4),
          child: Text(label, style: theme.textTheme.labelMedium),
        ),
        Row(
          children: [
            Expanded(
              child: OrionSlider(
                value: value,
                min: min,
                max: max,
                step: step,
                semanticLabel: label,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: OrionSpacing.space8),
            Text(
              display ?? value.toStringAsFixed(2),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

/// A fixed-width label beside a specimen, so a matrix scans as rows.
class OrionShowcaseLabeledRow extends StatelessWidget {
  const OrionShowcaseLabeledRow({
    super.key,
    required this.label,
    required this.child,
    this.labelWidth = 96,
  });

  final String label;
  final Widget child;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: OrionSpacing.space12),
        Expanded(
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
      ],
    );
  }
}

/// A selectable monospace peek at the code a demo stands for.
class OrionShowcaseCode extends StatelessWidget {
  const OrionShowcaseCode({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(OrionSpacing.space16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(OrionRadii.radius8),
        border: Border.all(
          color: isDark
              ? scheme.outlineVariant.withValues(alpha: 0.15)
              : scheme.outlineVariant.withValues(alpha: 0.30),
        ),
      ),
      child: SelectableText(
        code,
        style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
          fontFamily: 'monospace',
          height: 1.5,
        ),
      ),
    );
  }
}
