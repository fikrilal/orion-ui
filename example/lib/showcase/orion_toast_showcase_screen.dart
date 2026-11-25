import 'package:flutter/material.dart';
import 'package:orion_ui/orion_ui.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';

/// Playground and verification showcase for [OrionToast] and [OrionToaster].
class OrionToastShowcaseScreen extends StatefulWidget {
  const OrionToastShowcaseScreen({super.key});

  @override
  State<OrionToastShowcaseScreen> createState() =>
      _OrionToastShowcaseScreenState();
}

enum _ToastSkin { standard, richColors, frosted }

class _OrionToastShowcaseScreenState extends State<OrionToastShowcaseScreen> {
  final OrionToastController _controller = OrionToastController();
  final TextEditingController _keyboardField = TextEditingController();

  OrionToastStatus _status = OrionToastStatus.success;
  OrionToastPosition _position = OrionToastPosition.bottomCenter;
  _ToastSkin _skin = _ToastSkin.standard;
  bool _hasAction = true;
  bool _showCloseButton = true;
  bool _showProgressBar = true;
  bool _dismissible = true;
  int _counter = 0;
  String _lastEvent = 'Tap Fire Toast or Burst ×3 to test gestures.';

  @override
  void dispose() {
    _controller.dispose();
    _keyboardField.dispose();
    super.dispose();
  }

  String _statusLabel(OrionToastStatus status) => switch (status) {
    OrionToastStatus.neutral => 'Neutral',
    OrionToastStatus.info => 'Info',
    OrionToastStatus.success => 'Success',
    OrionToastStatus.warning => 'Warning',
    OrionToastStatus.error => 'Error',
    OrionToastStatus.loading => 'Loading',
  };

  String _positionLabel(OrionToastPosition pos) => switch (pos) {
    OrionToastPosition.topLeft => 'Top Left',
    OrionToastPosition.topCenter => 'Top Center',
    OrionToastPosition.topRight => 'Top Right',
    OrionToastPosition.bottomLeft => 'Bottom Left',
    OrionToastPosition.bottomCenter => 'Bottom Center',
    OrionToastPosition.bottomRight => 'Bottom Right',
  };

  String _skinLabel(_ToastSkin skin) => switch (skin) {
    _ToastSkin.standard => 'Standard',
    _ToastSkin.richColors => 'Rich Colors',
    _ToastSkin.frosted => 'Frosted',
  };

  OrionToastStyle? _skinStyle() => switch (_skin) {
    _ToastSkin.standard => null,
    _ToastSkin.richColors => OrionToastStyle.from(richColors: true),
    _ToastSkin.frosted => OrionToastStyle.from(frosted: true),
  };

  void _log(String event) {
    if (!mounted) return;
    setState(() => _lastEvent = event);
  }

  void _fireToast() {
    final int n = ++_counter;
    final (String title, String desc) = switch (_status) {
      OrionToastStatus.neutral => (
        'Draft saved (#$n)',
        'Your latest edits are stored locally.',
      ),
      OrionToastStatus.info => (
        'Update ready (#$n)',
        'Orion UI v2.1 is available to install.',
      ),
      OrionToastStatus.success => (
        'Changes published (#$n)',
        'All 14 targets deployed cleanly.',
      ),
      OrionToastStatus.warning => (
        'Storage nearly full (#$n)',
        'You have used 90% of your workspace quota.',
      ),
      OrionToastStatus.error => (
        'Sync failed (#$n)',
        'Check your network connection and retry.',
      ),
      OrionToastStatus.loading => (
        'Uploading build (#$n)...',
        'Compiling release artifacts.',
      ),
    };

    OrionToast.show(
      title,
      description: desc,
      status: _status,
      duration: _status == OrionToastStatus.loading
          ? Duration.zero
          : const Duration(milliseconds: 4500),
      dismissible: _dismissible,
      showCloseButton: _showCloseButton,
      showProgressBar: _showProgressBar,
      action: _hasAction
          ? OrionToastAction(
              label: _status == OrionToastStatus.error ? 'Retry' : 'Undo',
              onPressed: () => _log('Action pressed on #$n'),
            )
          : null,
      onTap: () => _log('Body tapped on #$n'),
      onDismissed: (OrionToastDismissReason reason) =>
          _log('Toast #$n dismissed (${reason.name})'),
      style: _skinStyle(),
      controller: _controller,
    );
  }

  void _fireBurst() {
    OrionToast.info(
      'New comment on PR #412',
      description: 'Ada left review feedback.',
      duration: const Duration(seconds: 7),
      onDismissed: (OrionToastDismissReason r) => _log('PR toast (${r.name})'),
      style: _skinStyle(),
      controller: _controller,
    );
    OrionToast.warning(
      'Rate limit approaching',
      description: '85% of hourly API quota consumed.',
      duration: const Duration(seconds: 7),
      onDismissed: (OrionToastDismissReason r) =>
          _log('Quota toast (${r.name})'),
      style: _skinStyle(),
      controller: _controller,
    );
    OrionToast.success(
      'Release v1.5.0 live',
      description: 'Tap stack to pin open, tap outside to collapse.',
      duration: const Duration(seconds: 7),
      action: OrionToastAction(
        label: 'View',
        onPressed: () => _log('Viewed release v1.5.0'),
      ),
      onDismissed: (OrionToastDismissReason r) =>
          _log('Release toast (${r.name})'),
      style: _skinStyle(),
      controller: _controller,
    );
  }

  Future<void> _firePromise({required bool shouldFail}) async {
    try {
      await OrionToast.promise<String>(
        Future<String>.delayed(const Duration(milliseconds: 1400), () {
          if (shouldFail) {
            throw Exception('Gateway timeout');
          }
          return 'v1.5.0';
        }),
        loading: 'Deploying release...',
        loadingDescription: 'Building and verifying bundle checksums',
        success: (String version) => 'Deployed $version',
        successDescription: (String _) => 'Zero errors across 3 regions.',
        error: (Object _) => 'Deployment failed',
        errorDescription: (Object _) => 'Gateway timed out after 1.4s.',
        successAction: OrionToastAction(
          label: 'View',
          onPressed: () => _log('Opened deployment log'),
        ),
        errorAction: OrionToastAction(
          label: 'Retry',
          onPressed: () => _firePromise(shouldFail: false),
        ),
        showCloseButton: _showCloseButton,
        showProgressBar: _showProgressBar,
        style: _skinStyle(),
        controller: _controller,
      );
    } catch (_) {
      // Handled cleanly by OrionToast.promise error state.
    }
  }

  String get _snippet {
    final List<String> lines = <String>[
      'OrionToaster(',
      if (_position != OrionToastPosition.bottomCenter)
        '  position: OrionToastPosition.${_position.name},',
      if (!_showCloseButton) '  showCloseButtons: false,',
      if (_showProgressBar) '  showProgressBar: true,',
      if (_skin == _ToastSkin.richColors) '  richColors: true,',
      '  child: app,',
      ');',
      '',
      'OrionToast.show(',
      "  'Changes published',",
      "  description: 'All 14 targets deployed cleanly.',",
      '  status: OrionToastStatus.${_status.name},',
      if (_hasAction) ...<String>[
        '  action: OrionToastAction(',
        "    label: 'Undo',",
        '    onPressed: () {},',
        '  ),',
      ],
      if (!_dismissible) '  dismissible: false,',
      '  onDismissed: (reason) {},',
      ');',
    ];
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return OrionThemedScaffold(
      title: 'Orion Toast',
      builder: (BuildContext context) {
        return OrionToaster(
          controller: _controller,
          position: _position,
          showCloseButtons: _showCloseButton,
          showProgressBar: _showProgressBar,
          richColors: _skin == _ToastSkin.richColors,
          child: Column(
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
                        'NOTIFICATION • PERSPECTIVE STACK',
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
                      'Uniform-width stacked toasts with dual-axis swipe '
                      '(horizontal or toward edge), tap-to-pin expansion on '
                      'mobile, calm anchor-edge exits, keyboard lift, and '
                      'morphing promise lifecycles.',
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.4,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Hero Playground
              OrionShowcaseSection(
                title: 'Interactive Playground',
                subtitle:
                    'Configure status, anchor, skin, close button, and countdown bar',
                card: true,
                child: OrionShowcasePanel(
                  key: const ValueKey<String>('showcase-panel-playground'),
                  code: _snippet,
                  preview: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(OrionSpacing.space16),
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
                            Wrap(
                              spacing: OrionSpacing.space8,
                              runSpacing: OrionSpacing.space8,
                              alignment: WrapAlignment.center,
                              children: <Widget>[
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
                                  onPressed: _fireBurst,
                                  leading: const Icon(
                                    Icons.layers_rounded,
                                    size: 16,
                                  ),
                                  child: const Text('Burst ×3'),
                                ),
                                OrionButton(
                                  size: OrionButtonSize.small,
                                  variant: OrionButtonVariant.flat,
                                  onPressed: () => _controller.dismiss(),
                                  child: const Text('Dismiss Top'),
                                ),
                                OrionButton(
                                  size: OrionButtonSize.small,
                                  variant: OrionButtonVariant.flat,
                                  onPressed: _controller.clear,
                                  child: const Text('Clear All'),
                                ),
                              ],
                            ),
                            const SizedBox(height: OrionSpacing.space12),
                            Text(
                              _position.isTop
                                  ? 'Anchored top: swipe sideways or UP to dismiss; tap stack to pin open.'
                                  : 'Anchored bottom: swipe sideways or DOWN to dismiss; tap stack to pin open.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: OrionSpacing.space4),
                            Text(
                              _lastEvent,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: OrionSpacing.space16),
                      OrionShowcaseControls(
                        children: <Widget>[
                          OrionShowcaseChoice<OrionToastStatus>(
                            label: 'Status',
                            values: OrionToastStatus.values,
                            selected: _status,
                            labelOf: _statusLabel,
                            onChanged: (OrionToastStatus val) =>
                                setState(() => _status = val),
                          ),
                          OrionShowcaseChoice<OrionToastPosition>(
                            label: 'Position',
                            values: const <OrionToastPosition>[
                              OrionToastPosition.topCenter,
                              OrionToastPosition.bottomCenter,
                              OrionToastPosition.topRight,
                              OrionToastPosition.bottomRight,
                            ],
                            selected: _position,
                            labelOf: _positionLabel,
                            onChanged: (OrionToastPosition val) =>
                                setState(() => _position = val),
                          ),
                          OrionShowcaseChoice<_ToastSkin>(
                            label: 'Skin',
                            values: _ToastSkin.values,
                            selected: _skin,
                            labelOf: _skinLabel,
                            onChanged: (_ToastSkin val) =>
                                setState(() => _skin = val),
                          ),
                          Wrap(
                            spacing: OrionSpacing.space20,
                            runSpacing: OrionSpacing.space12,
                            children: <Widget>[
                              OrionShowcaseToggle(
                                label: 'Action',
                                value: _hasAction,
                                onChanged: (bool v) =>
                                    setState(() => _hasAction = v),
                              ),
                              OrionShowcaseToggle(
                                label: 'Close ×',
                                value: _showCloseButton,
                                onChanged: (bool v) =>
                                    setState(() => _showCloseButton = v),
                              ),
                              OrionShowcaseToggle(
                                label: 'Progress',
                                value: _showProgressBar,
                                onChanged: (bool v) =>
                                    setState(() => _showProgressBar = v),
                              ),
                              OrionShowcaseToggle(
                                label: 'Swipeable',
                                value: _dismissible,
                                onChanged: (bool v) =>
                                    setState(() => _dismissible = v),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: OrionSpacing.space20),

              // Promise Lifecycles Card
              OrionShowcaseSection(
                title: 'Promise Lifecycles',
                subtitle:
                    'Smooth AnimatedSwitcher morphing with separate successAction and errorAction',
                card: true,
                child: Wrap(
                  spacing: OrionSpacing.space8,
                  runSpacing: OrionSpacing.space8,
                  children: <Widget>[
                    OrionButton(
                      size: OrionButtonSize.small,
                      onPressed: () => _firePromise(shouldFail: false),
                      leading: const Icon(Icons.check_rounded, size: 16),
                      child: const Text('Promise → Success'),
                    ),
                    OrionButton(
                      size: OrionButtonSize.small,
                      variant: OrionButtonVariant.bordered,
                      onPressed: () => _firePromise(shouldFail: true),
                      leading: const Icon(Icons.error_outline, size: 16),
                      child: const Text('Promise → Error'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: OrionSpacing.space20),

              // Keyboard Lift Card
              OrionShowcaseSection(
                title: 'Keyboard-Aware Lift',
                subtitle:
                    'Focus the field to open the soft keyboard, then fire a bottom toast to see it stay above the IME',
                card: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    OrionTextField(
                      controller: _keyboardField,
                      size: OrionTextFieldSize.small,
                      hint: 'Tap here to open keyboard...',
                      onSubmitted: (String value) {
                        OrionToast.success(
                          value.trim().isEmpty
                              ? 'Submitted cleanly'
                              : 'Sent: ${value.trim()}',
                          controller: _controller,
                        );
                      },
                    ),
                    const SizedBox(height: OrionSpacing.space12),
                    OrionButton(
                      size: OrionButtonSize.small,
                      variant: OrionButtonVariant.bordered,
                      onPressed: () {
                        OrionToast.info(
                          'Floating above keyboard',
                          description:
                              'OrionToaster tracks live viewInsets automatically.',
                          controller: _controller,
                        );
                      },
                      child: const Text('Fire Above Keyboard'),
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
