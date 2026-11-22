import 'package:flutter/material.dart';
import 'package:orion_ui/orion_ui.dart';

import 'package:orion_ui_example/showcase/orion_showcase_screen.dart';

void main() {
  runApp(const OrionShowcaseApp());
}

class OrionShowcaseApp extends StatefulWidget {
  const OrionShowcaseApp({super.key});

  @override
  State<OrionShowcaseApp> createState() => _OrionShowcaseAppState();
}

class _OrionShowcaseAppState extends State<OrionShowcaseApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orion UI Showcase',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: OrionTheme.light(),
      darkTheme: OrionTheme.dark(),
      home: OrionShowcaseScreen(
        isDark: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}
