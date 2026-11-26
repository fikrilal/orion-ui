# Changelog

All notable changes to **Orion UI** are documented in this file.

## 0.2.1

Visual contrast, modal theme propagation, icon tinting, and navigation badge layout fixes verified across light and dark themes.

### Fixed
- **Modal routes & dropdown sheets:** Captured ambient `InheritedTheme` in `showOrionBottomSheet`, `showOrionDialog`, and `showOrionMenu` so modals (including `OrionDatePickerSheet` and `OrionDropdown` sheet mode) inherit locally scoped light/dark themes. `OrionDropdown` bottom sheets also now resolve their style dynamically from the live sheet `Theme`.
- **Theme & dark-mode contrast (`OrionColors`):** Added explicit Material 3 container roles (`primaryContainer`, `secondaryContainer`, `tertiary`/`tertiaryContainer`, `errorContainer`, `surfaceContainerLowest`, `surfaceContainerLow`, and `surfaceContainerHigh`) to both `lightScheme` and `darkScheme`, and updated `darkScheme.onError` to `#171717` for WCAG AA+ contrast on `#FF6467`.
- **Icon foreground propagation (`OrionButton`, `OrionChip`):** Propagated resolved button and chip foreground colors and icon sizes via `IconTheme.merge` to `OrionButton.child` (unified across the full button row) and `OrionChip.label`.
- **Navigation bar count badges (`OrionNavigationBar`):** Anchored non-dot count badges outward from the icon shoulder so multi-digit badges (`12`, `99+`) never cover the destination icon, and added expanding-mode (`OrionNavigationLabelMode.selected`) layout so count badges glide cleanly inline beside the revealed label without overlap.
- **Example showcase:** Moved `Theme.of(context)` and modal context lookups inside `OrionThemedScaffold.builder`, inherited parent brightness on open, replaced the AppBar toggle with `OrionSwitch`, and polished avatar contrast and synchronous modal launch triggers.

## 0.2.0

A ground-up audit and polish pass across all 25 component families, adding new multi-control widgets, unified dark-mode elevation, keyboard/RTL/safe-area correctness, and a full interactive example showcase app.

### Added
- **New components:**
  - `OrionRangeSlider` for dual-thumb range selection with haptics, tick marks, and value tooltips.
  - `OrionRadioGroup` with card/horizontal layouts, keyboard navigation, and `FormField` validation.
  - `OrionCircularProgress` with determinate, indeterminate, and semantic tone variants.
  - `OrionChipGroup` for single/multi-select filter and removable tag groups.
  - `OrionDatePickerSheet` (`showOrionDatePickerSheet` / `showOrionDateRangePickerSheet`) modal sheet date pickers.
- **Interactive Showcase App (`example/`):** Live playground and code-snippet viewer covering all 25 component families in both light and dark mode.
- **GitHub Actions CI:** Automated formatting, static analysis, and test verification for both the package and `example/`.

### Changed & Improved
- **Motion & Core:** Refined default `pressScale` (`0.985`) and tightened `OrionSpringSpec.snappy` for crisper tactile feedback.
- **Inputs & Pickers:**
  - `OrionWheelPicker`: True iOS cylindrical 3D projection (`diameterRatio`, `perspective`, `squeeze`, `offAxisFraction`), translucent pill & hairline centre loupe, infinite `looping`, mouse-wheel/trackpad scroll, touch-to-catch momentum, asymptotic rubber-banding, live `onActiveChanged`, and dynamic list-shrink safety.
  - `OrionTextField`: Synchronized `FormField` (`reset`/`save`/`initialValue`), refined `13/14/15 pt` typography, full-box hit-testing, animated clear button, numeric filter, multiline crash guards, hover states, and style `lerp`.
  - `OrionOtpField`: Added `outline`, `filled`, and `underline` variants, masked semantics, formatted/long-press paste, and responsive slot scaling.
  - `OrionSwitch`: RTL-aware horizontal drag-to-toggle with flick handoff, stadium capsule press elongation, size presets, thumb icons, labeled rows, and elevated light-mode thumb contrast.
  - `OrionSlider`: NaN/geometry guards, tick marks, live value tooltip, track tap, haptics, and theme `lerp`.
  - `OrionCalendar`: Range selection, month/year picker view, swipe paging, and modal sheet integration.
  - `OrionDropdown`: Multi-select mode, sheet picker presentation, combobox search, grouped sections, and zero-cooldown close.
  - `OrionCheckbox`: Stroke-drawn animated checkmark, tactile press dip, and clickable `label`/`subtitle` rows.
  - `OrionCounter`: General `num` formatting, negative carries, cached metrics, smooth width glide, and motion-aware edge fade.
- **Overlays & Surfaces:**
  - `OrionToaster` / `OrionToast`: Elevated dark surfaces, uniform stack widths, dual-axis horizontal & anchor-edge vertical swipe, mobile tap-to-pin expansion + outside-tap collapse, calm anchor-edge exits, unstripped safe-area & soft-keyboard IME lift, corner anchors, scoped `OrionToastController`, `richColors`, countdown `showProgressBar`, and separated `promise` success/error actions.
  - `OrionTooltip`: Non-competing `tap` over buttons, keyboard `Focus` + `Escape`, single-active warm-window handoff without `_activeCount` leaks, unstripped safe-area & keyboard insets, RTL `start`/`end`, mobile cross-axis fallback, `OrionTooltipTone.surface`, automatic `DefaultTextStyle`/`IconTheme` for `richMessage`, and rounded-tip seam-bridged arrow.
  - `OrionPopover` & `OrionMenu`: Reactive styles, zero-cooldown close, seamless shadowed arrows, keyboard navigation, section headers, and checkmarks.
  - `OrionDialog`: Guarded back/`dismissOf`, style propagation, keyboard lift, vertical CTA ordering, and dark-mode contrast polish.
  - `OrionBottomSheet`: `fitContent`, floating variant, keyboard lift, scroll handoff, and crisp dismiss completion.
  - `OrionAccordion`: Refined disclosure physics, press wash, fade reveal, and `title` shorthand.
- **Navigation, Lists & Feedback:**
  - `OrionTabs`: Clean `underline` / `pill` variants, indicator-synced ink cross-fade, baseline divider, scroll edge fades, deterministic `PageController` sync, and keyboard navigation.
  - `OrionNavigationBar`: Docked & frosted variants, `selectedIcon`, dot/count badges, concentric expanding gaps, and focus/layout fixes.
  - `OrionSegmentedControl`: Concentric pill geometry, drag-to-scrub, pill-synced ink, size presets, intrinsic icon-only width, and disabled segments.
  - `OrionSwipeActionRow` & `OrionSwipeScope`: Unified RTL physics, full-swipe morph, zero-bleed panes, programmatic controller, and style/theme support.
  - `OrionButton`, `OrionBadge`, `OrionChip`, `OrionLinearProgress`, `OrionSegmentedProgress`: Shorthand `label` support, hover/press surface feedback, semantic tones, smooth buffer animation, and theme `lerp`.

### Removed
- Removed redundant `OrionCard` component in favor of composable Flutter surfaces and Orion theme tokens.

## 0.1.0

- Initial release of Orion UI.
- Analytical spring motion engine (`OrionSpringDriver`, `OrionSpringSpec`) and scroll-cooperative `OrionPressable`.
- Theme & token system (`OrionTheme`, `OrionThemeData`, `OrionColors`, `OrionSpacing`, `OrionRadii`, `OrionSizing`).
- Initial physics-driven component suite with three-layer style resolution (preset, ambient `ThemeExtension`, and per-instance style override).
