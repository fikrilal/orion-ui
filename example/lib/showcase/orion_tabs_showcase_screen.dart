import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

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
      '  onChanged: (val) => setState(() => _selectedHeroTab = val),',
      '  tabs: const [',
      "    OrionTab(value: 'overview', label: 'Overview', icon: Icon(Icons.dashboard_rounded)),",
      "    OrionTab(value: 'activity', label: 'Activity'),",
      "    OrionTab(value: 'pulls', label: 'Pulls', badge: OrionBadge.count(value: 12)),",
      "    OrionTab(value: 'issues', label: 'Issues', badge: OrionBadge.count(value: 4)),",
      "    OrionTab(value: 'settings', label: 'Settings', icon: Icon(Icons.settings_rounded)),",
      '  ],',
      ');',
    ];
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return OrionThemedScaffold(
      title: 'Orion Tabs',
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
                    'Physics-driven top-level view navigation tabs featuring '
                    'velocity-driven kinetic indicator stretching, single-tree '
                    'zero-ghosting layout, and real-time PageView swipe sync.',
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
                  'Switch variants and distributions to inspect velocity-driven stretch and layout modes',
              card: true,
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-tabs-playground'),
                code: _snippet,
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: OrionSpacing.space16,
                        horizontal: OrionSpacing.space8,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(OrionRadii.radius12),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Center(
                        child: OrionTabs<String>(
                          value: _selectedHeroTab,
                          variant: _variant,
                          distribution: _distribution,
                          onChanged: (val) =>
                              setState(() => _selectedHeroTab = val),
                          tabs: const [
                            OrionTab(
                              value: 'overview',
                              label: 'Overview',
                              icon: Icon(Icons.dashboard_rounded),
                            ),
                            OrionTab(value: 'activity', label: 'Activity'),
                            OrionTab(
                              value: 'pulls',
                              label: 'Pulls',
                              badge: OrionBadge.count(value: 12),
                            ),
                            OrionTab(
                              value: 'issues',
                              label: 'Issues',
                              badge: OrionBadge.count(value: 4),
                            ),
                            OrionTab(
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
                      children: [
                        OrionShowcaseChoice<OrionTabsVariant>(
                          label: 'Variant',
                          selected: _variant,
                          values: const [
                            OrionTabsVariant.underline,
                            OrionTabsVariant.pill,
                            OrionTabsVariant.segment,
                          ],
                          labelOf: (v) => switch (v) {
                            OrionTabsVariant.underline => 'UNDERLINE',
                            OrionTabsVariant.pill => 'PILL',
                            OrionTabsVariant.segment => 'SEGMENT',
                          },
                          onChanged: (v) => setState(() => _variant = v),
                        ),
                        OrionShowcaseChoice<OrionTabsDistribution>(
                          label: 'Distribution',
                          selected: _distribution,
                          values: const [
                            OrionTabsDistribution.intrinsic,
                            OrionTabsDistribution.equal,
                          ],
                          labelOf: (d) => switch (d) {
                            OrionTabsDistribution.intrinsic => 'INTRINSIC',
                            OrionTabsDistribution.equal => 'EQUAL',
                          },
                          onChanged: (d) => setState(() => _distribution = d),
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
              title: 'Scrollable Long List with Auto-Centering',
              subtitle:
                  '12 categories with horizontal scrolling; taps smoothly scroll the active tab to center',
              card: true,
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-tabs-scrollable'),
                code: '''
OrionTabs<String>(
  value: selectedCategory,
  variant: OrionTabsVariant.pill,
  distribution: OrionTabsDistribution.intrinsic,
  onChanged: (val) => setState(() => selectedCategory = val),
  tabs: categories.map((cat) => OrionTab(value: cat, label: cat)).toList(),
)''',
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: OrionSpacing.space12,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(OrionRadii.radius12),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      child: OrionTabs<String>(
                        value: _selectedScrollTab,
                        variant: OrionTabsVariant.pill,
                        distribution: OrionTabsDistribution.intrinsic,
                        onChanged: (val) =>
                            setState(() => _selectedScrollTab = val),
                        tabs: const [
                          OrionTab(value: 'all', label: 'All Projects'),
                          OrionTab(value: 'design', label: 'UI/UX Design'),
                          OrionTab(value: 'eng', label: 'Engineering'),
                          OrionTab(value: 'product', label: 'Product Roadmaps'),
                          OrionTab(
                            value: 'infra',
                            label: 'Cloud Infrastructure',
                          ),
                          OrionTab(value: 'security', label: 'AppSec & Auth'),
                          OrionTab(
                            value: 'mobile',
                            label: 'Flutter Mobile Kit',
                          ),
                          OrionTab(
                            value: 'marketing',
                            label: 'Growth Marketing',
                          ),
                          OrionTab(value: 'finance', label: 'FinTech Ledger'),
                          OrionTab(value: 'legal', label: 'Compliance & GDPR'),
                          OrionTab(
                            value: 'research',
                            label: 'AI Models & Labs',
                          ),
                          OrionTab(value: 'analytics', label: 'User Analytics'),
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
                  'Swipe the pages below to see the indicator follow your finger in real time',
              card: true,
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-tabs-pageview'),
                code: '''
Column(
  children: [
    OrionTabs<int>(
      pageController: pageController,
      variant: OrionTabsVariant.underline,
      tabs: const [
        OrionTab(value: 0, label: 'Feed'),
        OrionTab(value: 1, label: 'Discover'),
        OrionTab(value: 2, label: 'Profile'),
      ],
    ),
    SizedBox(
      height: 140,
      child: PageView(
        controller: pageController,
        children: [...],
      ),
    ),
  ],
)''',
                preview: Column(
                  children: [
                    OrionTabs<int>(
                      value: _selectedPageIndex,
                      pageController: _pageController,
                      variant: OrionTabsVariant.underline,
                      distribution: OrionTabsDistribution.equal,
                      onChanged: (idx) =>
                          setState(() => _selectedPageIndex = idx),
                      tabs: const [
                        OrionTab(
                          value: 0,
                          label: 'Feed',
                          icon: Icon(Icons.newspaper_rounded),
                        ),
                        OrionTab(
                          value: 1,
                          label: 'Discover',
                          icon: Icon(Icons.explore_rounded),
                        ),
                        OrionTab(
                          value: 2,
                          label: 'Profile',
                          icon: Icon(Icons.person_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: OrionSpacing.space12),
                    SizedBox(
                      height: 120,
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (idx) =>
                            setState(() => _selectedPageIndex = idx),
                        children: [
                          _buildPageCard(
                            title: 'Live Activity Feed',
                            description:
                                'Real-time timeline streams with optimistic updates.',
                            color: scheme.primaryContainer,
                            textColor: scheme.onPrimaryContainer,
                          ),
                          _buildPageCard(
                            title: 'Trending Discoveries',
                            description:
                                'Explore curated open-source design systems and toolkits.',
                            color: scheme.secondaryContainer,
                            textColor: scheme.onSecondaryContainer,
                          ),
                          _buildPageCard(
                            title: 'User Profile & Config',
                            description:
                                'Manage device haptics, spring tension, and accounts.',
                            color: scheme.tertiaryContainer,
                            textColor: scheme.onTertiaryContainer,
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
    required String title,
    required String description,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: OrionSpacing.space4),
      padding: const EdgeInsets.all(OrionSpacing.space16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(OrionRadii.radius12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: OrionSpacing.space4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
