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

enum _DialogTypeChoice { confirmation, destructive, info, input }

enum _DialogSkinChoice { standard, frosted, bordered, borderless }

class _OrionDialogShowcaseScreenState extends State<OrionDialogShowcaseScreen> {
  _DialogTypeChoice _dialogType = _DialogTypeChoice.confirmation;
  _DialogSkinChoice _skin = _DialogSkinChoice.standard;
  OrionDialogActionLayout _layout = OrionDialogActionLayout.auto;
  bool _frosted = false;
  bool _barrierDismissible = true;
  bool _centerContent = true;
  bool _showCloseButton = false;

  String _lastActionResult = 'None';

  OrionDialogStyle? _resolveSkinStyle(ColorScheme scheme) {
    final OrionDialogStyle base = switch (_skin) {
      _DialogSkinChoice.standard => const OrionDialogStyle(),
      _DialogSkinChoice.frosted => OrionDialogStyle.from(frosted: true),
      _DialogSkinChoice.bordered => OrionDialogStyle.from(
        borderWidth: 2.0,
        borderColor: scheme.primary,
      ),
      _DialogSkinChoice.borderless => OrionDialogStyle.from(borderWidth: 0.0),
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
    } else if (_skin == _DialogSkinChoice.borderless) {
      lines.add('  style: OrionDialogStyle.from(borderWidth: 0),');
    }
    lines.addAll(<String>[
      '  builder: (dialogContext) => OrionDialog(',
      "    title: 'Confirm Action',",
      "    description: 'Are you sure you want to proceed?',",
      if (!_centerContent) '    centerContent: false,',
      if (_showCloseButton) '    showCloseButton: true,',
      '    actionLayout: OrionDialogActionLayout.${_layout.name},',
      '    actions: [',
      '      OrionDialogAction.cancel(),',
      '      OrionDialogAction.primary(',
      "        label: 'Confirm',",
      '        onPressed: () => OrionDialog.dismissOf(dialogContext, true),',
      '      ),',
      '    ],',
      '  ),',
      ');',
    ]);
    return lines.join('\n');
  }

  void _launchPlaygroundDialog(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final OrionDialogStyle? style = _resolveSkinStyle(scheme);

    if (_dialogType == _DialogTypeChoice.input) {
      _launchInputDialog(context, style: style);
      return;
    }

    final String title = switch (_dialogType) {
      _DialogTypeChoice.confirmation => 'Publish Changes?',
      _DialogTypeChoice.destructive => 'Delete Workspace?',
      _DialogTypeChoice.info => 'Sync Complete',
      _DialogTypeChoice.input => '',
    };

    final String message = switch (_dialogType) {
      _DialogTypeChoice.confirmation =>
        'Your updates will be visible to all organization members immediately.',
      _DialogTypeChoice.destructive =>
        'This permanently deletes all repositories, files, and memberships. This cannot be undone.',
      _DialogTypeChoice.info =>
        'All offline files have been reconciled with cloud storage.',
      _DialogTypeChoice.input => '',
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
      _DialogTypeChoice.input => const SizedBox.shrink(),
    };

    // Pass `style` ONLY to `showOrionDialog` to demonstrate automatic
    // style propagation to the descendant `OrionDialog`.
    showOrionDialog<String>(
      context: context,
      style: style,
      barrierDismissible: _barrierDismissible,
      builder: (BuildContext dialogContext) {
        final List<OrionDialogAction> actions = switch (_dialogType) {
          _DialogTypeChoice.confirmation => <OrionDialogAction>[
            OrionDialogAction.cancel(
              onPressed: () =>
                  OrionDialog.dismissOf<String>(dialogContext, 'Cancelled'),
            ),
            OrionDialogAction.primary(
              label: 'Publish Now',
              onPressed: () =>
                  OrionDialog.dismissOf<String>(dialogContext, 'Published'),
            ),
          ],
          _DialogTypeChoice.destructive => <OrionDialogAction>[
            OrionDialogAction.cancel(
              onPressed: () =>
                  OrionDialog.dismissOf<String>(dialogContext, 'Cancelled'),
            ),
            OrionDialogAction.destructive(
              label: 'Delete Workspace',
              onPressed: () =>
                  OrionDialog.dismissOf<String>(dialogContext, 'Deleted'),
            ),
          ],
          _DialogTypeChoice.info => <OrionDialogAction>[
            OrionDialogAction.primary(
              label: 'Got It',
              onPressed: () =>
                  OrionDialog.dismissOf<String>(dialogContext, 'Acknowledged'),
            ),
          ],
          _DialogTypeChoice.input => const <OrionDialogAction>[],
        };

        return OrionDialog(
          icon: icon,
          title: title,
          description: message,
          centerContent: _centerContent,
          showCloseButton: _showCloseButton,
          actionLayout: _layout,
          actions: actions,
        );
      },
    ).then((String? result) {
      if (mounted) {
        setState(
          () => _lastActionResult = result ?? 'Dismissed (outside / close)',
        );
      }
    });
  }

  void _launchInputDialog(BuildContext context, {OrionDialogStyle? style}) {
    final TextEditingController controller = TextEditingController(
      text: 'orion-ui',
    );
    showOrionDialog<String>(
      context: context,
      style: style,
      barrierDismissible: _barrierDismissible,
      builder: (BuildContext dialogContext) {
        return OrionDialog(
          title: 'Rename Project',
          description:
              'Enter a new repository name. The dialog lifts cleanly above the keyboard.',
          centerContent: false,
          showCloseButton: true,
          actionLayout: _layout,
          content: OrionTextField(
            controller: controller,
            label: 'Project name',
            hint: 'my-project',
            autofocus: true,
          ),
          actions: <OrionDialogAction>[
            OrionDialogAction.cancel(),
            OrionDialogAction.primary(
              label: 'Save Name',
              onPressed: () => OrionDialog.dismissOf<String>(
                dialogContext,
                'Renamed to "${controller.text.trim()}"',
              ),
            ),
          ],
        );
      },
    ).then((String? result) {
      controller.dispose();
      if (mounted) {
        setState(() => _lastActionResult = result ?? 'Cancelled rename');
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
      showCloseButton: true,
      style: OrionDialogStyle.from(frosted: true),
    ).then((bool result) {
      if (mounted) {
        setState(
          () => _lastActionResult = result ? 'Confirmed Frosted' : 'Cancelled',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return OrionThemedScaffold(
      title: 'Orion Dialog & Alerts',
      builder: (BuildContext context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Top Category Header
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
                    'Physics-driven centered modal surfaces with crisp spring kinematics, keyboard lift, safe scrolling, automatic vertical CTA ordering, and frosted acrylic glass.',
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
                  'Configure parameters below and launch the modal to test spring entrance, exit, and keyboard lift',
              card: true,
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: OrionSpacing.space20,
                        vertical: OrionSpacing.space24,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(OrionRadii.radius12),
                        border: Border.all(
                          color: isDark
                              ? scheme.outlineVariant.withValues(alpha: 0.15)
                              : scheme.outlineVariant.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          Center(
                            child: OrionButton(
                              variant: OrionButtonVariant.solid,
                              size: OrionButtonSize.medium,
                              onPressed: () => _launchPlaygroundDialog(context),
                              leading: const Icon(
                                Icons.open_in_browser_rounded,
                                size: 18,
                              ),
                              label: 'Launch Dialog Modal',
                            ),
                          ),
                          const SizedBox(height: OrionSpacing.space12),
                          Text(
                            'Spring micro-scale 0.94 -> 1.0 with 6 pt upward glide',
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

                    // Controls
                    OrionShowcaseChoice<_DialogTypeChoice>(
                      label: 'Dialog type',
                      values: _DialogTypeChoice.values,
                      selected: _dialogType,
                      labelOf: (_DialogTypeChoice t) => t.name,
                      onChanged: (_DialogTypeChoice t) =>
                          setState(() => _dialogType = t),
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    OrionShowcaseChoice<OrionDialogActionLayout>(
                      label: 'Action layout',
                      values: OrionDialogActionLayout.values,
                      selected: _layout,
                      labelOf: (OrionDialogActionLayout l) => l.name,
                      onChanged: (OrionDialogActionLayout l) =>
                          setState(() => _layout = l),
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    OrionShowcaseChoice<_DialogSkinChoice>(
                      label: 'Skin',
                      values: _DialogSkinChoice.values,
                      selected: _skin,
                      labelOf: (_DialogSkinChoice s) => s.name,
                      onChanged: (_DialogSkinChoice s) => setState(() {
                        _skin = s;
                        _frosted = s == _DialogSkinChoice.frosted;
                      }),
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OrionShowcaseToggle(
                            label: 'Center content',
                            value: _centerContent,
                            onChanged: (bool val) =>
                                setState(() => _centerContent = val),
                          ),
                        ),
                        const SizedBox(width: OrionSpacing.space16),
                        Expanded(
                          child: OrionShowcaseToggle(
                            label: 'Close button',
                            value: _showCloseButton,
                            onChanged: (bool val) =>
                                setState(() => _showCloseButton = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: OrionSpacing.space12),

                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OrionShowcaseToggle(
                            label: 'Frosted blur',
                            value: _frosted,
                            onChanged: (bool val) => setState(() {
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
                            onChanged: (bool val) =>
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
            const SizedBox(height: OrionSpacing.space24),

            // Dedicated Frosted Glass Specimen Card
            OrionShowcaseSection(
              title: 'Frosted Glass Surface',
              subtitle:
                  'Static blur isolation filters colorful backgrounds behind the dialog without per-frame GPU re-sampling',
              card: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(OrionSpacing.space20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(OrionRadii.radius12),
                  gradient: LinearGradient(
                    colors: <Color>[
                      scheme.primaryContainer,
                      scheme.tertiaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
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
                        label: 'Open Frosted Dialog',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: OrionSpacing.space24),

            // Turnkey Helpers Section
            OrionShowcaseSection(
              title: 'Turnkey Helper Functions',
              subtitle:
                  'One-liner helpers for confirmation, destructive, alert, and guarded flows',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'High-level functions resolve typed results with spring dismissal:',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  Wrap(
                    spacing: OrionSpacing.space12,
                    runSpacing: OrionSpacing.space12,
                    children: <Widget>[
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
                          ).then((bool ok) {
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
                        label: 'Confirm Helper',
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
                          ).then((bool ok) {
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
                        label: 'Destructive Helper',
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
                        label: 'Alert Helper',
                      ),
                      OrionButton(
                        variant: OrionButtonVariant.bordered,
                        onPressed: () {
                          showOrionAlertDialog(
                            context: context,
                            title: 'Required Update',
                            message:
                                'Outside taps and system Back are blocked until you explicitly acknowledge.',
                            actionLabel: 'Acknowledge',
                            barrierDismissible: false,
                          ).then((_) {
                            if (mounted) {
                              setState(
                                () => _lastActionResult = 'Guarded Acknowledged',
                              );
                            }
                          });
                        },
                        leading: const Icon(Icons.lock_outline_rounded, size: 18),
                        label: 'Guarded Alert',
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
