# Orion UI

Tactile, physics-driven design engineering component kit for Flutter.

## Core Philosophy

- **One Spring, Retargeted:** Single continuous `SpringSimulation` without position snapping or velocity truncation.
- **Scroll-First Gesture Cooperation:** Passive pointer monitoring that allows parent `Scrollable` views to win the gesture arena without lag.
- **Rebuild Isolation:** Ticker frame updates only alter the `Transform.scale` matrix around pre-built child subtrees.
- **Decoupled Architecture:** Pure Flutter SDK dependencies only.

## Theme & Tokens

Role colors stay in Material `ColorScheme` and typography in `ThemeData.textTheme`; Orion tokens add what Material cannot express — springs, press scale, haptics, radii, blur, and elevation.

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
```

- `OrionButton` owns async in-flight locking, opt-in debounce, loading/disabled states, a 44 pt hit-target floor, and Enter/Space activation.
- `OrionCard` keeps frosted glass in a clipped static layer; interactive cards compress only the foreground content.
- `OrionBadge` applies the ambient `labelSmall` style through `DefaultTextStyle`.


