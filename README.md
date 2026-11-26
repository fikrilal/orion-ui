<div align="center">

# Orion UI

**A zero-dependency, physics-driven Flutter UI component kit.**  
Analytical spring motion · Tactile gestures · Semantic tokens · Composable 3-layer styling

[![pub.dev](https://img.shields.io/pub/v/orion_ui?style=flat-square&color=171717&logo=dart&logoColor=white)](https://pub.dev/packages/orion_ui)
[![Pub Points](https://img.shields.io/pub/points/orion_ui?style=flat-square&color=02569B)](https://pub.dev/packages/orion_ui/score)
[![CI](https://img.shields.io/github/actions/workflow/status/fikrilal/orion-ui/ci.yml?branch=main&style=flat-square&label=CI)](https://github.com/fikrilal/orion-ui/actions/workflows/ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.29.0-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dependencies](https://img.shields.io/badge/dependencies-0-16A34A?style=flat-square)](pubspec.yaml)
[![License: MIT](https://img.shields.io/badge/license-MIT-525252?style=flat-square)](LICENSE)

[pub.dev](https://pub.dev/packages/orion_ui) · [Installation](#installation) · [Quick Start](#quick-start) · [Styling](#3-layer-styling) · [Components](#components) · [Showcase App](#showcase-app)

</div>

---

## Why Orion UI?

- **Continuous Spring Physics:** Every interactive component runs on retargetable `SpringSimulation` (`OrionSpringDriver`), preserving position and velocity mid-flight with zero snapping and full `MediaQuery.disableAnimations` reduced-motion support.
- **Scroll-First Gesture Cooperation:** Passive pointer tracking (`OrionPressable`) lets ancestor `Scrollable` widgets win the gesture arena naturally without touch lag.
- **Rebuild Isolation:** Animation ticks drive transform and paint layers around pre-built subtrees so your labels and children never rebuild on every frame.
- **Pure Flutter, Zero Dependencies:** Built exclusively on the Flutter SDK — light & dark neutral themes out of the box, RTL-aware geometry, keyboard navigation, and accessible semantics.

---

## Installation

```bash
flutter pub add orion_ui
```

Or add it manually to your `pubspec.yaml`:

```yaml
dependencies:
  orion_ui: ^0.2.1
```

---

## Quick Start

### 1. Apply the Theme

Use the built-in light and dark neutral themes, or merge Orion tokens into your existing `ThemeData`:

```dart
import 'package:flutter/material.dart';
import 'package:orion_ui/orion_ui.dart';

void main() {
  runApp(
    MaterialApp(
      theme: OrionTheme.light(),
      darkTheme: OrionTheme.dark(),
      builder: (context, child) => OrionToaster(child: child),
      home: const DemoPage(),
    ),
  );
}
```

Or keep your existing `ColorScheme` and typography:

```dart
theme: OrionTheme.apply(existingTheme),
```

### 2. Use Components

```dart
// Async-safe button (locks automatically while the Future is in flight)
OrionButton(
  variant: OrionButtonVariant.solid,
  leading: const Icon(Icons.rocket_launch_rounded, size: 16),
  label: 'Deploy',
  onPressed: () async {
    await OrionToast.promise(
      deployRelease(),
      loading: 'Deploying release…',
      success: (_) => 'Deployed cleanly',
      error: (err) => 'Deploy failed: $err',
    );
  },
);

// Labeled switch with horizontal drag-to-toggle & capsule physics
OrionSwitch(
  value: notificationsEnabled,
  label: 'Push notifications',
  subtitle: 'Receive deploy and alert updates',
  onChanged: (value) => setState(() => notificationsEnabled = value),
);

// Cylindrical 3D looping wheel picker
SizedBox(
  width: 96,
  child: OrionWheelPicker<int>(
    items: [
      for (int m = 0; m < 60; m++)
        OrionWheelItem(value: m, label: Text(m.toString().padLeft(2, '0'))),
    ],
    value: minute,
    looping: true,
    onChanged: (value) => setState(() => minute = value),
  ),
);
```

---

## 3-Layer Styling

Every component resolves appearance and physics through three composable layers — each overriding only the properties it specifies:

1. **Preset** — Built-in variant, size, and `ColorScheme` defaults.
2. **Ambient Theme (`ThemeExtension`)** — App-wide overrides registered via `OrionTheme.apply`.
3. **Instance `style`** — Local overrides via `*.from(...)` without restating untouched values.

```dart
// App-wide default via ThemeExtension
final theme = OrionTheme.apply(
  OrionTheme.light(),
  extensions: [
    OrionButtonTheme(
      variantStyles: {
        OrionButtonVariant.solid: OrionButtonStyle.from(
          backgroundColor: const Color(0xFF4F46E5),
        ),
      },
    ),
  ],
);

// Call-site refinement
OrionButton(
  label: 'Save',
  onPressed: save,
  style: OrionButtonStyle.from(
    borderRadius: BorderRadius.circular(20),
    pressedScale: 0.97,
    pressSpring: OrionSpringSpec.snappy,
  ),
);
```

---

## Components

25 component families, all zero-dependency and light/dark ready:

| Category | Components | Highlights |
| :--- | :--- | :--- |
| **Actions** | `OrionButton`, `OrionSwipeActionRow`, `OrionSwipeScope` | Async in-flight locking, full-swipe morph, RTL swipe panes |
| **Text & Code Inputs** | `OrionTextField`, `OrionOtpField` | Synced `FormField`, clearable search, OTP paste & variants |
| **Selection Controls** | `OrionCheckbox`, `OrionRadio`, `OrionRadioGroup`, `OrionSwitch`, `OrionChip`, `OrionChipGroup` | Stroke-drawn check, drag-to-toggle capsule switch, grouped radio/chips |
| **Pickers & Ranges** | `OrionSlider`, `OrionRangeSlider`, `OrionDropdown`, `OrionCalendar`, `OrionDatePickerSheet`, `OrionWheelPicker` | Dual-thumb slider, searchable multi-select, range calendar, iOS 3D looping drum |
| **Navigation** | `OrionNavigationBar`, `OrionSegmentedControl`, `OrionTabs` | Docked/frosted bar with badges, scrubbable pill segment, edge-faded tabs |
| **Overlays & Surfaces** | `OrionBottomSheet`, `OrionDialog`, `OrionPopover`, `OrionMenu`, `OrionTooltip`, `OrionAccordion` | Keyboard-lifting sheets/dialogs, warm-window tooltips, seamless arrows |
| **Feedback & Data** | `OrionToaster` / `OrionToast`, `OrionBadge`, `OrionCounter`, `OrionLinearProgress`, `OrionCircularProgress`, `OrionSegmentedProgress` | Perspective-stacked swipable toasts, rolling numeric counter, semantic progress |
| **Foundations** | `OrionPressable`, `OrionSpringDriver`, `OrionSpringSpec`, `OrionHaptics`, `OrionTheme`, `OrionColors`, `OrionSpacing`, `OrionRadii`, `OrionSizing` | Retargetable physics core and semantic design tokens |

---

## Showcase App

Explore every component interactively — with live controls, light/dark toggle, and copyable code snippets — using the bundled example app:

```bash
cd example
flutter pub get
flutter run
```

---

## Development

```bash
# Format check
dart format --output=none --set-exit-if-changed lib test example/lib example/test

# Static analysis
flutter analyze
(cd example && flutter analyze)

# Run full test suites
flutter test
(cd example && flutter test)
```

---

## License

MIT License — see [LICENSE](LICENSE) for details.
