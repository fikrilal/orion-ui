import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground for [OrionToast] and [OrionToaster].
class OrionToastShowcaseScreen extends StatefulWidget {
  const OrionToastShowcaseScreen({super.key});

  @override
  State<OrionToastShowcaseScreen> createState() =>
      _OrionToastShowcaseScreenState();
}

enum _ToastSkin { standard, frosted, bordered }

class _OrionToastShowcaseScreenState extends State<OrionToastShowcaseScreen> {
  OrionToastStatus _status = OrionToastStatus.success;
  OrionToastPosition _position = OrionToastPosition.bottomCenter;
  _ToastSkin _skin = _ToastSkin.standard;
  bool _hasAction = false;
  bool _dismissible = true;

  String _statusLabel(OrionToastStatus status) => switch (status) {
    OrionToastStatus.neutral => 'Neutral',
    OrionToastStatus.info => 'Info',
    OrionToastStatus.success => 'Success',
    OrionToastStatus.warning => 'Warning',
    OrionToastStatus.error => 'Error',
    OrionToastStatus.loading => 'Loading',
  };

  String _positionLabel(OrionToastPosition pos) => switch (pos) {
    OrionToastPosition.topCenter => 'Top',
    OrionToastPosition.bottomCenter => 'Bottom',
  };

  String _skinLabel(_ToastSkin skin) => switch (skin) {
    _ToastSkin.standard => 'Standard',
    _ToastSkin.frosted => 'Frosted',
    _ToastSkin.bordered => 'Bordered',
  };

  OrionToastStyle? _skinStyle(ColorScheme scheme) => switch (_skin) {
    _ToastSkin.standard => null,
    _ToastSkin.frosted => OrionToastStyle.from(frosted: true),
    _ToastSkin.bordered => OrionToastStyle.from(
      borderWidth: 2.0,
      borderColor: scheme.primary,
    ),
  };

  void _fireToast() {
    OrionToast.show(
      'Notification title',
      description: 'This is a description message providing details.',
      status: _status,
      dismissible: _dismissible,
      action: _hasAction
          ? OrionToastAction(label: 'Action', onPressed: () {})
          : null,
      style: _skinStyle(Theme.of(context).colorScheme),
    );
  }

  Future<void> _firePromise() async {
    await OrionToast.promise(
      Future<String>.delayed(
        const Duration(milliseconds: 1400),
        () => 'Deploy v1.4.0',
      ),
      loading: 'Deploying release...',
      success: (result) => 'Successfully deployed: $result',
      error: (err) => 'Deployment failed',
      action: OrionToastAction(label: 'View', onPressed: () {}),
    );
  }

  String get _snippet {
    final List<String> lines = <String>[
      'OrionToast.show(',
      "  'Notification title',",
      "  description: 'This is a description message.',",
      '  status: OrionToastStatus.${_status.name},',
    ];
    if (_hasAction) {
      lines.addAll(<String>[
        '  action: OrionToastAction(',
        "    label: 'Action',",
        '    onPressed: () {},',
        '  ),',
      ]);
    }
    if (!_dismissible) {
      lines.add('  dismissible: false,');
    }
    lines.add(');');
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return OrionThemedScaffold(
      title: 'Orion Toast',
      builder: (context) {
        return OrionToaster(
          position: _position,
          child: Column(
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
                        'NOTIFICATION • 3D PERSPECTIVE STACK',
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
                      'Sonner-style stacked toasts. Features 3-tier perspective depth, interactive expand-on-hold, kinetic swipe dismissal, and promise lifecycle morphing.',
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
                    'Configure toast options, trigger alerts, and inspect generated code',
                child: OrionShowcasePanel(
                  key: const ValueKey<String>('showcase-panel-playground'),
                  preview: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(OrionSpacing.space16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? scheme.surfaceContainerLowest
                              : scheme.surfaceContainerLowest,
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
                          children: [
                            Wrap(
                              spacing: OrionSpacing.space8,
                              runSpacing: OrionSpacing.space8,
                              alignment: WrapAlignment.center,
                              children: [
                                OrionButton(
                                  size: OrionButtonSize.small,
                                  onPressed: _fireToast,
                                  leading: const Icon(
                                    Icons.bolt_rounded,
                                    size: 16,
                                  ),
                                  child: const Text('Fire Toast'),
                                ),
                                OrionButton(
                                  size: OrionButtonSize.small,
                                  variant: OrionButtonVariant.bordered,
                                  onPressed: _firePromise,
                                  leading: const Icon(
                                    Icons.sync_rounded,
                                    size: 16,
                                  ),
                                  child: const Text('Trigger Promise'),
                                ),
                                OrionButton(
                                  size: OrionButtonSize.small,
                                  variant: OrionButtonVariant.flat,
                                  onPressed: () => OrionToast.dismiss(),
                                  child: const Text('Dismiss Top'),
                                ),
                                OrionButton(
                                  size: OrionButtonSize.small,
                                  variant: OrionButtonVariant.flat,
                                  onPressed: () => OrionToast.clear(),
                                  child: const Text('Clear All'),
                                ),
                              ],
                            ),
                            const SizedBox(height: OrionSpacing.space12),
                            Text(
                              'Toasts stack at bottom. Swipe horizontally or hold to expand.',
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

                      OrionShowcaseChoice<OrionToastStatus>(
                        label: 'Status',
                        values: OrionToastStatus.values,
                        selected: _status,
                        labelOf: _statusLabel,
                        onChanged: (val) => setState(() => _status = val),
                      ),
                      const SizedBox(height: OrionSpacing.space16),

                      OrionShowcaseChoice<OrionToastPosition>(
                        label: 'Position',
                        values: OrionToastPosition.values,
                        selected: _position,
                        labelOf: _positionLabel,
                        onChanged: (val) => setState(() => _position = val),
                      ),
                      const SizedBox(height: OrionSpacing.space16),

                      Row(
                        children: [
                          Expanded(
                            child: OrionShowcaseToggle(
                              label: 'Action button',
                              value: _hasAction,
                              onChanged: (val) =>
                                  setState(() => _hasAction = val),
                            ),
                          ),
                          Expanded(
                            child: OrionShowcaseToggle(
                              label: 'Dismissible',
                              value: _dismissible,
                              onChanged: (val) =>
                                  setState(() => _dismissible = val),
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

              // Status Matrix Card
              OrionShowcaseSection(
                title: 'Typed Statuses',
                subtitle:
                    'Semantic status roles mapping icons and accents to scheme colors',
                card: true,
                child: Wrap(
                  spacing: OrionSpacing.space8,
                  runSpacing: OrionSpacing.space8,
                  children: [
                    OrionButton(
                      size: OrionButtonSize.small,
                      variant: OrionButtonVariant.bordered,
                      onPressed: () => OrionToast.success('Saved to project'),
                      leading: const Icon(Icons.check_circle_outline, size: 16),
                      child: const Text('Success'),
                    ),
                    OrionButton(
                      size: OrionButtonSize.small,
                      variant: OrionButtonVariant.bordered,
                      onPressed: () => OrionToast.error(
                        'Upload failed',
                        description: 'Please check your connection and retry.',
                      ),
                      leading: const Icon(Icons.error_outline, size: 16),
                      child: const Text('Error'),
                    ),
                    OrionButton(
                      size: OrionButtonSize.small,
                      variant: OrionButtonVariant.bordered,
                      onPressed: () => OrionToast.info('Version 2.0 available'),
                      leading: const Icon(Icons.info_outline, size: 16),
                      child: const Text('Info'),
                    ),
                    OrionButton(
                      size: OrionButtonSize.small,
                      variant: OrionButtonVariant.bordered,
                      onPressed: () => OrionToast.warning('Storage 90% full'),
                      leading: const Icon(
                        Icons.warning_amber_outlined,
                        size: 16,
                      ),
                      child: const Text('Warning'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: OrionSpacing.space20),

              // Promise Card
              OrionShowcaseSection(
                title: 'Promise Lifecycles',
                subtitle:
                    'Track any Future in place: loading spinner resolves to success or error',
                card: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OrionButton(
                      size: OrionButtonSize.small,
                      variant: OrionButtonVariant.solid,
                      onPressed: _firePromise,
                      child: const Text('Simulate 1.4s Async Task'),
                    ),
                    const SizedBox(height: OrionSpacing.space8),
                    Text(
                      'Replaces the spinner with success checkmark in place without unmounting or resetting position.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurfaceVariant,
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
                    'Three-layer style contract: Presets -> OrionToastTheme -> Instance OrionToastStyle',
                card: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OrionShowcaseChoice<_ToastSkin>(
                      label: 'Skin',
                      values: _ToastSkin.values,
                      selected: _skin,
                      labelOf: _skinLabel,
                      onChanged: (val) => setState(() => _skin = val),
                    ),
                    const SizedBox(height: OrionSpacing.space16),
                    OrionButton(
                      size: OrionButtonSize.small,
                      variant: OrionButtonVariant.bordered,
                      onPressed: () {
                        OrionToast.show(
                          'Skinned Toast',
                          description:
                              'Styled via ${_skinLabel(_skin)} profile',
                          style: _skinStyle(scheme),
                        );
                      },
                      child: Text('Fire ${_skinLabel(_skin)} Toast'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
