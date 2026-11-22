import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground for [OrionPopover], [OrionMenu], and [showOrionMenu].
class OrionPopoverShowcaseScreen extends StatefulWidget {
  const OrionPopoverShowcaseScreen({super.key});

  @override
  State<OrionPopoverShowcaseScreen> createState() =>
      _OrionPopoverShowcaseScreenState();
}

enum _PopoverPlacementChoice {
  bottomStart,
  bottomCenter,
  bottomEnd,
  topStart,
  topCenter,
  topEnd,
}

enum _TriggerAlignChoice { start, center, end }

enum _PopoverSkinChoice { standard, frosted, bordered }

class _OrionPopoverShowcaseScreenState
    extends State<OrionPopoverShowcaseScreen> {
  _PopoverPlacementChoice _placement = _PopoverPlacementChoice.bottomStart;
  _TriggerAlignChoice _triggerAlign = _TriggerAlignChoice.center;
  _PopoverSkinChoice _skin = _PopoverSkinChoice.standard;
  bool _showArrow = false;
  bool _frosted = false;

  String _selectedAction = 'None';

  OrionPopoverPlacement get _activePlacement => switch (_placement) {
    _PopoverPlacementChoice.bottomStart => OrionPopoverPlacement.bottomStart,
    _PopoverPlacementChoice.bottomCenter => OrionPopoverPlacement.bottomCenter,
    _PopoverPlacementChoice.bottomEnd => OrionPopoverPlacement.bottomEnd,
    _PopoverPlacementChoice.topStart => OrionPopoverPlacement.topStart,
    _PopoverPlacementChoice.topCenter => OrionPopoverPlacement.topCenter,
    _PopoverPlacementChoice.topEnd => OrionPopoverPlacement.topEnd,
  };

  Alignment get _stageAlignment => switch (_triggerAlign) {
    _TriggerAlignChoice.start => Alignment.centerLeft,
    _TriggerAlignChoice.center => Alignment.center,
    _TriggerAlignChoice.end => Alignment.centerRight,
  };

  OrionPopoverStyle? _resolveSkinStyle(ColorScheme scheme) {
    final OrionPopoverStyle base = switch (_skin) {
      _PopoverSkinChoice.standard => const OrionPopoverStyle(),
      _PopoverSkinChoice.frosted => OrionPopoverStyle.from(frosted: true),
      _PopoverSkinChoice.bordered => OrionPopoverStyle.from(
        borderWidth: 2.0,
        borderColor: scheme.primary,
      ),
    };
    return base.copyWith(
      frosted: _frosted || _skin == _PopoverSkinChoice.frosted,
    );
  }

  String get _snippet {
    final List<String> lines = <String>[
      'OrionMenu(',
      '  placement: OrionPopoverPlacement.${_activePlacement.name},',
    ];
    if (_showArrow) {
      lines.add('  showArrow: true,');
    }
    if (_frosted || _skin == _PopoverSkinChoice.frosted) {
      lines.add('  style: OrionPopoverStyle.from(frosted: true),');
    }
    lines.addAll(<String>[
      '  triggerBuilder: (context, controller) => OrionButton(',
      '    variant: OrionButtonVariant.solid,',
      '    onPressed: controller.toggle,',
      '    child: const Text("Actions"),',
      '  ),',
      '  items: [',
      '    OrionMenuItem(title: "Edit", leading: Icon(Icons.edit_rounded)),',
      '    OrionMenuItem(title: "Share", leading: Icon(Icons.share_rounded)),',
      '    const OrionMenuItem.divider(),',
      '    OrionMenuItem(title: "Delete", destructive: true),',
      '  ],',
      ');',
    ]);
    return lines.join('\n');
  }

  void _openImperativeMenu(BuildContext context, GlobalKey buttonKey) {
    final RenderBox? box =
        buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final Offset origin = box.localToGlobal(Offset.zero);
    final Rect rect = origin & box.size;

    showOrionMenu<void>(
      context: context,
      anchorRect: rect,
      placement: _activePlacement,
      showArrow: _showArrow,
      style: _resolveSkinStyle(Theme.of(context).colorScheme),
      items: [
        OrionMenuItem(
          title: 'Quick Preview',
          leading: const Icon(Icons.visibility_rounded),
          onTap: () => setState(() => _selectedAction = 'Quick Preview'),
        ),
        OrionMenuItem(
          title: 'Download Copy',
          leading: const Icon(Icons.download_rounded),
          onTap: () => setState(() => _selectedAction = 'Download Copy'),
        ),
        const OrionMenuItem.divider(),
        OrionMenuItem(
          title: 'Trash Item',
          leading: const Icon(Icons.delete_outline_rounded),
          destructive: true,
          onTap: () => setState(() => _selectedAction = 'Trash Item'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final GlobalKey imperativeBtnKey = GlobalKey();

    return OrionThemedScaffold(
      title: 'Orion Popover & Menu',
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Category Header
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
                      borderRadius: BorderRadius.circular(OrionRadii.radiusPill),
                      border: Border.all(
                        color: isDark
                            ? scheme.outlineVariant.withValues(alpha: 0.20)
                            : scheme.outlineVariant.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'SURFACE • ANCHORED MENUS & POPOVERS',
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
                    'Origin-aware floating menus and contextual popovers scaling directly from trigger anchors with collision auto-flipping.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Hero Interactive Stage Card
            OrionShowcaseSection(
              title: 'Interactive Playground',
              subtitle:
                  'Tap the trigger button to blossom the popover outward from its anchor',
              card: true,
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 180,
                      width: double.infinity,
                      padding: const EdgeInsets.all(2.00),
                      decoration: BoxDecoration(
                        color: isDark
                            ? scheme.surfaceContainerLowest
                            : scheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(OrionRadii.radius12),
                        border: Border.all(
                          color: isDark
                              ? scheme.outlineVariant.withValues(alpha: 0.15)
                              : scheme.outlineVariant.withValues(alpha: 0.30),
                          width: 1,
                        ),
                      ),
                      child: Align(
                        alignment: _stageAlignment,
                        child: OrionMenu(
                          placement: _activePlacement,
                          showArrow: _showArrow,
                          style: _resolveSkinStyle(scheme),
                          triggerBuilder: (context, controller) => OrionButton(
                            variant: OrionButtonVariant.solid,
                            size: OrionButtonSize.medium,
                            onPressed: controller.toggle,
                            leading: const Icon(
                              Icons.more_horiz_rounded,
                              size: 18,
                            ),
                            child: const Text('Options Menu'),
                          ),
                          items: [
                            OrionMenuItem(
                              title: 'Copy Link',
                              leading: const Icon(Icons.link_rounded),
                              trailing: const Text('⌘C'),
                              onTap: () =>
                                  setState(() => _selectedAction = 'Copy Link'),
                            ),
                            OrionMenuItem(
                              title: 'Share File',
                              subtitle: 'Invite team members',
                              leading: const Icon(Icons.share_rounded),
                              onTap: () => setState(
                                () => _selectedAction = 'Share File',
                              ),
                            ),
                            OrionMenuItem(
                              title: 'Archive',
                              leading: const Icon(Icons.archive_outlined),
                              onTap: () =>
                                  setState(() => _selectedAction = 'Archive'),
                            ),
                            const OrionMenuItem.divider(),
                            OrionMenuItem(
                              title: 'Delete Item',
                              leading: const Icon(Icons.delete_outline_rounded),
                              destructive: true,
                              onTap: () => setState(
                                () => _selectedAction = 'Delete Item',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 2.00),
                    OrionShowcaseChoice<_PopoverPlacementChoice>(
                      label: 'Placement',
                      values: _PopoverPlacementChoice.values,
                      selected: _placement,
                      labelOf: (p) => p.name,
                      onChanged: (p) => setState(() => _placement = p),
                    ),
                    const SizedBox(height: OrionSpacing.space16),
                    OrionShowcaseChoice<_TriggerAlignChoice>(
                      label: 'Trigger align',
                      values: _TriggerAlignChoice.values,
                      selected: _triggerAlign,
                      labelOf: (a) => a.name,
                      onChanged: (a) => setState(() => _triggerAlign = a),
                    ),
                    const SizedBox(height: OrionSpacing.space16),
                    OrionShowcaseChoice<_PopoverSkinChoice>(
                      label: 'Skin',
                      values: _PopoverSkinChoice.values,
                      selected: _skin,
                      labelOf: (s) => s.name,
                      onChanged: (s) => setState(() {
                        _skin = s;
                        _frosted = s == _PopoverSkinChoice.frosted;
                      }),
                    ),
                    const SizedBox(height: OrionSpacing.space16),
                    Row(
                      children: [
                        Expanded(
                          child: OrionShowcaseToggle(
                            label: 'Show arrow',
                            value: _showArrow,
                            onChanged: (val) =>
                                setState(() => _showArrow = val),
                          ),
                        ),
                        const SizedBox(width: OrionSpacing.space16),
                        Expanded(
                          child: OrionShowcaseToggle(
                            label: 'Frosted blur',
                            value: _frosted,
                            onChanged: (val) => setState(() {
                              _frosted = val;
                              if (val) {
                                _skin = _PopoverSkinChoice.frosted;
                              } else if (_skin == _PopoverSkinChoice.frosted) {
                                _skin = _PopoverSkinChoice.standard;
                              }
                            }),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: OrionSpacing.space12),
                      child: Text(
                        'Last selected action: $_selectedAction',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                code: _snippet,
              ),
            ),
            const SizedBox(height: 2.04),

            // Frosted Glass Specimen Card
            OrionShowcaseSection(
              title: 'Frosted Glass Surface',
              subtitle:
                  'Static blur isolation filters colorful backgrounds behind the popover without per-frame GPU re-sampling',
              card: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(2.00),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(OrionRadii.radius12),
                  gradient: LinearGradient(
                    colors: [scheme.primaryContainer, scheme.tertiaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surface.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'TRANSLUCENT SPECIMEN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Frosted blur over vibrant gradient backdrop',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap below to open the frosted popover menu directly over this colorful gradient to verify the blur.',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: OrionMenu(
                        placement: OrionPopoverPlacement.bottomCenter,
                        showArrow: true,
                        style: OrionPopoverStyle.from(frosted: true),
                        triggerBuilder: (context, controller) => OrionButton(
                          variant: OrionButtonVariant.solid,
                          size: OrionButtonSize.medium,
                          onPressed: controller.toggle,
                          leading: const Icon(Icons.blur_on_rounded, size: 18),
                          child: const Text('Open Frosted Menu'),
                        ),
                        items: [
                          OrionMenuItem(
                            title: 'View Analytics',
                            leading: const Icon(Icons.insights_rounded),
                            onTap: () => setState(
                              () => _selectedAction = 'View Analytics',
                            ),
                          ),
                          OrionMenuItem(
                            title: 'Export Palette',
                            leading: const Icon(Icons.color_lens_outlined),
                            onTap: () => setState(
                              () => _selectedAction = 'Export Palette',
                            ),
                          ),
                          const OrionMenuItem.divider(),
                          OrionMenuItem(
                            title: 'Reset Theme',
                            leading: const Icon(Icons.refresh_rounded),
                            destructive: true,
                            onTap: () =>
                                setState(() => _selectedAction = 'Reset Theme'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 2.04),

            // Imperative Invocation Card
            OrionShowcaseSection(
              title: 'Imperative `showOrionMenu`',
              subtitle:
                  'Present a contextual floating menu on the navigator from anywhere using an anchor rect',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tap the button below to trigger the imperative modal route menu. The route anchors to the button bounds and supports tap-outside / hardware back dismiss.',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  OrionButton(
                    key: imperativeBtnKey,
                    variant: OrionButtonVariant.bordered,
                    onPressed: () =>
                        _openImperativeMenu(context, imperativeBtnKey),
                    leading: const Icon(Icons.open_in_new_rounded, size: 18),
                    child: const Text('Open Imperative Menu'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2.04),

            // Custom Content Popover Card
            OrionShowcaseSection(
              title: 'Custom Popover Content',
              subtitle:
                  '`OrionPopover` accepts any arbitrary widget subtree for rich tooltips, profile cards, or filters',
              card: true,
              child: Center(
                child: OrionPopover(
                  placement: OrionPopoverPlacement.bottomCenter,
                  showArrow: true,
                  style: OrionPopoverStyle.from(
                    padding: const EdgeInsets.all(OrionSpacing.space16),
                    minWidth: 240,
                  ),
                  triggerBuilder: (context, controller) => OrionButton(
                    variant: OrionButtonVariant.flat,
                    onPressed: controller.toggle,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.account_circle_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Profile Card Popover'),
                      ],
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        child: Icon(Icons.person, size: 32),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Ahmad Fikril',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Design Engineer',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OrionButton(
                          size: OrionButtonSize.small,
                          variant: OrionButtonVariant.bordered,
                          onPressed: () {},
                          child: const Text('Manage Account'),
                        ),
                      ),
                    ],
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
