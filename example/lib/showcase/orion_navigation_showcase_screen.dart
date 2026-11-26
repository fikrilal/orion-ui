import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground for [OrionNavigationBar].
///
/// The Visible and Disabled flags in the top controls card drive every sample;
/// the sections below hold the destination matrix, the page-change sample,
/// 5-tab dense stress layouts, customization skins (including frosted and
/// docked), and the playground with live code generation.
class OrionNavigationShowcaseScreen extends StatefulWidget {
  const OrionNavigationShowcaseScreen({super.key});

  @override
  State<OrionNavigationShowcaseScreen> createState() =>
      _OrionNavigationShowcaseScreenState();
}

/// The instance-level skins the customization section demonstrates.
enum _BarSkin { standard, frosted, filled, docked, dense, icons, expanding }

class _OrionNavigationShowcaseScreenState
    extends State<OrionNavigationShowcaseScreen>
    with TickerProviderStateMixin {
  static const List<OrionNavigationDestination> _destinations =
      <OrionNavigationDestination>[
        OrionNavigationDestination(
          icon: Icon(Icons.chat_bubble_outline),
          selectedIcon: Icon(Icons.chat_bubble),
          label: 'Chats',
          badgeCount: 12,
          semanticLabel: 'Chats, 12 unread',
        ),
        OrionNavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Contacts',
          badgeDot: true,
        ),
        OrionNavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ];

  static const List<OrionNavigationDestination> _fiveDestinations =
      <OrionNavigationDestination>[
        OrionNavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        OrionNavigationDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search),
          label: 'Search',
        ),
        OrionNavigationDestination(
          icon: Icon(Icons.inbox_outlined),
          selectedIcon: Icon(Icons.inbox),
          label: 'Inbox',
          badgeCount: 128,
        ),
        OrionNavigationDestination(
          icon: Icon(Icons.lock_outline),
          selectedIcon: Icon(Icons.lock),
          label: 'Pro',
          enabled: false,
        ),
        OrionNavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
          badgeDot: true,
        ),
      ];

  final PageController _pages = PageController();
  late final AnimationController _jump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  // Flags: shared by every sample on the page.
  bool _visible = true;
  bool _disabled = false;

  // Customization: the focused skin choice.
  _BarSkin _skin = _BarSkin.standard;

  // 5-tab sample selection.
  int _fiveIndex = 0;

  // Live sample: the bar follows the pager's selection and drag.
  int _index = 0;
  int? _jumpFrom;
  int _jumpTo = 0;
  double? _drag;
  bool _userDrag = false;

  @override
  void dispose() {
    _jump.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _onScroll(ScrollNotification notification) {
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _userDrag = true;
    }
    if (notification is ScrollEndNotification) {
      setState(() {
        _drag = null;
        _userDrag = false;
      });
      return;
    }
    if (!_userDrag || notification is! ScrollUpdateNotification) {
      return;
    }
    final double? page = _pages.page;
    if (page == null) {
      return;
    }
    setState(() => _drag = page);
  }

  void _goTo(int index) {
    final int from = _index;
    setState(() {
      _index = index;
      _drag = null;
      _userDrag = false;
    });
    if ((index - from).abs() > 1) {
      setState(() {
        _jumpFrom = from;
        _jumpTo = index;
      });
      _jump.forward(from: 0).whenComplete(() {
        if (!mounted) {
          return;
        }
        _pages.jumpToPage(index);
        setState(() => _jumpFrom = null);
      });
      return;
    }
    _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  OrionNavigationBarVariant get _skinVariant => _skin == _BarSkin.docked
      ? OrionNavigationBarVariant.docked
      : OrionNavigationBarVariant.floating;

  OrionNavigationBarStyle? _skinStyle(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return switch (_skin) {
      _BarSkin.standard => null,
      _BarSkin.frosted => OrionNavigationBarStyle.from(frosted: true),
      _BarSkin.filled => OrionNavigationBarStyle(
        selectionColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => states.contains(WidgetState.disabled)
              ? scheme.onSurface.withValues(alpha: 0.04)
              : scheme.primary,
        ),
        destinationColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withValues(alpha: 0.38);
          }
          return states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.onSurfaceVariant;
        }),
        badge: OrionNavigationBadgeStyle(
          fill: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) => states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.primary,
          ),
          ink: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) => states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onPrimary,
          ),
        ),
      ),
      _BarSkin.docked => null,
      _BarSkin.dense => OrionNavigationBarStyle.from(
        maxWidth: 280,
        minHeight: 52,
        iconSize: 18,
      ),
      _BarSkin.icons => OrionNavigationBarStyle.from(
        labelMode: OrionNavigationLabelMode.none,
      ),
      _BarSkin.expanding => OrionNavigationBarStyle.from(
        labelMode: OrionNavigationLabelMode.selected,
      ),
    };
  }

  String _skinLabel(_BarSkin skin) => switch (skin) {
    _BarSkin.standard => 'Standard',
    _BarSkin.frosted => 'Frosted',
    _BarSkin.filled => 'Filled',
    _BarSkin.docked => 'Docked',
    _BarSkin.dense => 'Dense',
    _BarSkin.icons => 'Icons',
    _BarSkin.expanding => 'Expanding',
  };

  /// One bar under the shared flags.
  OrionNavigationBar _sampleBar({
    OrionNavigationBarStyle? style,
    OrionNavigationBarVariant variant = OrionNavigationBarVariant.floating,
    bool? useSafeArea,
  }) {
    return OrionNavigationBar(
      destinations: _destinations,
      selectedIndex: _index,
      dragPosition: _drag,
      visible: _visible,
      variant: variant,
      useSafeArea: useSafeArea,
      style: style,
      onChanged: _disabled ? null : _goTo,
    );
  }

  /// The exact call the current controls produce.
  String get _snippet {
    final List<String> lines = <String>[
      'OrionNavigationBar(',
      '  destinations: _destinations,',
      '  selectedIndex: $_index, // ${_destinations[_index].label}',
    ];
    if (_skin == _BarSkin.docked) {
      lines.add('  variant: OrionNavigationBarVariant.docked,');
    } else if (_skin == _BarSkin.frosted) {
      lines.add('  style: OrionNavigationBarStyle.from(frosted: true),');
    } else if (_skin == _BarSkin.icons) {
      lines.add(
        '  style: OrionNavigationBarStyle.from(labelMode: OrionNavigationLabelMode.none),',
      );
    } else if (_skin == _BarSkin.expanding) {
      lines.add(
        '  style: OrionNavigationBarStyle.from(labelMode: OrionNavigationLabelMode.selected),',
      );
    } else if (_skin == _BarSkin.dense) {
      lines.add(
        '  style: OrionNavigationBarStyle.from(maxWidth: 280, minHeight: 52, iconSize: 18),',
      );
    }
    if (!_visible) {
      lines.add('  visible: false,');
    }
    if (_disabled) {
      lines.add('  onChanged: null, // disabled');
    } else {
      lines.add('  onChanged: (index) => setState(() => _selected = index),');
    }
    lines.add(');');
    return lines.join('\n');
  }

  Widget _page(BuildContext context, int index) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return ColoredBox(
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          OrionSpacing.space24,
          OrionSpacing.space24,
          OrionSpacing.space24,
          96,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            IconTheme.merge(
              data: IconThemeData(
                size: OrionSizing.iconLarge,
                color: scheme.onSurfaceVariant,
              ),
              child:
                  _destinations[index].selectedIcon ??
                  _destinations[index].icon,
            ),
            const SizedBox(height: OrionSpacing.space12),
            Text(
              _destinations[index].label,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: OrionSpacing.space16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  for (var row = 0; row < 3; row++)
                    Container(
                      margin: const EdgeInsets.only(top: OrionSpacing.space8),
                      height: 44,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(
                          OrionRadii.radius12,
                        ),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrionThemedScaffold(
      title: 'Orion Navigation',
      builder: (context) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;
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
                      'SURFACE CAPSULE • DOCKED • TRAVEL SPRING',
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
                    'Floating or docked navigation bar with sliding pill, selectedIcon cross-fade, count/dot badges, frosted glass, and pager drag tracking.',
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
                        label: 'Visible',
                        value: _visible,
                        onChanged: (value) => setState(() => _visible = value),
                      ),
                    ),
                    Expanded(
                      child: OrionShowcaseToggle(
                        label: 'Disabled',
                        value: _disabled,
                        onChanged: (value) => setState(() => _disabled = value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: OrionSpacing.space24),

            // Destinations Card
            OrionShowcaseSection(
              title: 'Destinations',
              subtitle:
                  'Floating capsule with selectedIcon cross-fade, tabular badgeCount, and compact badgeDot',
              card: true,
              child: _sampleBar(),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // 5-Tab Expanding + Disabled Item Card
            OrionShowcaseSection(
              title: '5 Destinations & Disabled Tab',
              subtitle:
                  'Adaptive expanding layout with 99+ cap, status dot, and per-destination enabled: false',
              card: true,
              child: OrionNavigationBar(
                destinations: _fiveDestinations,
                selectedIndex: _fiveIndex,
                visible: _visible,
                style: OrionNavigationBarStyle.from(
                  labelMode: OrionNavigationLabelMode.selected,
                ),
                onChanged: _disabled
                    ? null
                    : (int index) => setState(() => _fiveIndex = index),
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Page change Card
            OrionShowcaseSection(
              title: 'Page change & Frosted glass',
              subtitle:
                  'Live PageView tracking fractional dragPosition with translucent BackdropFilter capsule',
              card: true,
              child: SizedBox(
                height: 380,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double width = constraints.maxWidth;
                    return Stack(
                      children: <Widget>[
                        NotificationListener<ScrollNotification>(
                          onNotification: (ScrollNotification notification) {
                            _onScroll(notification);
                            return false;
                          },
                          child: PageView(
                            controller: _pages,
                            onPageChanged: (int index) =>
                                setState(() => _index = index),
                            children: <Widget>[
                              for (var i = 0; i < _destinations.length; i++)
                                _page(context, i),
                            ],
                          ),
                        ),
                        if (_jumpFrom != null)
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _jump,
                              builder: (BuildContext context, Widget? child) {
                                final double t = Curves.easeInOutCubic
                                    .transform(_jump.value);
                                final double direction = _jumpTo > _jumpFrom!
                                    ? 1
                                    : -1;
                                return ClipRect(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: <Widget>[
                                      Transform.translate(
                                        offset: Offset(
                                          -width * t * direction,
                                          0,
                                        ),
                                        child: _page(context, _jumpFrom!),
                                      ),
                                      Transform.translate(
                                        offset: Offset(
                                          width * (1 - t) * direction,
                                          0,
                                        ),
                                        child: _page(context, _jumpTo),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              OrionSpacing.space24,
                              0,
                              OrionSpacing.space24,
                              OrionSpacing.space16,
                            ),
                            child: _sampleBar(
                              style: OrionNavigationBarStyle.from(
                                frosted: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Customization Card
            OrionShowcaseSection(
              title: 'Customization',
              subtitle:
                  'Floating & docked variants, frosted glass, inverted badges, and label modes',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrionShowcaseChoice<_BarSkin>(
                    label: 'Skin',
                    values: _BarSkin.values,
                    selected: _skin,
                    labelOf: _skinLabel,
                    onChanged: (value) => setState(() => _skin = value),
                  ),
                  const SizedBox(height: OrionSpacing.space24),
                  _sampleBar(
                    variant: _skinVariant,
                    useSafeArea: false,
                    style: _skinStyle(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Playground Card
            OrionShowcaseSection(
              title: 'Playground',
              subtitle: 'Interactive bar specimen with live code generator',
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                preview: _sampleBar(
                  variant: _skinVariant,
                  useSafeArea: false,
                  style: _skinStyle(context),
                ),
                code: _snippet,
              ),
            ),
          ],
        );
      },
    );
  }
}
