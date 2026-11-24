# Orion UI

A zero-dependency, physics-driven Flutter UI component kit with analytical spring motion, semantic tokens, and composable 3-layer style overrides.

## Why Orion UI?

- **One Spring, Retargeted:** Continuous `SpringSimulation` retargeting preserves position and velocity mid-flight without snapping.
- **Scroll-First Gesture Cooperation:** Passive pointer tracking lets parent `Scrollable` widgets win the gesture arena without lag.
- **Rebuild Isolation:** Frame ticks update only transform/paint layers around pre-built child subtrees.
- **Zero External Dependencies:** Pure Flutter SDK only.

## Installation

### From GitHub

```yaml
dependencies:
  orion_ui:
    git:
      url: https://github.com/fikrilal/orion-ui.git
      ref: main
```

## Quick Start

Install the Orion theme on your `MaterialApp` (or apply it onto your existing `ThemeData`):

```dart
import 'package:flutter/material.dart';
import 'package:orion_ui/orion_ui.dart';

void main() {
  runApp(
    MaterialApp(
      theme: OrionTheme.light(),
      darkTheme: OrionTheme.dark(),
      home: const DemoPage(),
    ),
  );
}
```

Or merge Orion tokens into an existing app theme:

```dart
theme: OrionTheme.apply(existingTheme),
```

## Usage

```dart
OrionButton(
  variant: OrionButtonVariant.glow,
  size: OrionButtonSize.large,
  onPressed: () async => submit(), // Automatically locks while Future is in-flight
  leading: const Icon(Icons.rocket_launch),
  child: const Text('Deploy'),
);

OrionSwitch(
  value: enabled,
  onChanged: (value) => setState(() => enabled = value),
);

OrionSegmentedControl<String>(
  segments: const [
    OrionSegment(value: 'overview', label: Text('Overview')),
    OrionSegment(value: 'live', label: Text('Live')),
    OrionSegment(value: 'tickets', label: Text('Tickets')),
  ],
  value: selected,
  onChanged: (value) => setState(() => selected = value),
);
```

## 3-Layer Styling Architecture

Every component resolves its look and physics through three composable layers:
1. **Preset** — variant and size defaults.
2. **Ambient Theme (`ThemeExtension`)** — app-wide overrides registered on `ThemeData`.
3. **Instance `style`** — call-site adjustments via `*.from(...)` without restating unchanged fields.

```dart
// 1. App-wide override via ThemeExtension
OrionTheme.apply(
  OrionTheme.light(),
  extensions: [
    OrionButtonTheme(
      variantStyles: {
        OrionButtonVariant.solid: OrionButtonStyle.from(
          backgroundColor: Colors.indigo,
        ),
      },
    ),
  ],
);

// 2. Per-instance override
OrionButton(
  onPressed: save,
  style: OrionButtonStyle.from(
    borderRadius: BorderRadius.circular(20),
    pressedScale: 0.97,
    pressSpring: OrionSpringSpec.snappy,
  ),
  child: const Text('Save'),
);
```

## Included Components

| Category | Components |
| :--- | :--- |
| **Core & Motion** | `OrionPressable`, `OrionSpringDriver`, `OrionSpringSpec`, `OrionHaptics` |
| **Theme & Tokens** | `OrionTheme`, `OrionThemeData`, `OrionColors`, `OrionSpacing`, `OrionRadii`, `OrionSizing` |
| **Actions & Inputs** | `OrionButton`, `OrionTextField`, `OrionOtpField`, `OrionCheckbox`, `OrionRadio`, `OrionSwitch`, `OrionSlider`, `OrionCounter`, `OrionDropdown`, `OrionCalendar`, `OrionWheelPicker` |
| **Navigation & Selection** | `OrionNavigationBar`, `OrionSegmentedControl`, `OrionTabs`, `OrionChip`, `OrionSwipeActionRow` |
| **Surfaces & Overlays** | `OrionAccordion`, `OrionBottomSheet`, `OrionDialog`, `OrionPopover`, `OrionMenu`, `OrionTooltip`, `OrionToaster` / `OrionToast` |
| **Feedback & Status** | `OrionBadge`, `OrionLinearProgress`, `OrionSegmentedProgress` |

## License

MIT License — see [LICENSE](LICENSE).
