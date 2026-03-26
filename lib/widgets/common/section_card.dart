import 'package:flutter/material.dart';

import '../../config/app_constants.dart';

class SectionCard extends StatefulWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final IconData? icon;
  final Color? iconColor;
  final bool collapsible;
  final bool initiallyExpanded;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.icon,
    this.iconColor,
    this.collapsible = false,
    this.initiallyExpanded = true,
  });

  @override
  State<SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<SectionCard>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late final AnimationController _controller;
  late final Animation<double> _sizeFactor;
  late final Animation<double> _iconTurns;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: _expanded ? 1.0 : 0.0,
    );
    _sizeFactor = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _iconTurns = Tween<double>(begin: 0.0, end: 0.5).animate(_sizeFactor);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: widget.collapsible ? _toggle : null,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 20, color: widget.iconColor ?? colorScheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (widget.trailing != null) widget.trailing!,
                  if (widget.collapsible)
                    RotationTransition(
                      turns: _iconTurns,
                      child: Icon(
                        Icons.expand_more,
                        size: 20,
                        color: colorScheme.outline,
                      ),
                    ),
                ],
              ),
            ),
            SizeTransition(
              sizeFactor: _sizeFactor,
              axisAlignment: -1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  widget.child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}