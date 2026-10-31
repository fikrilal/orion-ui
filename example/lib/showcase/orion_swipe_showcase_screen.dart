import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

class _InboxMessage {
  const _InboxMessage({
    required this.id,
    required this.sender,
    required this.subject,
    required this.time,
    this.pinned = false,
    this.unread = true,
  });

  final String id;
  final String sender;
  final String subject;
  final String time;
  final bool pinned;
  final bool unread;

  _InboxMessage copyWith({bool? pinned, bool? unread}) {
    return _InboxMessage(
      id: id,
      sender: sender,
      subject: subject,
      time: time,
      pinned: pinned ?? this.pinned,
      unread: unread ?? this.unread,
    );
  }
}

enum _CardStyle { flush, pills }

/// Playground for [OrionSwipeActionRow], [OrionSwipeController],
/// [OrionSwipeStyle], and [OrionSwipeScope].
class OrionSwipeShowcaseScreen extends StatefulWidget {
  const OrionSwipeShowcaseScreen({super.key});

  @override
  State<OrionSwipeShowcaseScreen> createState() =>
      _OrionSwipeShowcaseScreenState();
}

class _OrionSwipeShowcaseScreenState extends State<OrionSwipeShowcaseScreen> {
  static const List<_InboxMessage> _initialMessages = <_InboxMessage>[
    _InboxMessage(
      id: 'm1',
      sender: 'Design Systems',
      subject: 'Swipe physics & full-swipe spec ready',
      time: '9:42 AM',
      pinned: true,
    ),
    _InboxMessage(
      id: 'm2',
      sender: 'Build Bot',
      subject: 'Release candidate #48 passed all checks',
      time: '8:15 AM',
    ),
    _InboxMessage(
      id: 'm3',
      sender: 'Elena Park',
      subject: 'Lunch near the studio today?',
      time: 'Yesterday',
      unread: false,
    ),
  ];

  final OrionSwipeController _controller = OrionSwipeController();

  // Shared flag.
  bool _disabled = false;

  // Live inbox state.
  late List<_InboxMessage> _messages = List<_InboxMessage>.of(_initialMessages);
  String _inboxStatus = 'Swipe right to pin/read • Swipe far left to delete';

  // Floating pill card state.
  bool _muted = false;
  bool _starred = false;

  // Motion demo state.
  OrionSwipeMotion _motion = OrionSwipeMotion.stretch;

  // Controller demo state.
  OrionSwipeSide? _controllerSide;

  // Playground state.
  OrionSwipeMotion _playgroundMotion = OrionSwipeMotion.stretch;
  _CardStyle _playgroundStyle = _CardStyle.pills;
  bool _playgroundFullSwipe = true;
  bool _playgroundLeading = true;
  OrionSwipeSide? _playgroundSide;
  String _playgroundLastAction = 'None yet';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() => _controllerSide = _controller.openSide);
    }
  }

  void _togglePin(String id) {
    setState(() {
      _messages = _messages.map((_InboxMessage m) {
        if (m.id != id) {
          return m;
        }
        final bool next = !m.pinned;
        _inboxStatus = next ? 'Pinned "${m.sender}"' : 'Unpinned "${m.sender}"';
        return m.copyWith(pinned: next);
      }).toList();
    });
  }

  void _toggleUnread(String id) {
    setState(() {
      _messages = _messages.map((_InboxMessage m) {
        if (m.id != id) {
          return m;
        }
        final bool next = !m.unread;
        _inboxStatus = next
            ? 'Marked "${m.sender}" unread'
            : 'Marked "${m.sender}" read';
        return m.copyWith(unread: next);
      }).toList();
    });
  }

  void _removeMessage(String id, String verb) {
    setState(() {
      final _InboxMessage? match = _messages.cast<_InboxMessage?>().firstWhere(
        (_InboxMessage? m) => m?.id == id,
        orElse: () => null,
      );
      _messages = _messages.where((_InboxMessage m) => m.id != id).toList();
      if (match != null) {
        _inboxStatus = '$verb "${match.sender}"';
      }
    });
  }

  void _restoreMessages() {
    setState(() {
      _messages = List<_InboxMessage>.of(_initialMessages);
      _inboxStatus = 'Restored all messages';
    });
  }

  String _motionLabel(OrionSwipeMotion motion) => switch (motion) {
    OrionSwipeMotion.stretch => 'Stretch',
    OrionSwipeMotion.drawer => 'Drawer',
    OrionSwipeMotion.behind => 'Behind',
  };

  String _cardStyleLabel(_CardStyle style) => switch (style) {
    _CardStyle.flush => 'Flush',
    _CardStyle.pills => 'Floating Pills',
  };

  String get _snippet {
    final List<String> lines = <String>['OrionSwipeActionRow('];
    if (_playgroundLeading) {
      lines.addAll(<String>[
        '  leadingFullSwipe: $_playgroundFullSwipe,',
        '  leading: [',
        "    OrionSwipeAction(icon: const Icon(Icons.push_pin_outlined), label: 'Pin', background: Colors.indigo, onPressed: _onPin),",
        '  ],',
      ]);
    }
    lines.addAll(<String>[
      '  trailingFullSwipe: $_playgroundFullSwipe,',
      '  trailing: [',
      "    OrionSwipeAction(icon: const Icon(Icons.archive_outlined), label: 'Archive', background: scheme.secondary, onPressed: _onArchive),",
      "    OrionSwipeAction(icon: const Icon(Icons.delete_outline), label: 'Delete', onPressed: _onDelete),",
      '  ],',
    ]);
    if (_playgroundMotion != OrionSwipeMotion.stretch ||
        _playgroundStyle == _CardStyle.pills) {
      lines.add('  style: OrionSwipeStyle(');
      if (_playgroundMotion != OrionSwipeMotion.stretch) {
        lines.add('    motion: OrionSwipeMotion.${_playgroundMotion.name},');
      }
      if (_playgroundStyle == _CardStyle.pills) {
        lines.add('    actionGap: 8,');
        lines.add('    actionRadius: BorderRadius.circular(12),');
      }
      lines.add('  ),');
    }
    if (_disabled) {
      lines.add('  enabled: false, // disabled');
    }
    lines.add('  child: myRowWidget,');
    lines.add(');');
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return OrionThemedScaffold(
      title: 'Orion Swipe',
      builder: (BuildContext context) {
        return OrionSwipeScope(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Top Intro Header
              Padding(
                padding: const EdgeInsets.only(bottom: OrionSpacing.space20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: OrionSpacing.space8,
                        vertical: OrionSpacing.space4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? scheme.onSurface.withValues(alpha: 0.10)
                            : scheme.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(
                          OrionRadii.radiusPill,
                        ),
                        border: Border.all(
                          color: isDark
                              ? scheme.outlineVariant.withValues(alpha: 0.20)
                              : scheme.outlineVariant.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'GESTURE • FULL-SWIPE & ELASTIC REVEAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: OrionSpacing.space8),
                    Text(
                      'Bidirectional swipe actions with reversible elastic drag, opt-in full-swipe commit morph, zero-bleed rounded cards, floating pill gaps, programmatic controller, and scroll-aware scope.',
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.4,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              OrionShowcaseControls(
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: OrionShowcaseToggle(
                          label: 'Disabled',
                          value: _disabled,
                          onChanged: (bool value) =>
                              setState(() => _disabled = value),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: OrionSpacing.space24),

              // Section 1: Live Inbox (Full-Swipe Commit + Dual Sides + Undo)
              OrionShowcaseSection(
                title: 'Live Inbox — Full Swipe & Scope',
                subtitle:
                    'Pull past ~60% to arm & commit Pin or Delete; pull back to disarm. Scrolls or outside taps close automatically.',
                card: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (_messages.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: OrionSpacing.space16,
                        ),
                        child: Center(
                          child: Column(
                            children: <Widget>[
                              Text(
                                'Inbox zero',
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: OrionSpacing.space8),
                              OrionButton(
                                variant: OrionButtonVariant.bordered,
                                size: OrionButtonSize.small,
                                label: 'Restore messages',
                                onPressed: _restoreMessages,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          OrionRadii.radius12,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: scheme.outlineVariant),
                            borderRadius: BorderRadius.circular(
                              OrionRadii.radius12,
                            ),
                          ),
                          child: Column(
                            children: <Widget>[
                              for (
                                int i = 0;
                                i < _messages.length;
                                i++
                              ) ...<Widget>[
                                OrionSwipeActionRow(
                                  key: ValueKey<String>(_messages[i].id),
                                  enabled: !_disabled,
                                  leadingFullSwipe: true,
                                  trailingFullSwipe: true,
                                  leading: <OrionSwipeAction>[
                                    OrionSwipeAction(
                                      icon: Icon(
                                        _messages[i].pinned
                                            ? Icons.push_pin_rounded
                                            : Icons.push_pin_outlined,
                                      ),
                                      label: _messages[i].pinned
                                          ? 'Unpin'
                                          : 'Pin',
                                      background: const Color(0xFF4F46E5),
                                      onPressed: () =>
                                          _togglePin(_messages[i].id),
                                    ),
                                    OrionSwipeAction(
                                      icon: Icon(
                                        _messages[i].unread
                                            ? Icons.mark_email_read_outlined
                                            : Icons.mark_email_unread_outlined,
                                      ),
                                      label: _messages[i].unread
                                          ? 'Read'
                                          : 'Unread',
                                      background: const Color(0xFF0284C7),
                                      onPressed: () =>
                                          _toggleUnread(_messages[i].id),
                                    ),
                                  ],
                                  trailing: <OrionSwipeAction>[
                                    OrionSwipeAction(
                                      icon: const Icon(Icons.archive_outlined),
                                      label: 'Archive',
                                      background: scheme.secondary,
                                      onPressed: () => _removeMessage(
                                        _messages[i].id,
                                        'Archived',
                                      ),
                                    ),
                                    OrionSwipeAction(
                                      icon: const Icon(Icons.delete_outline),
                                      label: 'Delete',
                                      onPressed: () => _removeMessage(
                                        _messages[i].id,
                                        'Deleted',
                                      ),
                                    ),
                                  ],
                                  child: _InboxRowBody(message: _messages[i]),
                                ),
                                if (i != _messages.length - 1)
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: scheme.outlineVariant,
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: OrionSpacing.space12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _inboxStatus,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (_messages.length < _initialMessages.length)
                          OrionButton(
                            variant: OrionButtonVariant.flat,
                            size: OrionButtonSize.small,
                            label: 'Reset',
                            onPressed: _restoreMessages,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: OrionSpacing.space20),

              // Section 2: Floating Pill Cards + autoClose: false
              OrionShowcaseSection(
                title: 'Floating Pill Cards',
                subtitle:
                    'Zero corner bleed behind rounded cards, floating action pills (actionGap: 8), and autoClose: false Mute toggle',
                card: true,
                child: OrionSwipeActionRow(
                  enabled: !_disabled,
                  style: OrionSwipeStyle(
                    actionGap: OrionSpacing.space8,
                    actionRadius: BorderRadius.circular(OrionRadii.radius12),
                  ),
                  trailing: <OrionSwipeAction>[
                    OrionSwipeAction(
                      icon: Icon(
                        _muted
                            ? Icons.notifications_off_outlined
                            : Icons.notifications_none_rounded,
                      ),
                      label: _muted ? 'Unmute' : 'Mute',
                      background: const Color(0xFFD97706),
                      autoClose: false,
                      onPressed: () => setState(() => _muted = !_muted),
                    ),
                    OrionSwipeAction(
                      icon: Icon(
                        _starred ? Icons.star_rounded : Icons.star_outline,
                      ),
                      label: _starred ? 'Unstar' : 'Star',
                      background: scheme.primary,
                      onPressed: () => setState(() => _starred = !_starred),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: OrionSpacing.space16,
                      vertical: OrionSpacing.space12,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(OrionRadii.radius12),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                'Product updates',
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_muted ? 'Muted' : 'Alerts on'} • ${_starred ? 'Starred' : 'Swipe left for floating pills'}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_starred)
                          Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: scheme.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: OrionSpacing.space20),

              // Section 3: Motion Styles
              OrionShowcaseSection(
                title: 'Motion Styles',
                subtitle:
                    'Compare stretch, drawer, and behind pane choreography',
                card: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    OrionShowcaseChoice<OrionSwipeMotion>(
                      label: 'Motion',
                      values: OrionSwipeMotion.values,
                      selected: _motion,
                      labelOf: _motionLabel,
                      onChanged: (OrionSwipeMotion value) =>
                          setState(() => _motion = value),
                    ),
                    const SizedBox(height: OrionSpacing.space16),
                    OrionSwipeActionRow(
                      enabled: !_disabled,
                      style: OrionSwipeStyle(
                        motion: _motion,
                        borderRadius: BorderRadius.circular(
                          OrionRadii.radius12,
                        ),
                      ),
                      trailing: <OrionSwipeAction>[
                        OrionSwipeAction(
                          icon: const Icon(Icons.share_outlined),
                          label: 'Share',
                          background: const Color(0xFF0284C7),
                          onPressed: () {},
                        ),
                        OrionSwipeAction(
                          icon: const Icon(Icons.delete_outline),
                          label: 'Delete',
                          onPressed: () {},
                        ),
                      ],
                      child: _SimpleRowCard(
                        title: '${_motionLabel(_motion)} reveal',
                        subtitle:
                            'Swipe left slowly to observe ${_motion.name} choreography',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: OrionSpacing.space20),

              // Section 4: Programmatic Controller
              OrionShowcaseSection(
                title: 'Programmatic Controller',
                subtitle:
                    'Drive openLeading(), openTrailing(), and close() via OrionSwipeController',
                card: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    OrionSwipeActionRow(
                      controller: _controller,
                      enabled: !_disabled,
                      style: OrionSwipeStyle(
                        borderRadius: BorderRadius.circular(
                          OrionRadii.radius12,
                        ),
                      ),
                      leading: <OrionSwipeAction>[
                        OrionSwipeAction(
                          icon: const Icon(Icons.push_pin_outlined),
                          label: 'Pin',
                          background: const Color(0xFF4F46E5),
                          onPressed: () {},
                        ),
                      ],
                      trailing: <OrionSwipeAction>[
                        OrionSwipeAction(
                          icon: const Icon(Icons.archive_outlined),
                          label: 'Archive',
                          background: scheme.secondary,
                          onPressed: () {},
                        ),
                        OrionSwipeAction(
                          icon: const Icon(Icons.delete_outline),
                          label: 'Delete',
                          onPressed: () {},
                        ),
                      ],
                      child: _SimpleRowCard(
                        title: 'Controlled row',
                        subtitle: _controllerSide == null
                            ? 'State: closed'
                            : 'State: ${_controllerSide!.name} open',
                      ),
                    ),
                    const SizedBox(height: OrionSpacing.space12),
                    Wrap(
                      spacing: OrionSpacing.space8,
                      runSpacing: OrionSpacing.space8,
                      children: <Widget>[
                        OrionButton(
                          variant: OrionButtonVariant.bordered,
                          size: OrionButtonSize.small,
                          label: 'Open Leading',
                          onPressed: _disabled ? null : _controller.openLeading,
                        ),
                        OrionButton(
                          variant: OrionButtonVariant.bordered,
                          size: OrionButtonSize.small,
                          label: 'Open Trailing',
                          onPressed: _disabled
                              ? null
                              : _controller.openTrailing,
                        ),
                        OrionButton(
                          variant: OrionButtonVariant.flat,
                          size: OrionButtonSize.small,
                          label: 'Close',
                          onPressed: _disabled || _controllerSide == null
                              ? null
                              : _controller.close,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: OrionSpacing.space20),

              // Section 5: Playground
              OrionShowcaseSection(
                title: 'Playground',
                subtitle:
                    'Configure motion, card pill spacing, full-swipe commit, and leading actions',
                child: OrionShowcasePanel(
                  key: const ValueKey<String>('showcase-panel-playground'),
                  preview: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      OrionShowcaseChoice<OrionSwipeMotion>(
                        label: 'Motion',
                        values: OrionSwipeMotion.values,
                        selected: _playgroundMotion,
                        labelOf: _motionLabel,
                        onChanged: (OrionSwipeMotion value) =>
                            setState(() => _playgroundMotion = value),
                      ),
                      const SizedBox(height: OrionSpacing.space12),
                      OrionShowcaseChoice<_CardStyle>(
                        label: 'Style',
                        values: _CardStyle.values,
                        selected: _playgroundStyle,
                        labelOf: _cardStyleLabel,
                        onChanged: (_CardStyle value) =>
                            setState(() => _playgroundStyle = value),
                      ),
                      const SizedBox(height: OrionSpacing.space12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OrionShowcaseToggle(
                              label: 'Full swipe',
                              value: _playgroundFullSwipe,
                              onChanged: (bool value) =>
                                  setState(() => _playgroundFullSwipe = value),
                            ),
                          ),
                          Expanded(
                            child: OrionShowcaseToggle(
                              label: 'Leading',
                              value: _playgroundLeading,
                              onChanged: (bool value) =>
                                  setState(() => _playgroundLeading = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: OrionSpacing.space20),
                      OrionSwipeActionRow(
                        enabled: !_disabled,
                        leadingFullSwipe: _playgroundFullSwipe,
                        trailingFullSwipe: _playgroundFullSwipe,
                        style: OrionSwipeStyle(
                          motion: _playgroundMotion,
                          borderRadius: _playgroundStyle == _CardStyle.flush
                              ? BorderRadius.circular(OrionRadii.radius12)
                              : BorderRadius.zero,
                          actionGap: _playgroundStyle == _CardStyle.pills
                              ? OrionSpacing.space8
                              : 0.0,
                          actionRadius: _playgroundStyle == _CardStyle.pills
                              ? BorderRadius.circular(OrionRadii.radius12)
                              : BorderRadius.zero,
                        ),
                        leading: _playgroundLeading
                            ? <OrionSwipeAction>[
                                OrionSwipeAction(
                                  icon: const Icon(Icons.push_pin_outlined),
                                  label: 'Pin',
                                  background: const Color(0xFF4F46E5),
                                  onPressed: () => setState(
                                    () => _playgroundLastAction = 'Pin',
                                  ),
                                ),
                              ]
                            : const <OrionSwipeAction>[],
                        trailing: <OrionSwipeAction>[
                          OrionSwipeAction(
                            icon: const Icon(Icons.archive_outlined),
                            label: 'Archive',
                            background: scheme.secondary,
                            onPressed: () => setState(
                              () => _playgroundLastAction = 'Archive',
                            ),
                          ),
                          OrionSwipeAction(
                            icon: const Icon(Icons.delete_outline),
                            label: 'Delete',
                            onPressed: () => setState(
                              () => _playgroundLastAction = 'Delete',
                            ),
                          ),
                        ],
                        onSideChanged: (OrionSwipeSide? side) =>
                            setState(() => _playgroundSide = side),
                        child: _SimpleRowCard(
                          title: 'Playground row',
                          subtitle: _playgroundSide == null
                              ? 'Closed • Last action: $_playgroundLastAction'
                              : '${_playgroundSide!.name} open • Last action: $_playgroundLastAction',
                          bordered: _playgroundStyle == _CardStyle.pills,
                        ),
                      ),
                    ],
                  ),
                  code: _snippet,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InboxRowBody extends StatelessWidget {
  const _InboxRowBody({required this.message});

  final _InboxMessage message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return ColoredBox(
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OrionSpacing.space16,
          vertical: OrionSpacing.space12,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsetsDirectional.only(
                end: OrionSpacing.space12,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: message.unread ? scheme.primary : Colors.transparent,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      if (message.pinned) ...<Widget>[
                        Icon(
                          Icons.push_pin_rounded,
                          size: 13,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: OrionSpacing.space4),
                      ],
                      Expanded(
                        child: Text(
                          message.sender,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: message.unread
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        message.time,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleRowCard extends StatelessWidget {
  const _SimpleRowCard({
    required this.title,
    required this.subtitle,
    this.bordered = true,
  });

  final String title;
  final String subtitle;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OrionSpacing.space16,
        vertical: OrionSpacing.space12,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(OrionRadii.radius12),
        border: bordered ? Border.all(color: scheme.outlineVariant) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
