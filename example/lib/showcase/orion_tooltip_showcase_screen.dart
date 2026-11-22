import 'dart:async';
import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground and verification showcase for [OrionTooltip].
class OrionTooltipShowcaseScreen extends StatefulWidget {
  const OrionTooltipShowcaseScreen({super.key});

  @override
  State<OrionTooltipShowcaseScreen> createState() =>
      _OrionTooltipShowcaseScreenState();
}

enum _TooltipPlacementChoice { top, bottom, left, right }

enum _TooltipSkinChoice { standard, frosted }

class _OrionTooltipShowcaseScreenState
    extends State<OrionTooltipShowcaseScreen> {
  _TooltipPlacementChoice _placement = _TooltipPlacementChoice.top;
  _TooltipSkinChoice _skin = _TooltipSkinChoice.standard;
  OrionTooltipTriggerMode _triggerMode =
      OrionTooltipTriggerMode.hoverAndLongPress;
  bool _frosted = false;
  Timer? _warmPollTimer;
  bool _isWarm = false;

  @override
  void initState() {
    super.initState();
    _warmPollTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final warm = OrionTooltipWarmCoordinator.isWarm;
      if (warm != _isWarm && mounted) {
        setState(() => _isWarm = warm);
      }
    });
  }

  @override
  void dispose() {
    _warmPollTimer?.cancel();
    super.dispose();
  }

  OrionTooltipPlacement get _activePlacement => switch (_placement) {
    _TooltipPlacementChoice.top => OrionTooltipPlacement.top,
    _TooltipPlacementChoice.bottom => OrionTooltipPlacement.bottom,
    _TooltipPlacementChoice.left => OrionTooltipPlacement.left,
    _TooltipPlacementChoice.right => OrionTooltipPlacement.right,
  };

  OrionTooltipStyle? _resolveSkinStyle(ColorScheme scheme) {
    final OrionTooltipStyle base = switch (_skin) {
      _TooltipSkinChoice.standard => const OrionTooltipStyle(),
      _TooltipSkinChoice.frosted => OrionTooltipStyle.from(frosted: true),
    };
    return base.copyWith(
      frosted: _frosted || _skin == _TooltipSkinChoice.frosted,
    );
  }

  String get _snippet {
    final List<String> lines = <String>[
      'OrionTooltip(',
      "  message: 'Quick action tooltip with spring glide',",
      '  placement: OrionTooltipPlacement.${_activePlacement.name},',
    ];
    if (_frosted || _skin == _TooltipSkinChoice.frosted) {
      lines.add('  style: OrionTooltipStyle.from(frosted: true),');
    }
    if (_triggerMode != OrionTooltipTriggerMode.hoverAndLongPress) {
      lines.add('  triggerMode: OrionTooltipTriggerMode.${_triggerMode.name},');
    }
    lines.addAll(<String>[
      '  child: OrionButton(',
      '    variant: OrionButtonVariant.solid,',
      '    onPressed: () {},',
      '    child: const Text("Hover or Press Me"),',
      '  ),',
      ');',
    ]);
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return OrionThemedScaffold(
      title: 'Orion Tooltip',
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Intro Header
            Padding(
              padding: const EdgeInsets.only(bottom: OrionSpacing.space20),
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
                      borderRadius: BorderRadius.circular(OrionRadii.radiusPill),
                      border: Border.all(
                        color: isDark
                            ? scheme.outlineVariant.withValues(alpha: 0.20)
                            : scheme.outlineVariant.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'MICRO-CONTEXTUAL • TOOLTIPS',
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
                    'Anchor-aware micro-contextual tooltips driven by continuous spring '
                    'physics, featuring autonomous caret beaks, warm window fast inspection, '
                    'and frosted acrylic blur.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  // Warm Window Live Status Pill
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: OrionSpacing.space8,
                          vertical: OrionSpacing.space4,
                        ),
                        decoration: BoxDecoration(
                          color: _isWarm
                              ? scheme.primary.withValues(alpha: 0.12)
                              : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            OrionRadii.radiusPill,
                          ),
                          border: Border.all(
                            color: _isWarm
                                ? scheme.primary.withValues(alpha: 0.35)
                                : scheme.outlineVariant.withValues(alpha: 0.20),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isWarm
                                    ? scheme.primary
                                    : scheme.outlineVariant,
                              ),
                            ),
                            const SizedBox(width: OrionSpacing.space8),
                            Text(
                              _isWarm
                                  ? 'Warm Window Active (0ms Sibling Delay)'
                                  : 'Warm Window Cold (250ms Delay)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _isWarm
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Hero Interactive Stage Card
            OrionShowcaseSection(
              title: 'Interactive Playground',
              subtitle:
                  'Hover or long-press the target button to inspect spring glide, caret alignment, and collision auto-flipping.',
              card: true,
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                code: _snippet,
                preview: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: isDark
                            ? scheme.surfaceContainerLowest
                            : scheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(OrionRadii.radius12),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Center(
                        child: OrionTooltip(
                          message: 'Quick action tooltip with spring glide',
                          placement: _activePlacement,
                          triggerMode: _triggerMode,
                          style: _resolveSkinStyle(scheme),
                          child: OrionButton(
                            variant: OrionButtonVariant.solid,
                            onPressed: () {},
                            leading: const Icon(Icons.touch_app_rounded),
                            child: const Text('Hover or Press Me'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: OrionSpacing.space16),
                    OrionShowcaseControls(
                      children: [
                        OrionShowcaseChoice<_TooltipPlacementChoice>(
                          label: 'Placement',
                          selected: _placement,
                          values: const [
                            _TooltipPlacementChoice.top,
                            _TooltipPlacementChoice.bottom,
                            _TooltipPlacementChoice.left,
                            _TooltipPlacementChoice.right,
                          ],
                          labelOf: (p) => p.name.toUpperCase(),
                          onChanged: (p) => setState(() => _placement = p),
                        ),
                        OrionShowcaseChoice<_TooltipSkinChoice>(
                          label: 'Skin',
                          selected: _skin,
                          values: const [
                            _TooltipSkinChoice.standard,
                            _TooltipSkinChoice.frosted,
                          ],
                          labelOf: (s) => s.name.toUpperCase(),
                          onChanged: (s) => setState(() => _skin = s),
                        ),
                        OrionShowcaseChoice<OrionTooltipTriggerMode>(
                          label: 'Trigger Mode',
                          selected: _triggerMode,
                          values: const [
                            OrionTooltipTriggerMode.hoverAndLongPress,
                            OrionTooltipTriggerMode.tap,
                            OrionTooltipTriggerMode.longPress,
                          ],
                          labelOf: (m) => switch (m) {
                            OrionTooltipTriggerMode.hoverAndLongPress => 'BOTH',
                            OrionTooltipTriggerMode.tap => 'TAP',
                            OrionTooltipTriggerMode.longPress => 'LONG-PRESS',
                            _ => m.name.toUpperCase(),
                          },
                          onChanged: (m) => setState(() => _triggerMode = m),
                        ),
                        OrionShowcaseToggle(
                          label: 'Frosted Glass Layer',
                          value: _frosted,
                          onChanged: (v) => setState(() => _frosted = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: OrionSpacing.space20),

            // Warm Window Toolbar Specimen
            OrionShowcaseSection(
              title: 'Warm Window Toolbar',
              subtitle:
                  'Hover the first action icon (250ms cold delay). Then glide across sibling icons to see them emerge instantly (0ms) within the 300ms session.',
              card: true,
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-toolbar'),
                code: '''
Row(
  children: [
    OrionTooltip(message: 'Bold (Ctrl+B)', child: IconButton(...)),
    OrionTooltip(message: 'Italic (Ctrl+I)', child: IconButton(...)),
    OrionTooltip(message: 'Underline (Ctrl+U)', child: IconButton(...)),
    OrionTooltip(message: 'Strikethrough', child: IconButton(...)),
    OrionTooltip(message: 'Code snippet', child: IconButton(...)),
  ],
)''',
                preview: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: OrionSpacing.space16,
                    vertical: OrionSpacing.space12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? scheme.surfaceContainerLowest
                        : scheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(OrionRadii.radius12),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OrionTooltip(
                        message: 'Bold (Ctrl+B)',
                        placement: OrionTooltipPlacement.top,
                        child: IconButton(
                          icon: const Icon(Icons.format_bold_rounded),
                          onPressed: () {},
                        ),
                      ),
                      OrionTooltip(
                        message: 'Italic (Ctrl+I)',
                        placement: OrionTooltipPlacement.top,
                        child: IconButton(
                          icon: const Icon(Icons.format_italic_rounded),
                          onPressed: () {},
                        ),
                      ),
                      OrionTooltip(
                        message: 'Underline (Ctrl+U)',
                        placement: OrionTooltipPlacement.top,
                        child: IconButton(
                          icon: const Icon(Icons.format_underlined_rounded),
                          onPressed: () {},
                        ),
                      ),
                      OrionTooltip(
                        message: 'Strikethrough',
                        placement: OrionTooltipPlacement.top,
                        child: IconButton(
                          icon: const Icon(Icons.strikethrough_s_rounded),
                          onPressed: () {},
                        ),
                      ),
                      OrionTooltip(
                        message: 'Code snippet',
                        placement: OrionTooltipPlacement.top,
                        child: IconButton(
                          icon: const Icon(Icons.code_rounded),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: OrionSpacing.space20),

            // Rich Custom Content Specimen
            OrionShowcaseSection(
              title: 'Rich Contextual Bubble',
              subtitle:
                  'Tooltips can render custom layouts beyond plain text, such as avatars, presence dots, and titles.',
              card: true,
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-rich'),
                code: '''
OrionTooltip(
  message: 'Jane Doe profile',
  placement: OrionTooltipPlacement.bottom,
  richMessage: Row(
    children: [
      CircleAvatar(child: Text('JD')),
      Text('Jane Doe'),
    ],
  ),
  child: OrionButton(...),
)''',
                preview: Center(
                  child: OrionTooltip(
                    message: 'Jane Doe profile',
                    placement: OrionTooltipPlacement.bottom,
                    style: OrionTooltipStyle.from(
                      maxWidth: 280.0,
                      padding: const EdgeInsets.all(OrionSpacing.space12),
                      borderRadius: BorderRadius.circular(OrionRadii.radius12),
                    ),
                    richMessage: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: scheme.primaryContainer,
                          child: Text(
                            'JD',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: OrionSpacing.space12),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jane Doe',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: OrionSpacing.space4),
                                Text(
                                  'Lead Designer',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    child: OrionButton(
                      variant: OrionButtonVariant.bordered,
                      leading: const Icon(Icons.person_outline_rounded),
                      child: const Text('Hover User Profile'),
                      onPressed: () {},
                    ),
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
