import 'package:flutter/material.dart';
import 'package:orion_ui/orion_ui.dart';

/// Orion canvas shared by the component showcases.
///
/// The light/dark toggle swaps [OrionTheme] locally so a page can be reviewed
/// without the host app palette.
class OrionThemedScaffold extends StatefulWidget {
  const OrionThemedScaffold({
    super.key,
    required this.title,
    required this.builder,
  });

  final String title;
  final WidgetBuilder builder;

  @override
  State<OrionThemedScaffold> createState() => _OrionThemedScaffoldState();
}

class _OrionThemedScaffoldState extends State<OrionThemedScaffold> {
  bool _dark = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _dark = Theme.of(context).brightness == Brightness.dark;
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _dark ? OrionTheme.dark() : OrionTheme.light(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              actions: [
                Icon(
                  _dark ? Icons.dark_mode : Icons.light_mode,
                  size: OrionSizing.iconSmall,
                ),
                const SizedBox(width: OrionSpacing.space4),
                OrionSwitch(
                  key: const ValueKey<String>('showcase-theme-toggle'),
                  size: OrionSwitchSize.small,
                  value: _dark,
                  semanticLabel: 'Toggle dark theme',
                  onChanged: (bool value) => setState(() => _dark = value),
                ),
                const SizedBox(width: OrionSpacing.space8),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(OrionSpacing.space16),
              child: widget.builder(context),
            ),
          );
        },
      ),
    );
  }
}

/// A titled block of a showcase page.
class OrionShowcaseSection extends StatelessWidget {
  const OrionShowcaseSection({
    super.key,
    required this.title,
    this.subtitle,
    this.card = false,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final bool card;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 12.5,
              color: scheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],
      ],
    );

    if (!card) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: OrionSpacing.space12),
            child: header,
          ),
          child,
        ],
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerLow : scheme.surface,
        borderRadius: BorderRadius.circular(OrionRadii.radius12),
        border: Border.all(
          color: isDark
              ? scheme.outlineVariant.withValues(alpha: 0.15)
              : scheme.outlineVariant.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(OrionSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: OrionSpacing.space16),
          child,
        ],
      ),
    );
  }
}
