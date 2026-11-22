import 'package:flutter/material.dart';
import 'package:orion_ui/orion_ui.dart';

import 'package:orion_ui_example/showcase/orion_accordion_showcase_screen.dart';
import 'package:orion_ui_example/showcase/orion_badge_showcase_screen.dart';
import 'package:orion_ui_example/showcase/orion_bottom_sheet_showcase_screen.dart';
import 'package:orion_ui_example/showcase/orion_button_showcase_screen.dart';
import 'package:orion_ui_example/showcase/orion_calendar_showcase_screen.dart';
import 'package:orion_ui_example/showcase/orion_card_showcase_screen.dart';
import 'package:orion_ui_example/showcase/orion_checkbox_showcase_screen.dart';
import 'package:orion_ui_example/showcase/orion_chip_showcase_screen.dart';
import 'package:orion_ui_example/showcase/orion_counter_showcase_screen.dart';
import 'package:orion_ui_example/showcase/orion_dialog_showcase_screen.dart';
import 'package:orion_ui_example/showcase/orion_dropdown_showcase_screen.dart';
import 'package:orion_ui_example/showcase/orion_navigation_showcase_screen.dart';
import 'package:orion_ui_example/showcase/orion_otp_showcase_screen.dart';
import 'package:orion_ui_example/showcase/orion_popover_showcase_screen.dart';
import 'package:orion_ui_example/showcase/orion_progress_showcase_screen.dart';
import 'package:orion_ui_example/showcase/orion_radio_showcase_screen.dart';
import 'package:orion_ui_example/showcase/orion_segmented_showcase_screen.dart';
import 'package:orion_ui_example/showcase/orion_slider_showcase_screen.dart';
import 'package:orion_ui_example/showcase/orion_swipe_showcase_screen.dart';
import 'package:orion_ui_example/showcase/orion_switch_showcase_screen.dart';
import 'package:orion_ui_example/showcase/orion_tabs_showcase_screen.dart';
import 'package:orion_ui_example/showcase/orion_text_field_showcase_screen.dart';
import 'package:orion_ui_example/showcase/orion_toast_showcase_screen.dart';
import 'package:orion_ui_example/showcase/orion_tooltip_showcase_screen.dart';
import 'package:orion_ui_example/showcase/orion_wheel_showcase_screen.dart';

/// Index of all 25 Orion UI component showcases.
class OrionShowcaseScreen extends StatelessWidget {
  const OrionShowcaseScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  final bool isDark;
  final VoidCallback onToggleTheme;

  static final List<_OrionShowcaseEntry> _entries = <_OrionShowcaseEntry>[
    _OrionShowcaseEntry(
      title: 'Accordion',
      subtitle: 'A panel that unfolds on the spring',
      icon: Icons.unfold_more_rounded,
      builder: (BuildContext context) => const OrionAccordionShowcaseScreen(),
    ),
    _OrionShowcaseEntry(
      title: 'Badges',
      subtitle: 'Default pill, role tints, and an optional border',
      icon: Icons.local_offer_outlined,
      builder: (BuildContext context) => const OrionBadgeShowcaseScreen(),
    ),
    _OrionShowcaseEntry(
      title: 'Bottom sheet',
      subtitle:
          'Multi-detent surface with velocity projection and rubber-banding',
      icon: Icons.vertical_align_bottom_rounded,
      builder: (BuildContext context) => const OrionBottomSheetShowcaseScreen(),
    ),
    _OrionShowcaseEntry(
      title: 'Buttons',
      subtitle: 'Variants, sizes, icons, loading, and width',
      icon: Icons.smart_button_rounded,
      builder: (BuildContext context) => const OrionButtonShowcaseScreen(),
    ),
    _OrionShowcaseEntry(
      title: 'Calendar',
      subtitle: 'A month grid for a single day',
      icon: Icons.calendar_month_outlined,
      builder: (BuildContext context) => const OrionCalendarShowcaseScreen(),
    ),
    _OrionShowcaseEntry(
      title: 'Cards',
      subtitle: 'Plain, frosted, pressable, radius, and padding',
      icon: Icons.credit_card_outlined,
      builder: (BuildContext context) => const OrionCardShowcaseScreen(),
    ),
    _OrionShowcaseEntry(
      title: 'Checkbox',
      subtitle: 'A box that confirms and can sit in between',
      icon: Icons.check_box_outlined,
      builder: (BuildContext context) => const OrionCheckboxShowcaseScreen(),
    ),
    _OrionShowcaseEntry(
      title: 'Chip',
      subtitle: 'A pill that selects on its own',
      icon: Icons.label_outline_rounded,
      builder: (BuildContext context) => const OrionChipShowcaseScreen(),
    ),
    _OrionShowcaseEntry(
      title: 'Counter',
      subtitle: 'Digits that roll to the next value',
      icon: Icons.pin_outlined,
      builder: (BuildContext context) => const OrionCounterShowcaseScreen(),
    ),
    _OrionShowcaseEntry(
      title: 'Dialog',
      subtitle: 'Centered modal surfaces, confirmations, and alerts',
      icon: Icons.web_asset_rounded,
      builder: (BuildContext context) => const OrionDialogShowcaseScreen(),
    ),
    _OrionShowcaseEntry(
      title: 'Dropdown',
      subtitle: 'A single-select field with anchored transform-origin blossom',
      icon: Icons.arrow_drop_down_circle_outlined,
      builder: (BuildContext context) => const OrionDropdownShowcaseScreen(),
    ),
    _OrionShowcaseEntry(
      title: 'Navigation',
      subtitle: 'A floating bar that follows the page',
      icon: Icons.navigation_outlined,
      builder: (BuildContext context) => const OrionNavigationShowcaseScreen(),
    ),
    _OrionShowcaseEntry(
      title: 'OTP field',
      subtitle: 'One-time passcode and PIN slots with tactile spring physics',
      icon: Icons.password_rounded,
      builder: (BuildContext context) => const OrionOtpShowcaseScreen(),
    ),
    _OrionShowcaseEntry(
      title: 'Popover & menu',
      subtitle:
          'Anchored floating surfaces and dropdown menus with dynamic origin',
      icon: Icons.more_horiz_rounded,
      builder: (BuildContext context) => const OrionPopoverShowcaseScreen(),
    ),
    _OrionShowcaseEntry(
      title: 'Progress',
      subtitle: 'Steps across a quiet track',
      icon: Icons.linear_scale_rounded,
      builder: (BuildContext context) => const OrionProgressShowcaseScreen(),
    ),
    _OrionShowcaseEntry(
      title: 'Radio',
      subtitle: 'A circle that marks the one chosen option',
      icon: Icons.radio_button_checked_rounded,
      builder: (BuildContext context) => const OrionRadioShowcaseScreen(),
    ),
    _OrionShowcaseEntry(
      title: 'Segments',
      subtitle: 'Single choice and a sliding pill',
      icon: Icons.view_week_outlined,
      builder: (BuildContext context) => const OrionSegmentedShowcaseScreen(),
    ),
    _OrionShowcaseEntry(
      title: 'Slider',
      subtitle: 'A thumb that follows the finger and snaps on release',
      icon: Icons.tune_rounded,
      builder: (BuildContext context) => const OrionSliderShowcaseScreen(),
    ),
    _OrionShowcaseEntry(
      title: 'Swipe',
      subtitle: 'A row that reveals its actions under a drag',
      icon: Icons.swipe_left_outlined,
      builder: (BuildContext context) => const OrionSwipeShowcaseScreen(),
    ),
    _OrionShowcaseEntry(
      title: 'Switch',
      subtitle: 'A thumb that slides on a quiet track',
      icon: Icons.toggle_on_outlined,
      builder: (BuildContext context) => const OrionSwitchShowcaseScreen(),
    ),
    _OrionShowcaseEntry(
      title: 'Tabs',
      subtitle:
          'Kinetic stretching indicator, zero-ghosting tabs, and PageView sync',
      icon: Icons.tab_rounded,
      builder: (BuildContext context) => const OrionTabsShowcaseScreen(),
    ),
    _OrionShowcaseEntry(
      title: 'Text field',
      subtitle: 'A single line with a quiet focus ring',
      icon: Icons.text_fields_rounded,
      builder: (BuildContext context) => const OrionTextFieldShowcaseScreen(),
    ),
    _OrionShowcaseEntry(
      title: 'Toast',
      subtitle: 'A perspective card stack that expands on hold',
      icon: Icons.layers_outlined,
      builder: (BuildContext context) => const OrionToastShowcaseScreen(),
    ),
    _OrionShowcaseEntry(
      title: 'Tooltip',
      subtitle: 'Anchor-aware guidance with spring glide and autonomous carets',
      icon: Icons.chat_bubble_outline_rounded,
      builder: (BuildContext context) => const OrionTooltipShowcaseScreen(),
    ),
    _OrionShowcaseEntry(
      title: 'Wheel',
      subtitle: 'A picker that rolls and snaps to a detent',
      icon: Icons.donut_large_rounded,
      builder: (BuildContext context) => const OrionWheelShowcaseScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool dark = theme.brightness == Brightness.dark;

    final Color iconBgColor = dark
        ? scheme.onSurface.withValues(alpha: 0.06)
        : scheme.onSurface.withValues(alpha: 0.035);
    final Color iconBorderColor = dark
        ? scheme.outlineVariant.withValues(alpha: 0.20)
        : scheme.outlineVariant.withValues(alpha: 0.28);
    final Color iconColor = scheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orion Showcase'),
        actions: <Widget>[
          IconButton(
            tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
            onPressed: onToggleTheme,
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          OrionSpacing.space16,
          OrionSpacing.space8,
          OrionSpacing.space16,
          OrionSpacing.space24,
        ),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
              bottom: OrionSpacing.space12,
              top: OrionSpacing.space4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  '${_entries.length} COMPONENTS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: OrionSpacing.space8,
                    vertical: 2.0,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(OrionRadii.radiusPill),
                  ),
                  child: Text(
                    'A–Z',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ..._entries.map((_OrionShowcaseEntry entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: OrionSpacing.space8),
              child: OrionPressable(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: entry.builder),
                  );
                },
                pressedScale: 0.98,
                child: Container(
                  decoration: BoxDecoration(
                    color: dark ? scheme.surfaceContainerLow : scheme.surface,
                    borderRadius: BorderRadius.circular(OrionRadii.radius12),
                    border: Border.all(
                      color: dark
                          ? scheme.outlineVariant.withValues(alpha: 0.15)
                          : scheme.outlineVariant.withValues(alpha: 0.30),
                      width: 1,
                    ),
                    boxShadow: dark
                        ? const <BoxShadow>[]
                        : const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x06000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: OrionSpacing.space16,
                    vertical: OrionSpacing.space12,
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          borderRadius: BorderRadius.circular(
                            OrionRadii.radius12,
                          ),
                          border: Border.all(color: iconBorderColor, width: 1),
                        ),
                        child: Center(
                          child: Icon(entry.icon, size: 22, color: iconColor),
                        ),
                      ),
                      const SizedBox(width: OrionSpacing.space16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              entry.title,
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: OrionSpacing.space4),
                            Text(
                              entry.subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: scheme.onSurfaceVariant,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: OrionSpacing.space8),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _OrionShowcaseEntry {
  const _OrionShowcaseEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;
}
