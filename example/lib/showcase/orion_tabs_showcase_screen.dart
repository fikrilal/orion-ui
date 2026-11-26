import 'package:flutter/material.dart';
import 'package:orion_ui/orion_ui.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';

/// Playground and verification showcase for [OrionTabs].
class OrionTabsShowcaseScreen extends StatefulWidget {
  const OrionTabsShowcaseScreen({super.key});

  @override
  State<OrionTabsShowcaseScreen> createState() =>
      _OrionTabsShowcaseScreenState();
}

class _OrionTabsShowcaseScreenState extends State<OrionTabsShowcaseScreen> {
  OrionTabsVariant _variant = OrionTabsVariant.underline;
  OrionTabsDistribution _distribution = OrionTabsDistribution.intrinsic;
  bool _showDivider = true;
  bool _fadeEdges = true;
  String _selectedHeroTab = 'overview';
  String _selectedScrollTab = 'all';

  late final PageController _pageController;
  int _selectedPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String get _snippet {
    final List<String> lines = <String>[
      'OrionTabs<String>(',
      "  value: '$_selectedHeroTab',",
      '  variant: OrionTabsVariant.${_variant.name},',
      '  distribution: OrionTabsDistribution.${_distribution.name},',
      if (_variant == OrionTabsVariant.underline && !_showDivider)
        '  showDivider: false,',
      if (!_fadeEdges) '  fadeEdges: false,',
      '  onChanged: (val) => setState(() => _selectedHeroTab = val),',
      '  tabs: const [',
      "    OrionTab(value: 'overview', label: 'Overview', icon: Icon(Icons.dashboard_rounded)),",
      "    OrionTab(value: 'activity', label: 'Activity'),",
      "    OrionTab(value: 'pulls', label: 'Pulls', badge: OrionBadge.count(value: 12)),",
      "    OrionTab(value: 'issues', label: 'Issues', badge: OrionBadge.count(value: 4)),",
      "    OrionTab(value: 'billing', label: 'Billing', disabled: true, tooltip: 'Requires admin role'),",
      "    OrionTab(value: 'settings', label: 'Settings', icon: Icon(Icons.settings_rounded)),",
      '  ],',
      ');',
    ];
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return OrionThemedScaffold(
      title: 'Orion Tabs',
      builder: (BuildContext context) {
        final ThemeData theme = Theme.of(context);
        final ColorScheme scheme = theme.colorScheme;
        final bool isDark = theme.brightness == Brightness.dark;
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
                      'NAVIGATION • TABS',
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
                    'Top-level view navigation tabs powered by velocity-driven '
                    'spring physics, indicator-synced ink cross-fades, baseline '
                    'hairline dividers, scroll edge fades, and real-time '
                    'PageView synchronization.',
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
                  'Compare underline and pill indicators, baseline dividers, disabled skipping, and scroll edge fades',
              card: true,
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-tabs-playground'),
                code: _snippet,
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: OrionSpacing.space16,
                        horizontal: OrionSpacing.space8,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(
                          OrionRadii.radius12,
                        ),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Center(
                        child: OrionTabs<String>(
                          value: _selectedHeroTab,
                          variant: _variant,
                          distribution: _distribution,
                          showDivider: _showDivider,
                          fadeEdges: _fadeEdges,
                          onChanged: (String val) =>
                              setState(() => _selectedHeroTab = val),
                          tabs: const <OrionTab<String>>[
                            OrionTab<String>(
                              value: 'overview',
                              label: 'Overview',
                              icon: Icon(Icons.dashboard_rounded),
                            ),
                            OrionTab<String>(
                              value: 'activity',
                              label: 'Activity',
                            ),
                            OrionTab<String>(
                              value: 'pulls',
                              label: 'Pulls',
                              semanticLabel: 'Pull requests, 12 open',
                              badge: OrionBadge.count(value: 12),
                            ),
                            OrionTab<String>(
                              value: 'issues',
                              label: 'Issues',
                              semanticLabel: 'Issues, 4 open',
                              badge: OrionBadge.count(value: 4),
                            ),
                            OrionTab<String>(
                              value: 'billing',
                              label: 'Billing',
                              disabled: true,
                              tooltip: 'Requires admin role',
                            ),
                            OrionTab<String>(
                              value: 'settings',
                              label: 'Settings',
                              icon: Icon(Icons.settings_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: OrionSpacing.space12),
                    Text(
                      'Selected Tab: $_selectedHeroTab',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: OrionSpacing.space16),
                    OrionShowcaseControls(
                      children: <Widget>[
                        OrionShowcaseChoice<OrionTabsVariant>(
                          label: 'Variant',
                          selected: _variant,
                          values: const <OrionTabsVariant>[
                            OrionTabsVariant.underline,
                            OrionTabsVariant.pill,
                          ],
                          labelOf: (OrionTabsVariant v) => switch (v) {
                            OrionTabsVariant.underline => 'UNDERLINE',
                            OrionTabsVariant.pill => 'PILL',
                          },
                          onChanged: (OrionTabsVariant v) =>
                              setState(() => _variant = v),
                        ),
                        OrionShowcaseChoice<OrionTabsDistribution>(
                          label: 'Distribution',
                          selected: _distribution,
                          values: const <OrionTabsDistribution>[
                            OrionTabsDistribution.intrinsic,
                            OrionTabsDistribution.equal,
                          ],
                          labelOf: (OrionTabsDistribution d) => switch (d) {
                            OrionTabsDistribution.intrinsic => 'INTRINSIC',
                            OrionTabsDistribution.equal => 'EQUAL',
                          },
                          onChanged: (OrionTabsDistribution d) =>
                              setState(() => _distribution = d),
                        ),
                        Wrap(
                          spacing: OrionSpacing.space24,
                          runSpacing: OrionSpacing.space12,
                          children: <Widget>[
                            OrionShowcaseToggle(
                              label: 'Baseline Divider',
                              value: _showDivider,
                              onChanged: (bool v) =>
                                  setState(() => _showDivider = v),
                            ),
                            OrionShowcaseToggle(
                              label: 'Edge Fades',
                              value: _fadeEdges,
                              onChanged: (bool v) =>
                                  setState(() => _fadeEdges = v),
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

            // Scrollable Overflow Strip Specimen
            OrionShowcaseSection(
              title: 'Scrollable Category Strip with Edge Fades',
              subtitle:
                  '12 categories with automatic edge-fade masks and smooth auto-centering on selection',
              card: true,
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-tabs-scrollable'),
                code: '''
OrionTabs<String>(
  value: selectedCategory,
  variant: OrionTabsVariant.pill,
  distribution: OrionTabsDistribution.intrinsic,
  fadeEdges: true,
  onChanged: (val) => setState(() => selectedCategory = val),
  tabs: categories.map((cat) => OrionTab(value: cat, label: cat)).toList(),
)''',
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: OrionSpacing.space12,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(
                          OrionRadii.radius12,
                        ),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      child: OrionTabs<String>(
                        value: _selectedScrollTab,
                        variant: OrionTabsVariant.pill,
                        distribution: OrionTabsDistribution.intrinsic,
                        fadeEdges: _fadeEdges,
                        onChanged: (String val) =>
                            setState(() => _selectedScrollTab = val),
                        tabs: const <OrionTab<String>>[
                          OrionTab<String>(value: 'all', label: 'All Projects'),
                          OrionTab<String>(
                            value: 'design',
                            label: 'UI/UX Design',
                          ),
                          OrionTab<String>(value: 'eng', label: 'Engineering'),
                          OrionTab<String>(
                            value: 'product',
                            label: 'Product Roadmaps',
                          ),
                          OrionTab<String>(
                            value: 'infra',
                            label: 'Cloud Infrastructure',
                          ),
                          OrionTab<String>(
                            value: 'security',
                            label: 'AppSec & Auth',
                          ),
                          OrionTab<String>(
                            value: 'mobile',
                            label: 'Flutter Mobile Kit',
                          ),
                          OrionTab<String>(
                            value: 'marketing',
                            label: 'Growth Marketing',
                          ),
                          OrionTab<String>(
                            value: 'finance',
                            label: 'FinTech Ledger',
                          ),
                          OrionTab<String>(
                            value: 'legal',
                            label: 'Compliance & GDPR',
                          ),
                          OrionTab<String>(
                            value: 'research',
                            label: 'AI Models & Labs',
                          ),
                          OrionTab<String>(
                            value: 'analytics',
                            label: 'User Analytics',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: OrionSpacing.space8),
                    Text(
                      'Active Category: $_selectedScrollTab',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: OrionSpacing.space20),

            // Synchronized PageView Playground
            OrionShowcaseSection(
              title: 'Synchronized PageView Playground',
              subtitle:
                  'Drag or flick the cards below — indicator and ink track your finger in real time',
              card: true,
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-tabs-pageview'),
                code: '''
Column(
  children: [
    OrionTabs<int>(
      value: selectedPageIndex,
      pageController: pageController,
      variant: OrionTabsVariant.underline,
      distribution: OrionTabsDistribution.equal,
      onChanged: (idx) => setState(() => selectedPageIndex = idx),
      tabs: const [
        OrionTab(value: 0, label: 'Feed', icon: Icon(Icons.newspaper_rounded)),
        OrionTab(value: 1, label: 'Discover', icon: Icon(Icons.explore_rounded)),
        OrionTab(value: 2, label: 'Profile', icon: Icon(Icons.person_rounded)),
      ],
    ),
    SizedBox(
      height: 132,
      child: PageView(
        controller: pageController,
        children: [...],
      ),
    ),
  ],
)''',
                preview: Column(
                  children: <Widget>[
                    OrionTabs<int>(
                      value: _selectedPageIndex,
                      pageController: _pageController,
                      variant: OrionTabsVariant.underline,
                      distribution: OrionTabsDistribution.equal,
                      onChanged: (int idx) =>
                          setState(() => _selectedPageIndex = idx),
                      tabs: const <OrionTab<int>>[
                        OrionTab<int>(
                          value: 0,
                          label: 'Feed',
                          icon: Icon(Icons.newspaper_rounded),
                        ),
                        OrionTab<int>(
                          value: 1,
                          label: 'Discover',
                          icon: Icon(Icons.explore_rounded),
                        ),
                        OrionTab<int>(
                          value: 2,
                          label: 'Profile',
                          icon: Icon(Icons.person_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: OrionSpacing.space12),
                    SizedBox(
                      height: 128,
                      child: PageView(
                        controller: _pageController,
                        children: <Widget>[
                          _buildPageCard(
                            scheme: scheme,
                            icon: Icons.newspaper_rounded,
                            accent: scheme.primary,
                            title: 'Live Activity Feed',
                            description:
                                'Real-time timeline streams synced cleanly via PageController.',
                          ),
                          _buildPageCard(
                            scheme: scheme,
                            icon: Icons.explore_rounded,
                            accent: scheme.secondary,
                            title: 'Trending Discoveries',
                            description:
                                'Explore curated open-source design systems and motion primitives.',
                          ),
                          _buildPageCard(
                            scheme: scheme,
                            icon: Icons.person_rounded,
                            accent: scheme.tertiary,
                            title: 'User Profile & Config',
                            description:
                                'Manage device haptics, spring tension, and workspace preferences.',
                          ),
                        ],
                      ),
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

  Widget _buildPageCard({
    required ColorScheme scheme,
    required IconData icon,
    required Color accent,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: OrionSpacing.space4),
      padding: const EdgeInsets.all(OrionSpacing.space16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(OrionRadii.radius12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(OrionRadii.radius12),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: OrionSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: OrionSpacing.space4),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
