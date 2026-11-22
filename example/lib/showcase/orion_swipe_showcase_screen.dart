import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// The side the playground row reveals its actions on.
enum _SwipeSide { trailing, leading }

/// Playground for [OrionSwipeActionRow] and [OrionSwipeScope].
///
/// The `Disabled` flag at the top mutes every row, the sections below are the
/// reference matrices - trailing actions, leading actions, and the full swipe -
/// and the playground last carries the focused row, which opens under a drag and
/// closes under a tap while the readout follows, generating the call it stands
/// for behind the Code tab.
class OrionSwipeShowcaseScreen extends StatefulWidget {
  const OrionSwipeShowcaseScreen({super.key});

  @override
  State<OrionSwipeShowcaseScreen> createState() =>
      _OrionSwipeShowcaseScreenState();
}

class _OrionSwipeShowcaseScreenState extends State<OrionSwipeShowcaseScreen> {
  // Flag: shared by every row on the page.
  bool _disabled = false;

  String _lastAction = 'Nothing pressed yet';

  // Playground: the focused row's own axes.
  _SwipeSide _side = _SwipeSide.trailing;
  bool _playgroundOpen = false;

  OrionSwipeAction _action(
    String label,
    IconData icon, {
    bool destructive = false,
  }) {
    return OrionSwipeAction(
      icon: Icon(icon),
      label: label,
      background: destructive ? null : Theme.of(context).colorScheme.secondary,
      onPressed: () => setState(() => _lastAction = label),
    );
  }

  /// One row under the shared flag.
  Widget _row({
    required String title,
    required String subtitle,
    List<OrionSwipeAction> trailing = const <OrionSwipeAction>[],
    List<OrionSwipeAction> leading = const <OrionSwipeAction>[],
    ValueChanged<bool>? onOpenChanged,
  }) {
    return OrionSwipeActionRow(
      trailing: trailing,
      leading: leading,
      enabled: !_disabled,
      onOpenChanged: onOpenChanged,
      child: _RowBody(title: title, subtitle: subtitle),
    );
  }

  /// The exact call the current controls produce.
  String get _snippet {
    final List<String> lines = <String>['OrionSwipeActionRow('];
    if (_side == _SwipeSide.leading) {
      lines.addAll(<String>[
        '  leading: <OrionSwipeAction>[',
        "    OrionSwipeAction(icon: const Icon(Icons.push_pin_outlined), "
            "label: 'Pin', onPressed: _onPin),",
        '  ],',
      ]);
    } else {
      lines.addAll(<String>[
        '  trailing: <OrionSwipeAction>[',
        "    OrionSwipeAction(icon: const Icon(Icons.star_outline), "
            "label: 'Star', onPressed: _onStar),",
        "    OrionSwipeAction(icon: const Icon(Icons.delete_outline), "
            "label: 'Delete', onPressed: _onDelete),",
        '  ],',
      ]);
    }
    if (_disabled) {
      lines.add('  enabled: false, // disabled');
    }
    lines.add('  onOpenChanged: _onOpenChanged,');
    lines.add(
      "  child: const _RowBody(title: 'Playground row', "
      "subtitle: 'Drag to open, tap to close'),",
    );
    lines.add(');');
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return OrionThemedScaffold(
      title: 'Orion Swipe',
      builder: (context) {
        return OrionSwipeScope(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Top Intro Header
              Padding(
                padding: const EdgeInsets.only(bottom: 2.00),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: OrionSpacing.space8,
                        vertical: OrionSpacing.space4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? scheme.onSurface.withValues(alpha: 0.10)
                            : scheme.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(
                          OrionRadii.radiusPill,
                        ),
                        border: Border.all(
                          color: isDark
                              ? scheme.outlineVariant.withValues(alpha: 0.20)
                              : scheme.outlineVariant.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'GESTURE • RUBBER-BAND STRETCH',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: OrionSpacing.space8),
                    Text(
                      'Horizontal drag action reveal with rubber-band stretching and snap-back to 74 pt actions. Single-open coordination via OrionSwipeScope.',
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.4,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              OrionShowcaseControls(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: OrionShowcaseToggle(
                          label: 'Disabled',
                          value: _disabled,
                          onChanged: (value) =>
                              setState(() => _disabled = value),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 2.04),

              // Trailing actions Card
              OrionShowcaseSection(
                title: 'Trailing actions',
                subtitle:
                    'Swipe left to reveal trailing actions; single-open scope coordinates rows',
                card: true,
                child: Column(
                  children: <Widget>[
                    _row(
                      title: 'Swipe me',
                      subtitle: 'Open one row at a time',
                      trailing: <OrionSwipeAction>[
                        _action('Star', Icons.star_outline),
                        _action(
                          'Delete',
                          Icons.delete_outline,
                          destructive: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: OrionSpacing.space12),
                    _row(
                      title: 'And me',
                      subtitle: 'Opening this closes the other',
                      trailing: <OrionSwipeAction>[
                        _action('Star', Icons.star_outline),
                        _action(
                          'Delete',
                          Icons.delete_outline,
                          destructive: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2.00),

              // Leading actions Card
              OrionShowcaseSection(
                title: 'Leading actions',
                subtitle:
                    'Swipe right to reveal leading actions anchored at the start edge',
                card: true,
                child: _row(
                  title: 'Swipe the other way',
                  subtitle: 'The pane follows the drag direction',
                  leading: <OrionSwipeAction>[
                    _action('Pin', Icons.push_pin_outlined),
                  ],
                ),
              ),
              const SizedBox(height: 2.00),

              // Full swipe Card
              OrionShowcaseSection(
                title: 'Full swipe',
                subtitle:
                    'Long pull stretches every button together, then smoothly settles onto resting width',
                card: true,
                child: _row(
                  title: 'Drag all the way',
                  subtitle:
                      'A long pull stretches both buttons, then rests there',
                  trailing: <OrionSwipeAction>[
                    _action('Star', Icons.star_outline),
                    _action('Delete', Icons.delete_outline, destructive: true),
                  ],
                ),
              ),
              const SizedBox(height: 2.00),

              // Last action Card
              OrionShowcaseSection(
                title: 'Last action',
                subtitle:
                    'Event audit: actions only fire when explicitly tapped, never on swipe release',
                card: true,
                child: Text(
                  _lastAction,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 2.00),

              // Playground Card
              OrionShowcaseSection(
                title: 'Playground',
                subtitle:
                    'Interactive swipe row with configurable action direction and live code generator',
                child: OrionShowcasePanel(
                  key: const ValueKey<String>('showcase-panel-playground'),
                  preview: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      OrionShowcaseChoice<_SwipeSide>(
                        label: 'Side',
                        values: _SwipeSide.values,
                        selected: _side,
                        labelOf: _sideLabel,
                        onChanged: (value) => setState(() => _side = value),
                      ),
                      const SizedBox(height: 2.04),
                      _row(
                        title: 'Playground row',
                        subtitle: 'Drag to open, tap to close',
                        trailing: _side == _SwipeSide.trailing
                            ? <OrionSwipeAction>[
                                _action('Star', Icons.star_outline),
                                _action(
                                  'Delete',
                                  Icons.delete_outline,
                                  destructive: true,
                                ),
                              ]
                            : const <OrionSwipeAction>[],
                        leading: _side == _SwipeSide.leading
                            ? <OrionSwipeAction>[
                                _action('Pin', Icons.push_pin_outlined),
                              ]
                            : const <OrionSwipeAction>[],
                        onOpenChanged: (open) =>
                            setState(() => _playgroundOpen = open),
                      ),
                      const SizedBox(height: OrionSpacing.space8),
                      Text(
                        _playgroundOpen ? 'Row is open' : 'Row is closed',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  code: _snippet,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _sideLabel(_SwipeSide side) => switch (side) {
    _SwipeSide.trailing => 'Trailing',
    _SwipeSide.leading => 'Leading',
  };
}

/// The opaque surface a row hides its panes behind.
class _RowBody extends StatelessWidget {
  const _RowBody({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OrionSpacing.space16,
          vertical: OrionSpacing.space12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: OrionSpacing.space4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
