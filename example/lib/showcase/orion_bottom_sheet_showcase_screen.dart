import 'package:flutter/material.dart';
import 'package:orion_ui/orion_ui.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';

/// Playground for [OrionBottomSheet] and [showOrionBottomSheet].
class OrionBottomSheetShowcaseScreen extends StatefulWidget {
  const OrionBottomSheetShowcaseScreen({super.key});

  @override
  State<OrionBottomSheetShowcaseScreen> createState() =>
      _OrionBottomSheetShowcaseScreenState();
}

enum _SheetMode { fitContent, twoTier, threeTier }

enum _SheetSkin { standard, frosted, bordered }

class _OrionBottomSheetShowcaseScreenState
    extends State<OrionBottomSheetShowcaseScreen> {
  final OrionSheetController _inlineController = OrionSheetController();

  _SheetMode _mode = _SheetMode.fitContent;
  OrionBottomSheetVariant _variant = OrionBottomSheetVariant.floating;
  _SheetSkin _skin = _SheetSkin.standard;
  bool _showHandle = true;
  bool _showHeader = true;
  bool _frosted = false;
  String? _lastActionResult;

  List<double> get _activeDetents => switch (_mode) {
    _SheetMode.fitContent => const <double>[0.5, 0.9],
    _SheetMode.twoTier => const <double>[0.4, 0.85],
    _SheetMode.threeTier => const <double>[0.25, 0.55, 0.90],
  };

  String _modeLabel(_SheetMode mode) => switch (mode) {
    _SheetMode.fitContent => 'Fit content',
    _SheetMode.twoTier => '2-Tier [40%, 85%]',
    _SheetMode.threeTier => '3-Tier [25%, 55%, 90%]',
  };

  String _variantLabel(OrionBottomSheetVariant variant) => switch (variant) {
    OrionBottomSheetVariant.floating => 'Floating',
    OrionBottomSheetVariant.edgeToEdge => 'Edge-to-edge',
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

  Future<void> _openModalSheet({
    OrionBottomSheetStyle? styleOverride,
    OrionBottomSheetVariant? variantOverride,
    bool? fitOverride,
  }) async {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final OrionBottomSheetStyle baseStyle =
        styleOverride ??
        (_skinStyle(scheme) ?? const OrionBottomSheetStyle()).copyWith(
          frosted: _frosted,
        );
    final bool fit = fitOverride ?? (_mode == _SheetMode.fitContent);
    final OrionBottomSheetVariant variant = variantOverride ?? _variant;

    final String? result = await showOrionBottomSheet<String>(
      context: context,
      fitContent: fit,
      detents: _activeDetents,
      variant: variant,
      title: _showHeader ? (fit ? 'Quick Actions' : 'Explore Items') : null,
      subtitle: _showHeader
          ? (fit
                ? 'Auto-sized to content height with spring dismiss'
                : 'Drag handle or scroll past top to transition detents')
          : null,
      showCloseButton: _showHeader,
      showDragHandle: _showHandle,
      style: baseStyle,
      builder: (BuildContext sheetContext, ScrollController scrollController) {
        if (fit) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              OrionSpacing.space16,
              0,
              OrionSpacing.space16,
              OrionSpacing.space16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const OrionTextField(
                  hint: 'Add a quick note (tests keyboard lift)...',
                ),
                const SizedBox(height: OrionSpacing.space16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OrionButton(
                        label: 'Cancel',
                        variant: OrionButtonVariant.bordered,
                        isExpanded: true,
                        onPressed: () =>
                            OrionBottomSheet.dismissOf(sheetContext, 'Cancelled'),
                      ),
                    ),
                    const SizedBox(width: OrionSpacing.space12),
                    Expanded(
                      child: OrionButton(
                        label: 'Confirm',
                        variant: OrionButtonVariant.solid,
                        isExpanded: true,
                        onPressed: () =>
                            OrionBottomSheet.dismissOf(sheetContext, 'Confirmed'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: 25,
                padding: const EdgeInsets.symmetric(
                  horizontal: OrionSpacing.space16,
                ),
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: Text('${index + 1}'),
                    ),
                    title: Text('Sheet Item ${index + 1}'),
                    subtitle: const Text(
                      'Scroll down continuously past top to collapse',
                    ),
                    onTap: () => OrionBottomSheet.dismissOf(
                      sheetContext,
                      'Picked Item ${index + 1}',
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(OrionSpacing.space16),
              child: OrionButton(
                label: 'Done',
                isExpanded: true,
                onPressed: () =>
                    OrionBottomSheet.dismissOf(sheetContext, 'Done'),
              ),
            ),
          ],
        );
      },
    );

    if (mounted && result != null) {
      setState(() => _lastActionResult = result);
    }
  }

  String get _snippet {
    final bool fit = _mode == _SheetMode.fitContent;
    final List<String> lines = <String>[
      'final result = await showOrionBottomSheet<String>(',
      '  context: context,',
      '  variant: OrionBottomSheetVariant.${_variant.name},',
      if (fit)
        '  fitContent: true,'
      else
        '  detents: ${_activeDetents.map((double d) => d.toString()).toList()},',
    ];
    if (_showHeader) {
      lines.add("  title: '${fit ? 'Quick Actions' : 'Explore Items'}',");
      lines.add('  showCloseButton: true,');
    }
    if (!_showHandle) {
      lines.add('  showDragHandle: false,');
    }
    if (_frosted) {
      lines.add('  style: OrionBottomSheetStyle.from(frosted: true),');
    }
    lines.addAll(<String>[
      '  builder: (context, scrollController) => ...,',
      ');',
    ]);
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return OrionThemedScaffold(
      title: 'Orion Bottom Sheet',
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
                            ? scheme.outlineVariant.withValues(alpha: 0.20)
                            : scheme.outlineVariant.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'SURFACE • FIT-CONTENT & MULTI-DETENT',
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
                    'Physics-driven bottom sheet supporting intrinsic content sizing, multi-snap detents, floating card or edge-to-edge layout, keyboard lift, and seamless nested scroll handoff.',
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
                  'Test floating vs edge-to-edge, fit-content vs multi-detent, keyboard avoidance, and typed results',
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(OrionSpacing.space20),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(
                          OrionRadii.radius12,
                        ),
                        border: Border.all(
                          color: isDark
                              ? scheme.outlineVariant.withValues(alpha: 0.15)
                              : scheme.outlineVariant.withValues(alpha: 0.30),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          Center(
                            child: OrionButton(
                              label: 'Open Modal Bottom Sheet',
                              size: OrionButtonSize.medium,
                              variant: OrionButtonVariant.solid,
                              onPressed: _openModalSheet,
                              leading: const Icon(
                                Icons.open_in_new_rounded,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: OrionSpacing.space12),
                          Text(
                            _lastActionResult == null
                                ? 'Try focusing the input inside Fit Content, or dragging smoothly across detents'
                                : 'Last returned result: $_lastActionResult',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: OrionSpacing.space20),

                    OrionShowcaseChoice<OrionBottomSheetVariant>(
                      label: 'Variant',
                      values: OrionBottomSheetVariant.values,
                      selected: _variant,
                      labelOf: _variantLabel,
                      onChanged: (OrionBottomSheetVariant val) =>
                          setState(() => _variant = val),
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    OrionShowcaseChoice<_SheetMode>(
                      label: 'Sizing mode',
                      values: _SheetMode.values,
                      selected: _mode,
                      labelOf: _modeLabel,
                      onChanged: (_SheetMode val) =>
                          setState(() => _mode = val),
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OrionShowcaseToggle(
                            label: 'Handle',
                            value: _showHandle,
                            onChanged: (bool val) =>
                                setState(() => _showHandle = val),
                          ),
                        ),
                        Expanded(
                          child: OrionShowcaseToggle(
                            label: 'Header',
                            value: _showHeader,
                            onChanged: (bool val) =>
                                setState(() => _showHeader = val),
                          ),
                        ),
                        Expanded(
                          child: OrionShowcaseToggle(
                            label: 'Frosted',
                            value: _frosted,
                            onChanged: (bool val) =>
                                setState(() => _frosted = val),
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
                children: <Widget>[
                  Wrap(
                    spacing: OrionSpacing.space8,
                    runSpacing: OrionSpacing.space8,
                    children: <Widget>[
                      OrionButton(
                        label: 'Expand (Top)',
                        size: OrionButtonSize.small,
                        variant: OrionButtonVariant.bordered,
                        onPressed: () => _inlineController.expand(),
                      ),
                      OrionButton(
                        label: 'Collapse (Low)',
                        size: OrionButtonSize.small,
                        variant: OrionButtonVariant.bordered,
                        onPressed: () => _inlineController.collapse(),
                      ),
                      OrionButton(
                        label: 'Dismiss',
                        size: OrionButtonSize.small,
                        variant: OrionButtonVariant.flat,
                        onPressed: () => _inlineController.dismiss(),
                      ),
                    ],
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  Container(
                    height: 280,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(OrionRadii.radius12),
                      border: Border.all(
                        color: isDark
                            ? scheme.outlineVariant.withValues(alpha: 0.15)
                            : scheme.outlineVariant.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[
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
                              children: <Widget>[
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
                                      boxShadow: <BoxShadow>[
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
                              ],
                            ),
                          ),
                        ),
                        OrionBottomSheet(
                          controller: _inlineController,
                          detents: const <double>[0.35, 0.85],
                          initialDetentIndex: 0,
                          showDragHandle: true,
                          style:
                              (_skinStyle(scheme) ??
                                      const OrionBottomSheetStyle())
                                  .copyWith(frosted: _frosted),
                          builder:
                              (BuildContext context, ScrollController scroll) =>
                                  ListView(
                                    controller: scroll,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    children: const <Widget>[
                                      Text(
                                        'Inline Tray Content',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
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
                children: <Widget>[
                  OrionShowcaseChoice<_SheetSkin>(
                    label: 'Skin',
                    values: _SheetSkin.values,
                    selected: _skin,
                    labelOf: _skinLabel,
                    onChanged: (_SheetSkin val) => setState(() => _skin = val),
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  OrionButton(
                    label: 'Open ${_skinLabel(_skin)} Sheet',
                    size: OrionButtonSize.small,
                    variant: OrionButtonVariant.bordered,
                    onPressed: () =>
                        _openModalSheet(styleOverride: _skinStyle(scheme)),
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
