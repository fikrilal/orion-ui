import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Interactive showcase playground for [OrionDialog] and related dialog APIs.
class OrionDialogShowcaseScreen extends StatefulWidget {
  const OrionDialogShowcaseScreen({super.key});

  @override
  State<OrionDialogShowcaseScreen> createState() =>
      _OrionDialogShowcaseScreenState();
}

enum _DialogTypeChoice { confirmation, destructive, info }

enum _DialogSkinChoice { standard, frosted, bordered }

class _OrionDialogShowcaseScreenState extends State<OrionDialogShowcaseScreen> {
  _DialogTypeChoice _dialogType = _DialogTypeChoice.confirmation;
  _DialogSkinChoice _skin = _DialogSkinChoice.standard;
  OrionDialogActionLayout _layout = OrionDialogActionLayout.auto;
  bool _frosted = false;
  bool _barrierDismissible = true;

  String _lastActionResult = 'None';

  OrionDialogStyle? _resolveSkinStyle(ColorScheme scheme) {
    final OrionDialogStyle base = switch (_skin) {
      _DialogSkinChoice.standard => const OrionDialogStyle(),
      _DialogSkinChoice.frosted => OrionDialogStyle.from(frosted: true),
      _DialogSkinChoice.bordered => OrionDialogStyle.from(
        borderWidth: 2.0,
        borderColor: scheme.primary,
      ),
    };
    return base.copyWith(
      frosted: _frosted || _skin == _DialogSkinChoice.frosted,
    );
  }

  String get _snippet {
    final List<String> lines = <String>[
      'showOrionDialog<bool>(',
      '  context: context,',
      '  barrierDismissible: $_barrierDismissible,',
    ];
    if (_frosted || _skin == _DialogSkinChoice.frosted) {
      lines.add('  style: OrionDialogStyle.from(frosted: true),');
    }
    lines.addAll(<String>[
      '  builder: (context) => OrionDialog(',
      '    title: "Confirm Action",',
      '    description: "Are you sure you want to proceed?",',
      '    actionLayout: OrionDialogActionLayout.${_layout.name},',
      '    actions: [',
      '      OrionDialogAction.cancel(onPressed: () => Navigator.pop(context, false)),',
      '      OrionDialogAction.primary(label: "Confirm", onPressed: () => Navigator.pop(context, true)),',
      '    ],',
      '  ),',
      ');',
    ]);
    return lines.join('\n');
  }

  void _launchPlaygroundDialog(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = _resolveSkinStyle(scheme);

    final String title = switch (_dialogType) {
      _DialogTypeChoice.confirmation => 'Publish Changes?',
      _DialogTypeChoice.destructive => 'Delete Workspace?',
      _DialogTypeChoice.info => 'Sync Complete',
    };

    final String message = switch (_dialogType) {
      _DialogTypeChoice.confirmation =>
        'Your updates will be visible to all organization members immediately.',
      _DialogTypeChoice.destructive =>
        'This permanently deletes all repositories, files, and memberships. This cannot be undone.',
      _DialogTypeChoice.info =>
        'All offline files have been reconciled with cloud storage.',
    };

    final Widget icon = switch (_dialogType) {
      _DialogTypeChoice.confirmation => Icon(
        Icons.cloud_upload_outlined,
        size: 36,
        color: scheme.primary,
      ),
      _DialogTypeChoice.destructive => Icon(
        Icons.delete_forever_rounded,
        size: 36,
        color: scheme.error,
      ),
      _DialogTypeChoice.info => Icon(
        Icons.check_circle_outline_rounded,
        size: 36,
        color: scheme.primary,
      ),
    };

    final List<OrionDialogAction> actions = switch (_dialogType) {
      _DialogTypeChoice.confirmation => [
        OrionDialogAction.cancel(
          onPressed: () => Navigator.of(context).maybePop('Cancelled'),
        ),
        OrionDialogAction.primary(
          label: 'Publish Now',
          onPressed: () => Navigator.of(context).maybePop('Published'),
        ),
      ],
      _DialogTypeChoice.destructive => [
        OrionDialogAction.cancel(
          onPressed: () => Navigator.of(context).maybePop('Cancelled'),
        ),
        OrionDialogAction.destructive(
          label: 'Delete Workspace',
          onPressed: () => Navigator.of(context).maybePop('Deleted'),
        ),
      ],
      _DialogTypeChoice.info => [
        OrionDialogAction.primary(
          label: 'Got It',
          onPressed: () => Navigator.of(context).maybePop('Acknowledged'),
        ),
      ],
    };

    showOrionDialog<String>(
      context: context,
      style: style,
      barrierDismissible: _barrierDismissible,
      builder: (dialogContext) => OrionDialog(
        icon: icon,
        title: title,
        description: message,
        style: style,
        actionLayout: _layout,
        actions: actions,
      ),
    ).then((result) {
      if (mounted) {
        setState(() => _lastActionResult = result ?? 'Dismissed (outside tap)');
      }
    });
  }

  void _launchFrostedDialog(BuildContext context) {
    showOrionConfirmDialog(
      context: context,
      title: 'Translucent Glass Confirmation',
      message:
          'This modal surface demonstrates true Gaussian acrylic frosted glass over high-contrast content.',
      confirmLabel: 'Looks Great',
      cancelLabel: 'Close',
      style: OrionDialogStyle.from(frosted: true),
    ).then((result) {
      if (mounted) {
        setState(
          () => _lastActionResult = result ? 'Confirmed Frosted' : 'Cancelled',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return OrionThemedScaffold(
      title: 'Orion Dialog & Alerts',
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
                      'SURFACE • CENTERED MODALS & ALERTS',
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
                    'Physics-driven centered modal surfaces, confirmations, and alerts with micro-scale spring kinematics and isolated frosted acrylic glass.',
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
                  'Configure parameters below and launch the modal to test spring entrance and exit physics',
              card: true,
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2.00,
                        vertical: 2.04,
                      ),
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
                      child: Column(
                        children: [
                          Center(
                            child: OrionButton(
                              variant: OrionButtonVariant.solid,
                              size: OrionButtonSize.medium,
                              onPressed: () => _launchPlaygroundDialog(context),
                              leading: const Icon(
                                Icons.open_in_browser_rounded,
                                size: 18,
                              ),
                              child: const Text('Launch Dialog Modal'),
                            ),
                          ),
                          const SizedBox(height: OrionSpacing.space12),
                          Text(
                            'Spring micro-scale 0.94 → 1.0 with 6 pt upward glide',
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
                    const SizedBox(height: 2.00),

                    // Controls
                    OrionShowcaseChoice<_DialogTypeChoice>(
                      label: 'Dialog type',
                      values: _DialogTypeChoice.values,
                      selected: _dialogType,
                      labelOf: (t) => t.name,
                      onChanged: (t) => setState(() => _dialogType = t),
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    OrionShowcaseChoice<OrionDialogActionLayout>(
                      label: 'Action layout',
                      values: OrionDialogActionLayout.values,
                      selected: _layout,
                      labelOf: (l) => l.name,
                      onChanged: (l) => setState(() => _layout = l),
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    OrionShowcaseChoice<_DialogSkinChoice>(
                      label: 'Skin',
                      values: _DialogSkinChoice.values,
                      selected: _skin,
                      labelOf: (s) => s.name,
                      onChanged: (s) => setState(() {
                        _skin = s;
                        _frosted = s == _DialogSkinChoice.frosted;
                      }),
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    Row(
                      children: [
                        Expanded(
                          child: OrionShowcaseToggle(
                            label: 'Frosted blur',
                            value: _frosted,
                            onChanged: (val) => setState(() {
                              _frosted = val;
                              if (val) {
                                _skin = _DialogSkinChoice.frosted;
                              } else if (_skin == _DialogSkinChoice.frosted) {
                                _skin = _DialogSkinChoice.standard;
                              }
                            }),
                          ),
                        ),
                        const SizedBox(width: OrionSpacing.space16),
                        Expanded(
                          child: OrionShowcaseToggle(
                            label: 'Tap-outside dismiss',
                            value: _barrierDismissible,
                            onChanged: (val) =>
                                setState(() => _barrierDismissible = val),
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: OrionSpacing.space12),
                      child: Text(
                        'Last action outcome: $_lastActionResult',
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

            // Dedicated Frosted Glass Specimen Card
            OrionShowcaseSection(
              title: 'Frosted Glass Surface',
              subtitle:
                  'Static blur isolation filters colorful backgrounds behind the dialog without per-frame GPU re-sampling',
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
                      'Frosted glass dialog over colorful gradient',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap below to open a translucent acrylic dialog and observe the real-time background blur.',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: OrionButton(
                        variant: OrionButtonVariant.solid,
                        size: OrionButtonSize.medium,
                        onPressed: () => _launchFrostedDialog(context),
                        leading: const Icon(Icons.blur_on_rounded, size: 18),
                        child: const Text('Open Frosted Dialog'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 2.04),

            // Turnkey Helpers Section
            OrionShowcaseSection(
              title: 'Turnkey Helper Functions',
              subtitle:
                  'One-liner helpers for common confirmation and alert workflows',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'High-level functions resolve typed results without boilerplate:',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  Wrap(
                    spacing: OrionSpacing.space12,
                    runSpacing: OrionSpacing.space12,
                    children: [
                      OrionButton(
                        variant: OrionButtonVariant.bordered,
                        onPressed: () {
                          showOrionConfirmDialog(
                            context: context,
                            title: 'Discard Draft?',
                            message:
                                'Any unsaved changes will be permanently discarded.',
                            confirmLabel: 'Discard',
                            cancelLabel: 'Keep Editing',
                          ).then((ok) {
                            if (mounted) {
                              setState(
                                () => _lastActionResult = ok
                                    ? 'Confirmed Discard'
                                    : 'Kept Draft',
                              );
                            }
                          });
                        },
                        leading: const Icon(
                          Icons.help_outline_rounded,
                          size: 18,
                        ),
                        child: const Text('Confirm Helper'),
                      ),
                      OrionButton(
                        variant: OrionButtonVariant.solid,
                        style: OrionButtonStyle.from(
                          backgroundColor: scheme.error,
                          foregroundColor: scheme.onError,
                        ),
                        onPressed: () {
                          showOrionConfirmDialog(
                            context: context,
                            title: 'Delete Repository?',
                            message:
                                'This repository will be purged immediately from the cluster.',
                            confirmLabel: 'Delete Repo',
                            cancelLabel: 'Cancel',
                            isDestructive: true,
                            icon: Icon(
                              Icons.warning_amber_rounded,
                              size: 32,
                              color: scheme.error,
                            ),
                          ).then((ok) {
                            if (mounted) {
                              setState(
                                () => _lastActionResult = ok
                                    ? 'Confirmed Delete'
                                    : 'Cancelled Delete',
                              );
                            }
                          });
                        },
                        leading: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        child: const Text('Destructive Helper'),
                      ),
                      OrionButton(
                        variant: OrionButtonVariant.flat,
                        onPressed: () {
                          showOrionAlertDialog(
                            context: context,
                            title: 'Notice',
                            message:
                                'Maintenance scheduled tonight between 2:00 AM and 4:00 AM UTC.',
                            actionLabel: 'Understood',
                          ).then((_) {
                            if (mounted) {
                              setState(
                                () => _lastActionResult = 'Alert Dismissed',
                              );
                            }
                          });
                        },
                        leading: const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                        ),
                        child: const Text('Alert Helper'),
                      ),
                    ],
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
