# Orion UI

Tactile, physics-driven design engineering component kit for Flutter.

## Core Philosophy

- **One Spring, Retargeted:** Single continuous `SpringSimulation` without position snapping or velocity truncation.
- **Scroll-First Gesture Cooperation:** Passive pointer monitoring that allows parent `Scrollable` views to win the gesture arena without lag.
- **Rebuild Isolation:** Ticker frame updates only alter the `Transform.scale` matrix around pre-built child subtrees.
- **Decoupled Architecture:** Pure Flutter SDK dependencies only.

## Theme & Tokens

Role colors stay in Material `ColorScheme` and typography in `ThemeData.textTheme`. `OrionTheme.light()` and `OrionTheme.dark()` install the shadcn neutral palette. Orion tokens add what Material cannot express — springs, press scale, haptics, radii, blur, and elevation.

```dart
MaterialApp(
  theme: OrionTheme.light(),
  darkTheme: OrionTheme.dark(),
);

// Or register on an existing theme:
theme: OrionTheme.apply(hostTheme),

// Then read tokens anywhere:
final tokens = OrionTheme.of(context);
```

- `OrionSpacing` / `OrionRadii` / `OrionSizing` — compile-time token scales (values mirror the host app's `AppSpacing`/`AppRadii`/`AppSizing`).
- `OrionThemeData` — a `ThemeExtension` carrying motion, radii, blur, and shadow tokens.
- `OrionTheme.of(context)` — a single lookup over `ThemeData.extensions` with a documented fallback.

## Components

Concrete widgets built on the primitives and tokens. Role colors come from the host `ColorScheme`.

```dart
OrionButton(
  variant: OrionButtonVariant.glow,
  size: OrionButtonSize.large,
  onPressed: () async => submit(), // async actions lock the button automatically
  leading: const Icon(Icons.rocket_launch),
  child: const Text('Deploy'),
);

OrionCard(
  frosted: true,
  onTap: () {},
  child: const Text('The blur is a static layer: press feedback never scales it.'),
);

OrionBadge(child: const Text('New'));

OrionSegmentedControl<String>(
  segments: const [
    OrionSegment(value: 'overview', label: Text('Overview')),
    OrionSegment(value: 'live', label: Text('Live')),
    OrionSegment(value: 'tickets', label: Text('Tickets')),
  ],
  value: selected,
  onChanged: (value) => setState(() => selected = value),
);

OrionSegmentedProgress(count: 4, value: 2.5);

OrionSwitch(
  value: enabled,
  onChanged: (value) => setState(() => enabled = value),
);

OrionCheckbox(
  value: remember, // null shows the indeterminate bar
  onChanged: (value) => setState(() => remember = value ?? false),
);

OrionChip(
  label: const Text('Live'),
  selected: filters.contains('live'),
  onSelected: (value) => setState(() =>
      value ? filters.add('live') : filters.remove('live')),
);

OrionNavigationBar(
  destinations: const [
    OrionNavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
    OrionNavigationDestination(icon: Icon(Icons.people_outline), label: 'Contacts'),
  ],
  selectedIndex: index,
  onChanged: (value) => setState(() => index = value),
);

OrionTextField(
  label: 'Name',
  hint: 'Ada Lovelace',
  onChanged: (value) => setState(() => name = value),
);
```

- `OrionButton` owns async in-flight locking, opt-in debounce, loading/disabled states, a 44 pt hit-target floor, and Enter/Space activation.
- `OrionCard` keeps frosted glass in a clipped static layer; interactive cards compress only the foreground content.
- `OrionBadge` applies the ambient `labelSmall` style through `DefaultTextStyle`.
- `OrionSegmentedControl` is a single-select pill track. The selected pill slides on the press spring, arrow keys follow the text direction, and `onChanged: null` mutes the track.
- `OrionSegmentedProgress` fills equal segments from the start. `value` may be fractional, and the fill settles on a critically damped spring.
- `OrionSwitch` slides a thumb on the gentle spring. Enter and Space flip it, and `onChanged: null` disables it.
- `OrionCheckbox` is a tap-only box whose fill, border, and mark ride the gentle spring, sized for the full checked/unchecked travel rather than the shorter press release. `value: null` draws the indeterminate bar and reports `true` on the first tap. It owns no label; compose the row around it. Enter and Space flip it without a haptic, and `onChanged: null` disables it.
- `OrionChip` is a tap-only pill whose fill, hairline, check, and label ride the same gentle travel spring as the checkbox. The parent owns the selection, `onSelected` reports the opposite, and a check marks selection so it is not carried by color alone. Enter and Space flip it without a haptic, and `onSelected: null` disables it.
- `OrionNavigationBar` is a floating surface capsule. The selection pill slides on the press spring. `dragPosition` follows a finger drag, and a jump of more than one destination does not select the tabs in between. `visible: false` fades the bar down by 8 pt.
- `OrionTextField` is a single-line field. The focus ring rides the press spring, and losing focus settles without a second flash. A non-empty `error` replaces the helper and paints `ColorScheme.error`. `enabled: false` mutes the field.


