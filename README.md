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

OrionSlider(
  value: volume,
  semanticLabel: 'Volume',
  onChanged: (value) => setState(() => volume = value),
);

OrionSlider(
  value: rating, // reports the nearest half star on release
  min: 0,
  max: 5,
  step: 0.5,
  onChanged: (value) => setState(() => rating = value),
);

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

Restyle in one place, or tune a single call site - only the fields an override names change:

```dart
// One place: register an OrionButtonTheme when the app is themed.
OrionTheme.apply(
  OrionTheme.light(),
  extensions: [
    OrionButtonTheme(
      variantStyles: {
        OrionButtonVariant.solid: OrionButtonStyle.from(backgroundColor: brand),
      },
    ),
  ],
);

// One call site: instance overrides merge over the preset and the theme.
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

- `OrionButton` owns async in-flight locking, opt-in debounce, loading/disabled states, a 44 pt hit-target floor, and Enter/Space activation. Look and feel resolve in three layers - the variant preset, an ambient `OrionButtonTheme`, and the per-instance `OrionButtonStyle` - so an override can retune state colors (`WidgetStateProperty` for pressed, hovered, focused, disabled), metrics, or the press physics (`pressedScale`, springs, both haptics) without restating the rest.
- `OrionCard` keeps frosted glass in a clipped static layer; interactive cards compress only the foreground content. Look and feel resolve in three layers - the `OrionCardPresets` for the frosted or opaque face, an ambient `OrionCardTheme`, and the per-instance `OrionCardStyle` (with `padding` and `radius` kept as shortcuts that win).
- `OrionBadge` is a label, a decorative dot or a counter. Variants map to scheme roles (`neutral`, `primary`, `secondary`, `error`, `outline`), sizes step the padding and type, and count badges use tabular figures with an optional `maxCount` cap (`"99+"`). A count change pops the pill and morphs its width on the kit's springs, instant under reduced motion. Look and feel resolve in three layers - the variant/size preset, an ambient `OrionBadgeTheme`, and the per-instance `OrionBadgeStyle`.
- `OrionSegmentedControl` is a single-select pill track. The selected pill slides on the immediate travel spec, arrow keys follow the text direction, and `onChanged: null` mutes the track. A segment may carry an optional `badge` - short content like a count, shown in a counter chip after the label and muted with the control. Look and feel resolve in three layers - the built-in defaults, an ambient `OrionSegmentedControlTheme`, and the per-instance `OrionSegmentedControlStyle` - with `WidgetStateProperty` resolving the track, pill, labels and badge through the disabled and selected states.
- `OrionSegmentedProgress` fills equal segments from the start. `value` may be fractional, and the fill settles on a critically damped spring. Look and feel resolve in three layers - the shared `OrionProgressStyle` defaults, an ambient `OrionProgressTheme`, and the per-instance `style`.
- `OrionLinearProgress` is the continuous bar: `value` is 0 through 1 and clamped, `bufferedValue` paints the cached layer, and a null `value` reads as indeterminate - a bar that grows out of the leading edge, stretches across the track and sweeps through, the next growing before the previous leaves (Material's linear-indicator rhythm), resting static under reduced motion. It shares the progress contract.
- `OrionSlider` takes a continuous number. The thumb follows the pointer exactly while the finger is down, and the spring only settles the release: with `step` set the nearest step is reported and the thumb glides onto it (the range's maximum stays reachable whatever the step), without one there is nothing left to settle, and a tap never moves it. The drag claims horizontal gestures only, so a vertical parent list keeps its scrolls, and the whole track takes the drag, not just the thumb. Arrow keys move by `step` or a twentieth of the range, Home and End jump to the bounds, right and left follow the text direction, and `onChanged: null` disables it. `size` (small/medium/large) steps the thumb and the track as real geometry under a constant 44 pt hit target, `semanticFormatter` phrases the spoken value, and focus is a translucent state layer under the thumb, not a ring. Look and feel resolve in three layers - the built-in `OrionSliderStyle` presets, an ambient `OrionSliderTheme`, and the per-instance `style`.
- `OrionSwitch` slides a thumb on the gentle spring, widening and squashing it under a finger. Enter and Space flip it, and `onChanged: null` disables it. Look and feel resolve in three layers - the built-in `OrionSwitchStyle` defaults (state-resolved track and thumb colours, track geometry, the press deformation, both springs, the haptic), an ambient `OrionSwitchTheme`, and the per-instance `style`.
- `OrionCheckbox` is a tap-only box whose fill, border, and mark ride the gentle travel spring, sized for the full checked/unchecked travel rather than the shorter press release. `value: null` draws the indeterminate bar and reports `true` on the first tap. `size` (small/medium/large) steps the box, its radius, the mark and the bar as real geometry under a constant 44 pt hit target, and `error` paints the form's error role without validating anything. Focus is a translucent overlay under the box, not a second border. It owns no label; compose the row around it. Enter and Space flip it without a haptic, and `onChanged: null` disables it. Look and feel resolve in three layers - the size presets, an ambient `OrionCheckboxTheme`, and the per-instance `OrionCheckboxStyle`.
- `OrionChip` is a tap-only pill whose fill, hairline, check, and label ride the same gentle travel spring as the checkbox. The parent owns the selection, `onSelected` reports the opposite, and a check marks selection so it is not carried by color alone. `size` (small/medium/large) steps the pill, its padding, the check and the gap as real geometry under a constant 44 pt hit target, and focus is a translucent layer over the pill's surface, not a second edge. Enter and Space flip it without a haptic, and `onSelected: null` disables it. Look and feel resolve in three layers - the size presets, an ambient `OrionChipTheme`, and the per-instance `OrionChipStyle`.
- `OrionRadio` is a tap-only circle whose dot rides the same gentle travel spring as the checkbox mark. It never reports `false`, because a radio cannot be switched off by activating it, and its interior stays transparent by default - `fillColor` is the opt-in - so the ring-plus-dot and the filled box stay distinguishable in one row. `size` (small/medium/large) steps the circle and the dot as real geometry under a constant 44 pt hit target, `error` paints the form's error role, and focus is a translucent overlay under the circle, not a second ring. The parent owns the group; each circle exposes its checked state and the exclusive-group flag to semantics. It owns no label, so compose the row around it. Enter and Space select it without a haptic, and `onChanged: null` disables it. Look and feel resolve in three layers - the size presets, an ambient `OrionRadioTheme`, and the per-instance `OrionRadioStyle`.
- `OrionWheelPicker` rolls a column of options under the finger and settles exactly on a detent: a flick carries two or three items, a slow release lands on the nearer one. Crossing a detent emits a single selection click while rolling, and keyboard and tap moves stay silent. Arrow keys move one item and Home and End jump to the bounds. The wheel claims every vertical drag that starts on it, so give it a bounded, non-scrolling surface and a bounded width. Look and feel resolve in three layers - the built-in `OrionWheelPickerPresets` (the two label colours, the row text style, the extent, the edge scale, the flick projection and end resistance, the focus ring, the settle spring), an ambient `OrionWheelPickerTheme`, and the per-instance `OrionWheelPickerStyle`.
- `OrionAccordion` is a controlled disclosure row: the parent owns `expanded`, and there is no group widget. One spring holds the 0 to 1 reveal, and the panel extent and the chevron rotation read that same sample, so they cannot disagree. The content is laid out at its natural height and only the clipped extent animates, as the stable child of its builder. Collapsed content leaves the semantics tree and the focus order, and Enter and Space toggle it. Header and panel content share aligned horizontal insets, header press feedback is tuned to a calm 0.99 micro-scale, and the style supports optional card surface containment. Look and feel resolve in three layers - the built-in `OrionAccordionPresets` (the header and content padding, the calm pressed scale, the focus ring, the disabled dim, both springs), an ambient `OrionAccordionTheme`, and the per-instance `OrionAccordionStyle`.
- `OrionCounter` is a rolling digit odometer for a non-negative integer. It is a readout: no taps, no callback, no hit target. One spring per slot is seeded on its digit and only ever retargeted, and direction belongs to the change rather than the digit, so a `9` becoming `0` on a growing value travels forward instead of unwinding. Ten rows is exactly one period of the column, so the wrap needs no clamp. `animate: false` and reduced motion render the value immediately. Look and feel resolve in three layers - the built-in `OrionCounterPresets` (the text style, the two roll-deformation numbers, the travel spring), an ambient `OrionCounterTheme`, and the per-instance `OrionCounterStyle`.
- `OrionSwipeActionRow` reveals actions under a horizontal drag: the panes sit behind the content, are clipped by the row, and collapse to nothing until the row is dragged, so a closed row cannot show or take an action whatever its content is. Travel follows the finger across the actions, then stretches every button on that side together. A release of 18 logical pixels or more springs back onto the 74 pt actions, however far the finger went, and a swipe never runs an action by itself. Only horizontal drags are claimed, so a parent list keeps its scrolls, and while the row is open the content stops taking pointers so a tap closes instead of activating. Wrap rows in an `OrionSwipeScope` for one open row at a time and a closing tap on the surrounding surface.
- `OrionNavigationBar` is a floating surface capsule. A destination may carry a `badge` - a count or a mark in a ringed chip at the icon's top-right, scaling in on appearance. `labelMode` picks how labels ride: `all` (the default), `none` (an icon-only bar that hugs its icons - a compact natural width, a shorter fallback height, a larger item inset), or `selected` (the label-on-select pattern: the selected destination expands into a pill that reveals its label while the rest stay icons, the capsule reserving one label's width so it never resizes). The label stays the destination's spoken name in every mode. The selection pill slides on the immediate travel spec. `dragPosition` follows a finger drag, and a jump of more than one destination does not select the tabs in between. `visible: false` fades the bar down by 8 pt, and `onLongPress` reports a destination's long press (silent; menus are the host's). Look and feel resolve in three layers - the built-in `OrionNavigationBarStyle` defaults, an ambient `OrionNavigationTheme`, and the per-instance `style`.
- `OrionTextField` is a single-line field (or a growing multiline one). The hairline carries focus - it steps to the scheme's `primary` and half a point wider on a clamped critically damped spring, and losing focus retreats it without a second flash. `variant` (outline/filled/underline) and `size` step the face, `type` derives the keyboard, action, autocorrect/suggestions, autofill hints and formatters (explicit parameters always win), `prefix`/`suffix` are host slots, a password field carries a reveal toggle, `maxLength` caps the text and shows a counter, `reserveCaption` keeps validation from reflowing the form, `readOnly` + `onTap` make a picker face, and `validator`/`autovalidateMode` run through the field's `FormField`. Look and feel resolve in three layers - the variant/size preset, an ambient `OrionTextFieldTheme`, and the per-instance `OrionTextFieldStyle`.
- `OrionToaster` & `OrionToast` provide a Sonner-style 3D perspective notification stack. Up to 3 visible toasts layer with scale attenuation (1.0 -> 0.93 -> 0.86) and depth offsets, expanding into an unstacked column when held or dragged, spaced by the height each card actually laid out at. Dispatched imperatively via `OrionToast.show`, `.success`, `.error`, `.info`, `.warning`, `.loading`, and `.promise`, supporting in-place update by `id`, interactive action buttons, and automatic timer pausing on touch. A card arrives on the mount spring and always leaves with motion: a swipe rides its own velocity off the nearest edge, and a timer or programmatic dismissal sends the card on the same glide instead of cutting it. A card that is already leaving is committed and takes no pointers. `OrionToastCard` is the card itself, for hosts that want to render one directly - note that a `loading` toast keeps a spinner turning, so a test that waits for the tree to settle should not leave one on screen. Look and feel resolve in three layers - the built-in `OrionToastPresets` (status icons, colors, mount/stack/swipe springs), an ambient `OrionToastTheme`, and the per-instance `OrionToastStyle`.
- `OrionBottomSheet` is a tactile, physics-driven bottom sheet with multi-snap detents, top rubber-band resistance, and nested scroll cooperation. Pulling the pill drag handle always claims the sheet; pulling inner content cooperates seamlessly, moving the sheet when the inner scroll is at top rest ($offset \le 0$). Available both as an imperative modal route (`showOrionBottomSheet`) and as an inline overlay widget (`OrionBottomSheet`). Programmatic control is exposed via `OrionSheetController` (`snapToDetent`, `expand`, `collapse`, `dismiss`). Look and feel resolve in three layers - the built-in `OrionBottomSheetPresets` (handle geometry, corner radius, detent/dismiss springs, rubber-band elasticity), an ambient `OrionBottomSheetTheme`, and the per-instance `OrionBottomSheetStyle`.
- `OrionPopover` & `OrionMenu` provide anchor-aware floating surfaces and contextual dropdown menus. Following Emil Kowalski's Transform-Origin law, panels physically blossom directly out of the trigger's touch point with normalized alignment scaling ($0.88 \to 1.0$) rather than scaling from thin air. Automatic viewport collision avoidance flips vertical orientation (`bottom` $\leftrightarrow$ `top`) and clamps horizontal alignment without clipping screen boundaries. `OrionMenu` pairs the popover with structured `OrionMenuItem` rows (leading icons, title, subtitle, trailing shortcuts/badges, destructive error tints, and dividers), tactile press feedback, and optional Telegram-style cascading slide-in reveals. Also available imperatively via `showOrionMenu`. Look and feel resolve in three layers - the built-in `OrionPopoverPresets`, an ambient `OrionPopoverTheme`, and the per-instance `OrionPopoverStyle`.
- `OrionDialog` is a physics-driven, centered modal surface adhering to Emil Kowalski's Centered Modal Law. The dialog blossoms directly out of screen center with authoritative micro-scale kinematics ($0.94 \to 1.0$) and a subtle $6\text{ pt}$ upward glide ($y = 6 \to 0$) powered by an underdamped spring ($k = 380, \zeta = 0.85$). On dismissal, a critically damped spring ($k = 340, \zeta = 1.0$) returns smoothly to rest with zero rebound. Features static frosted glass blur isolation (`frosted: true`, $70\%$ surface alpha), adaptive action layout (horizontal side-by-side or stacked vertical rows), and turnkey helpers: `showOrionConfirmDialog` (returning `Future<bool>`), `showOrionAlertDialog`, and generic `showOrionDialog<T>`. Look and feel resolve in three layers - the built-in `OrionDialogPresets`, an ambient `OrionDialogTheme`, and the per-instance `OrionDialogStyle`.
- `OrionOtpField` is a physics-driven one-time passcode and PIN field. A single invisible input handles keyboard input, hardware keystrokes, SMS autofill (`one-time-code`), and multi-digit paste without multi-field focus fighting. Each slot tile performs a micro-bounce spring compression ($1.0 \to 1.08 \to 1.0$) on entry with an organic vertical digit entrance glide. Features an organic breathing caret on active slots, delayed secure dot masking (`delayedObscure: true`) for transaction PIN verification, optional slot grouping (e.g. $3 + 3$), and damped sinusoidal error shake physics on invalid entry. Look and feel resolve in three layers - the built-in `OrionOtpPresets`, an ambient `OrionOtpTheme`, and the per-instance `OrionOtpStyle`.
- `OrionTooltip` is a physics-driven micro-contextual tooltip surface. Adheres to Emil Kowalski's transform-origin law, blossoming directly out of the trigger anchor with normalized micro-scaling ($0.94 \to 1.0$) and a $4\text{ pt}$ directional rise driven by an underdamped spring ($k = 480, \zeta = 0.85$). Employs a global warm window engine: once any tooltip has been displayed, sibling tooltips hovered within a $300\text{ ms}$ window open instantly with 0ms delay, making toolbar sweeps fast and responsive. Features an autonomous vector caret beak arrow, static frosted glass isolation (`frosted: true`), non-blocking pass-through overlay with outside dismiss, and WCAG 2.1 AA accessible hover, focus, and Escape key dismissal. Look and feel resolve in three layers - the built-in `OrionTooltipPresets`, an ambient `OrionTooltipTheme`, and the per-instance `OrionTooltipStyle`.


