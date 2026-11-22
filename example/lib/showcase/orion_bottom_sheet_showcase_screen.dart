import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground for [OrionBottomSheet] and [showOrionBottomSheet].
class OrionBottomSheetShowcaseScreen extends StatefulWidget {
  const OrionBottomSheetShowcaseScreen({super.key});

  @override
  State<OrionBottomSheetShowcaseScreen> createState() =>
      _OrionBottomSheetShowcaseScreenState();
}

enum _SheetPresetDetents { twoTier, threeTier }

enum _SheetSkin { standard, frosted, bordered }

class _OrionBottomSheetShowcaseScreenState
    extends State<OrionBottomSheetShowcaseScreen> {
  final OrionSheetController _inlineController = OrionSheetController();

  _SheetPresetDetents _preset = _SheetPresetDetents.twoTier;
  _SheetSkin _skin = _SheetSkin.standard;
  bool _showHandle = true;
  bool _frosted = false;

  List<double> get _activeDetents => switch (_preset) {
    _SheetPresetDetents.twoTier => const [0.4, 0.85],
    _SheetPresetDetents.threeTier => const [0.25, 0.55, 0.90],
  };

  String _presetLabel(_SheetPresetDetents preset) => switch (preset) {
    _SheetPresetDetents.twoTier => '2-Tier [40%, 85%]',
    _SheetPresetDetents.threeTier => '3-Tier [25%, 55%, 90%]',
  };

  String _skinLabel(_SheetSkin skin) => switch (skin) {
    _SheetSkin.standard => 'Standard',
    _SheetSkin.frosted => 'Frosted',
    _SheetSkin.bordered => 'Bordered',
  };

  OrionBottomSheetStyle? _skinStyle(ColorScheme scheme) => switch (_skin) {
    _SheetSkin.standard => null,
    _SheetSkin.frosted => OrionBottomSheetStyle.from(frosted: true),
    _SheetSkin.bordered => OrionBottomSheetStyle.from(
      borderWidth: 2.0,
      borderColor: scheme.primary,
    ),
  };

  void _openModalSheet({OrionBottomSheetStyle? styleOverride}) {
    final scheme = Theme.of(context).colorScheme;
    final baseStyle =
        styleOverride ??
        (_skinStyle(scheme) ?? const OrionBottomSheetStyle()).copyWith(
          frosted: _frosted,
        );

    showOrionBottomSheet<void>(
      context: context,
      detents: _activeDetents,
      showDragHandle: _showHandle,
      style: baseStyle,
      builder: (context, scrollController) {
        return ListView.builder(
          controller: scrollController,
          itemCount: 25,
          padding: const EdgeInsets.symmetric(
            horizontal: OrionSpacing.space16,
            vertical: OrionSpacing.space8,
          ),
          itemBuilder: (context, index) {
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                child: Text('${index + 1}'),
              ),
              title: Text('Sheet Item ${index + 1}'),
              subtitle: const Text('Pull down at top to collapse or dismiss'),
            );
          },
        );
      },
    );
  }

  String get _snippet {
    final List<String> lines = <String>[
      'showOrionBottomSheet(',
      '  context: context,',
      '  detents: ${_activeDetents.map((d) => d.toString()).toList()},',
    ];
    if (!_showHandle) {
      lines.add('  showDragHandle: false,');
    }
    if (_frosted) {
      lines.add('  style: OrionBottomSheetStyle.from(frosted: true),');
    }
    lines.addAll(<String>[
      '  builder: (context, scrollController) => ListView(',
      '    controller: scrollController,',
      '    children: [...],',
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
      title: 'Orion Bottom Sheet',
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
                      'SURFACE • MULTI-SNAP DETENTS',
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
                    'Physics-driven multi-detent bottom sheet. Features continuous spring velocity projection, top rubber-banding, nested scroll cooperation, and modal presentation.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Hero Playground (top)
            OrionShowcaseSection(
              title: 'Playground',
              subtitle:
                  'Interactive workbench: test modal and inline sheets with live code generation',
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(OrionSpacing.space20),
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
                      child: Column(
                        children: [
                          Center(
                            child: OrionButton(
                              size: OrionButtonSize.medium,
                              variant: OrionButtonVariant.solid,
                              onPressed: _openModalSheet,
                              leading: const Icon(
                                Icons.open_in_new_rounded,
                                size: 18,
                              ),
                              child: const Text('Open Modal Bottom Sheet'),
                            ),
                          ),
                          const SizedBox(height: OrionSpacing.space12),
                          Text(
                            'Drag pill or scroll content down at top to test physics',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: OrionSpacing.space20),

                    OrionShowcaseChoice<_SheetPresetDetents>(
                      label: 'Detents',
                      values: _SheetPresetDetents.values,
                      selected: _preset,
                      labelOf: _presetLabel,
                      onChanged: (val) => setState(() => _preset = val),
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    Row(
                      children: [
                        Expanded(
                          child: OrionShowcaseToggle(
                            label: 'Drag handle',
                            value: _showHandle,
                            onChanged: (val) =>
                                setState(() => _showHandle = val),
                          ),
                        ),
                        Expanded(
                          child: OrionShowcaseToggle(
                            label: 'Frosted blur',
                            value: _frosted,
                            onChanged: (val) => setState(() => _frosted = val),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                code: _snippet,
              ),
            ),
            const SizedBox(height: OrionSpacing.space24),

            // Inline Stage Card
            OrionShowcaseSection(
              title: 'Embedded Inline Sheet',
              subtitle:
                  'Persistent sheet widget container with programmatic controller buttons',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: OrionSpacing.space8,
                    runSpacing: OrionSpacing.space8,
                    children: [
                      OrionButton(
                        size: OrionButtonSize.small,
                        variant: OrionButtonVariant.bordered,
                        onPressed: () => _inlineController.expand(),
                        child: const Text('Expand (Top)'),
                      ),
                      OrionButton(
                        size: OrionButtonSize.small,
                        variant: OrionButtonVariant.bordered,
                        onPressed: () => _inlineController.collapse(),
                        child: const Text('Collapse (Low)'),
                      ),
                      OrionButton(
                        size: OrionButtonSize.small,
                        variant: OrionButtonVariant.flat,
                        onPressed: () => _inlineController.dismiss(),
                        child: const Text('Dismiss'),
                      ),
                    ],
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  Container(
                    height: 280,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: isDark
                          ? scheme.surfaceContainerLowest
                          : scheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(OrionRadii.radius12),
                      border: Border.all(
                        color: isDark
                            ? scheme.outlineVariant.withValues(alpha: 0.15)
                            : scheme.outlineVariant.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Rich simulated map canvas so frosted glass blur is clearly visible
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFE2E8F0),
                                  isDark
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFCBD5E1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 40,
                                  left: 0,
                                  right: 0,
                                  height: 24,
                                  child: Container(
                                    color:
                                        (isDark
                                                ? Colors.white
                                                : const Color(0xFFF59E0B))
                                            .withValues(alpha: 0.15),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  bottom: 0,
                                  left: 120,
                                  width: 28,
                                  child: Container(
                                    color:
                                        (isDark
                                                ? Colors.white
                                                : const Color(0xFF3B82F6))
                                            .withValues(alpha: 0.15),
                                  ),
                                ),
                                Positioned(
                                  top: 25,
                                  left: 106,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x33000000),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.location_on_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 70,
                                  right: 32,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF334155)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x20000000),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.local_cafe,
                                          size: 14,
                                          color: Color(0xFFD97706),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Blue Bottle Coffee',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        OrionBottomSheet(
                          controller: _inlineController,
                          detents: const [0.35, 0.85],
                          initialDetentIndex: 0,
                          showDragHandle: true,
                          style:
                              (_skinStyle(scheme) ??
                                      const OrionBottomSheetStyle())
                                  .copyWith(frosted: _frosted),
                          builder: (context, scroll) => ListView(
                            controller: scroll,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: const [
                              Text(
                                'Inline Tray Content',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Swipe or use the buttons above to animate detents.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Customization Card
            OrionShowcaseSection(
              title: 'Customization',
              subtitle:
                  'Three-layer style contract: Presets -> OrionBottomSheetTheme -> Instance OrionBottomSheetStyle',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrionShowcaseChoice<_SheetSkin>(
                    label: 'Skin',
                    values: _SheetSkin.values,
                    selected: _skin,
                    labelOf: _skinLabel,
                    onChanged: (val) => setState(() => _skin = val),
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  OrionButton(
                    size: OrionButtonSize.small,
                    variant: OrionButtonVariant.bordered,
                    onPressed: () =>
                        _openModalSheet(styleOverride: _skinStyle(scheme)),
                    child: Text('Open ${_skinLabel(_skin)} Sheet'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
