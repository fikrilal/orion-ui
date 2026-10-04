# Orion UI

Tactile, physics-driven design engineering component kit for Flutter.

## Core Philosophy

- **One Spring, Retargeted:** Single continuous `SpringSimulation` without position snapping or velocity truncation.
- **Scroll-First Gesture Cooperation:** Passive pointer monitoring that allows parent `Scrollable` views to win the gesture arena without lag.
- **Rebuild Isolation:** Ticker frame updates only alter the `Transform.scale` matrix around pre-built child subtrees.
- **Decoupled Architecture:** Pure Flutter SDK dependencies only.
