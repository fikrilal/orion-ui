import 'package:flutter/material.dart';
import 'package:orion_ui/orion_ui.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';

/// Playground and verification showcase for [OrionTooltip].
class OrionTooltipShowcaseScreen extends StatefulWidget {
  const OrionTooltipShowcaseScreen({super.key});

  @override
  State<OrionTooltipShowcaseScreen> createState() =>
      _OrionTooltipShowcaseScreenState();
}

class _OrionTooltipShowcaseScreenState
    extends State<OrionTooltipShowcaseScreen> {
  OrionTooltipPlacement _placement = OrionTooltipPlacement.top;
  OrionTooltipTone _tone = OrionTooltipTone.inverted;
  OrionTooltipTriggerMode _triggerMode =
      OrionTooltipTriggerMode.hoverAndLongPress;
  bool _showArrow = true;
  bool _frosted = false;
  int _playgroundPresses = 0;

  final OrionTooltipController _manualController = OrionTooltipController();

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  String get _snippet {
    final List<String> lines = <String>[
      'OrionTooltip(',
      "  message: 'Quick action tooltip with spring glide',",
      '  placement: OrionTooltipPlacement.${_placement.name},',
    ];
    if (_tone != OrionTooltipTone.inverted) {
      lines.add('  tone: OrionTooltipTone.${_tone.name},');
    }
    if (_triggerMode != OrionTooltipTriggerMode.hoverAndLongPress) {
      lines.add('  triggerMode: OrionTooltipTriggerMode.${_triggerMode.name},');
    }
    if (!_showArrow) {
      lines.add('  showArrow: false,');
    }
    if (_frosted) {
      lines.add('  style: OrionTooltipStyle.from(frosted: true),');
    }
    lines.addAll(<String>[
      '  child: OrionButton(',
      '    variant: OrionButtonVariant.solid,',
      '    onPressed: () {},',
      "    child: const Text('Hover or Press Me'),",
      '  ),',
      ');',
    ]);
    return lines.join('\n');
  }

  String get _playgroundHint => switch (_triggerMode) {
    OrionTooltipTriggerMode.hoverAndLongPress =>
      'Hover on desktop or long-press on touch',
    OrionTooltipTriggerMode.tap =>
      'Tap toggles the tooltip without blocking the button',
    OrionTooltipTriggerMode.longPress =>
      'Press & hold for haptic tooltip (auto-hides in 1.8 s)',
    OrionTooltipTriggerMode.hoverOnly => 'Pointer hover or Tab focus',
    OrionTooltipTriggerMode.manual => 'Controlled via OrionTooltipController',
  };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color stageBg = isDark
        ? scheme.surfaceContainer
        : scheme.surfaceContainerHighest.withValues(alpha: 0.45);
    final Color stageBorder = scheme.outlineVariant;

    return OrionThemedScaffold(
      title: 'Orion Tooltip',
      builder: (BuildContext context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Top Intro Header
            Padding(
              padding: const EdgeInsets.only(bottom: OrionSpacing.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
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
                            ? scheme.outlineVariant.withValues(alpha: 0.25)
                            : scheme.outlineVariant.withValues(alpha: 0.50),
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
                    'Anchor-aware tooltips with spring physics, single-active warm '
                    'window handoff, safe-area & mobile cross-axis fallback, keyboard '
                    'focus support, and inverted or surface card tones.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  // Reactive Warm Window Status Pill (zero polling)
                  ValueListenableBuilder<bool>(
                    valueListenable: OrionTooltipWarmCoordinator.listenable,
                    builder: (BuildContext context, bool isWarm, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: OrionSpacing.space12,
                          vertical: OrionSpacing.space4,
                        ),
                        decoration: BoxDecoration(
                          color: isWarm
                              ? scheme.primary.withValues(alpha: 0.12)
                              : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            OrionRadii.radiusPill,
                          ),
                          border: Border.all(
                            color: isWarm
                                ? scheme.primary.withValues(alpha: 0.35)
                                : scheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isWarm
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant.withValues(
                                        alpha: 0.45,
                                      ),
                              ),
                            ),
                            const SizedBox(width: OrionSpacing.space8),
                            Text(
                              isWarm
                                  ? 'Warm Window Active (0ms Handoff)'
                                  : 'Warm Window Cold (250ms Delay)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isWarm
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 1. Hero Interactive Playground
            OrionShowcaseSection(
              title: 'Interactive Playground',
              subtitle:
                  'Test placements (including mobile cross-axis fallback), inverted vs surface tones, tap over buttons, arrow, and frosted glass.',
              card: true,
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                code: _snippet,
                preview: Column(
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      height: 176,
                      padding: const EdgeInsets.all(OrionSpacing.space16),
                      decoration: BoxDecoration(
                        color: stageBg,
                        borderRadius: BorderRadius.circular(
                          OrionRadii.radius12,
                        ),
                        border: Border.all(color: stageBorder),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          OrionTooltip(
                            message: 'Quick action tooltip with spring glide',
                            placement: _placement,
                            tone: _tone,
                            triggerMode: _triggerMode,
                            showArrow: _showArrow,
                            style: _frosted
                                ? OrionTooltipStyle.from(frosted: true)
                                : null,
                            child: OrionButton(
                              variant: OrionButtonVariant.solid,
                              onPressed: () {
                                setState(() => _playgroundPresses++);
                              },
                              leading: const Icon(
                                Icons.touch_app_rounded,
                                size: 16,
                              ),
                              child: const Text('Hover or Press Me'),
                            ),
                          ),
                          const SizedBox(height: OrionSpacing.space12),
                          Text(
                            _playgroundPresses > 0
                                ? '$_playgroundHint • Pressed $_playgroundPresses×'
                                : _playgroundHint,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: OrionSpacing.space16),
                    OrionShowcaseControls(
                      children: <Widget>[
                        OrionShowcaseChoice<OrionTooltipPlacement>(
                          label: 'Placement',
                          selected: _placement,
                          values: const <OrionTooltipPlacement>[
                            OrionTooltipPlacement.top,
                            OrionTooltipPlacement.bottom,
                            OrionTooltipPlacement.left,
                            OrionTooltipPlacement.right,
                            OrionTooltipPlacement.start,
                            OrionTooltipPlacement.end,
                          ],
                          labelOf: (OrionTooltipPlacement p) =>
                              p.name[0].toUpperCase() + p.name.substring(1),
                          onChanged: (OrionTooltipPlacement p) =>
                              setState(() => _placement = p),
                        ),
                        OrionShowcaseChoice<OrionTooltipTone>(
                          label: 'Tone',
                          selected: _tone,
                          values: const <OrionTooltipTone>[
                            OrionTooltipTone.inverted,
                            OrionTooltipTone.surface,
                          ],
                          labelOf: (OrionTooltipTone t) => switch (t) {
                            OrionTooltipTone.inverted => 'Inverted',
                            OrionTooltipTone.surface => 'Surface',
                          },
                          onChanged: (OrionTooltipTone t) =>
                              setState(() => _tone = t),
                        ),
                        OrionShowcaseChoice<OrionTooltipTriggerMode>(
                          label: 'Trigger Mode',
                          selected: _triggerMode,
                          values: const <OrionTooltipTriggerMode>[
                            OrionTooltipTriggerMode.hoverAndLongPress,
                            OrionTooltipTriggerMode.tap,
                            OrionTooltipTriggerMode.longPress,
                          ],
                          labelOf: (OrionTooltipTriggerMode m) => switch (m) {
                            OrionTooltipTriggerMode.hoverAndLongPress =>
                              'Hover / Hold',
                            OrionTooltipTriggerMode.tap => 'Tap',
                            OrionTooltipTriggerMode.longPress => 'Long-Press',
                            _ => m.name,
                          },
                          onChanged: (OrionTooltipTriggerMode m) =>
                              setState(() => _triggerMode = m),
                        ),
                        OrionShowcaseToggle(
                          label: 'Caret Arrow',
                          value: _showArrow,
                          onChanged: (bool v) => setState(() => _showArrow = v),
                        ),
                        OrionShowcaseToggle(
                          label: 'Frosted Glass',
                          value: _frosted,
                          onChanged: (bool v) => setState(() => _frosted = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: OrionSpacing.space20),

            // 2. Warm Window Toolbar Specimen
            OrionShowcaseSection(
              title: 'Warm Window Toolbar',
              subtitle:
                  'Hover across icons on desktop for 0ms single-active handoff (no overlap), or long-press on mobile.',
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
                    horizontal: OrionSpacing.space12,
                    vertical: OrionSpacing.space8,
                  ),
                  decoration: BoxDecoration(
                    color: stageBg,
                    borderRadius: BorderRadius.circular(OrionRadii.radius12),
                    border: Border.all(color: stageBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      _ToolbarTooltipButton(
                        label: 'Bold',
                        shortcut: '⌘B',
                        icon: Icons.format_bold_rounded,
                      ),
                      _ToolbarTooltipButton(
                        label: 'Italic',
                        shortcut: '⌘I',
                        icon: Icons.format_italic_rounded,
                      ),
                      _ToolbarTooltipButton(
                        label: 'Underline',
                        shortcut: '⌘U',
                        icon: Icons.format_underlined_rounded,
                      ),
                      _ToolbarTooltipButton(
                        label: 'Strike',
                        shortcut: '⇧⌘X',
                        icon: Icons.strikethrough_s_rounded,
                      ),
                      _ToolbarTooltipButton(
                        label: 'Code',
                        shortcut: '⌘E',
                        icon: Icons.code_rounded,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: OrionSpacing.space20),

            // 3. Rich Contextual Bubbles (Surface Card + Inverted Shortcut)
            OrionShowcaseSection(
              title: 'Rich Contextual Bubbles',
              subtitle:
                  'Surface tone gives rich profiles and multi-line details a bordered card; inverted tone auto-styles uncolored icons and text.',
              card: true,
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-rich'),
                code: '''
OrionTooltip(
  message: 'Jane Doe profile',
  tone: OrionTooltipTone.surface,
  triggerMode: OrionTooltipTriggerMode.tap,
  placement: OrionTooltipPlacement.bottom,
  richMessage: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      CircleAvatar(child: Text('JD')),
      Text('Jane Doe — Lead Designer'),
    ],
  ),
  child: OrionButton(...),
)''',
                preview: Wrap(
                  spacing: OrionSpacing.space12,
                  runSpacing: OrionSpacing.space12,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    OrionTooltip(
                      message: 'Jane Doe — Lead Designer (Online)',
                      tone: OrionTooltipTone.surface,
                      triggerMode: OrionTooltipTriggerMode.tap,
                      placement: OrionTooltipPlacement.bottom,
                      style: OrionTooltipStyle.from(
                        maxWidth: 260.0,
                        padding: const EdgeInsets.all(OrionSpacing.space12),
                        borderRadius: BorderRadius.circular(
                          OrionRadii.radius12,
                        ),
                      ),
                      richMessage: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: scheme.primary,
                            child: Text(
                              'JD',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: scheme.onPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: OrionSpacing.space12),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Jane Doe',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2.0),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF22C55E),
                                    ),
                                  ),
                                  const SizedBox(width: OrionSpacing.space4),
                                  Text(
                                    'Lead Designer • Online',
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
                        leading: const Icon(
                          Icons.person_outline_rounded,
                          size: 16,
                        ),
                        onPressed: () {},
                        child: const Text('Tap User Profile'),
                      ),
                    ),
                    OrionTooltip(
                      message: 'Copy share link (Cmd+Shift+C)',
                      triggerMode: OrionTooltipTriggerMode.tap,
                      placement: OrionTooltipPlacement.top,
                      richMessage: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(Icons.link_rounded),
                          SizedBox(width: 6),
                          Text('Copy share link'),
                        ],
                      ),
                      child: OrionButton(
                        variant: OrionButtonVariant.bordered,
                        leading: const Icon(Icons.link_rounded, size: 16),
                        onPressed: () {},
                        child: const Text('Inverted Rich'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: OrionSpacing.space20),

            // 4. Edge Collision & Programmatic Controller
            OrionShowcaseSection(
              title: 'Edge Clamping & Programmatic Control',
              subtitle:
                  'Edge triggers keep the caret aligned inside rounded corners, and manual controllers stay pinned until explicitly toggled.',
              card: true,
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-edge-manual'),
                code: '''
OrionTooltip(
  controller: controller,
  triggerMode: OrionTooltipTriggerMode.manual,
  dismissOnTapOutside: false,
  message: 'Pinned manual callout',
  child: ...,
)''',
                preview: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        OrionTooltip(
                          message:
                              'Clamped cleanly to the left viewport edge with safe caret inset',
                          triggerMode: OrionTooltipTriggerMode.tap,
                          placement: OrionTooltipPlacement.top,
                          child: OrionButton(
                            size: OrionButtonSize.small,
                            variant: OrionButtonVariant.bordered,
                            onPressed: () {},
                            child: const Text('Left Edge'),
                          ),
                        ),
                        OrionTooltip(
                          message:
                              'Clamped cleanly to the right viewport edge with safe caret inset',
                          triggerMode: OrionTooltipTriggerMode.tap,
                          placement: OrionTooltipPlacement.top,
                          child: OrionButton(
                            size: OrionButtonSize.small,
                            variant: OrionButtonVariant.bordered,
                            onPressed: () {},
                            child: const Text('Right Edge'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: OrionSpacing.space16),
                    AnimatedBuilder(
                      animation: _manualController,
                      builder: (BuildContext context, _) {
                        final bool isOpen = _manualController.isOpen;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            OrionTooltip(
                              controller: _manualController,
                              triggerMode: OrionTooltipTriggerMode.manual,
                              dismissOnTapOutside: false,
                              tone: OrionTooltipTone.surface,
                              message:
                                  'Pinned manually — stays open until toggled or Escape',
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: OrionSpacing.space12,
                                  vertical: OrionSpacing.space8,
                                ),
                                decoration: BoxDecoration(
                                  color: stageBg,
                                  borderRadius: BorderRadius.circular(
                                    OrionRadii.radius8,
                                  ),
                                  border: Border.all(color: stageBorder),
                                ),
                                child: Text(
                                  'Anchor Target',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                            OrionButton(
                              size: OrionButtonSize.small,
                              variant: isOpen
                                  ? OrionButtonVariant.solid
                                  : OrionButtonVariant.bordered,
                              onPressed: _manualController.toggle,
                              child: Text(
                                isOpen ? 'Hide Manual' : 'Show Manual',
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ToolbarTooltipButton extends StatelessWidget {
  const _ToolbarTooltipButton({
    required this.label,
    required this.shortcut,
    required this.icon,
  });

  final String label;
  final String shortcut;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return OrionTooltip(
      message: '$label ($shortcut)',
      placement: OrionTooltipPlacement.top,
      richMessage: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: scheme.onInverseSurface.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              shortcut,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      child: IconButton(icon: Icon(icon, size: 20), onPressed: () {}),
    );
  }
}
