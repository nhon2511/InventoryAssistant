import 'package:flutter/material.dart';

EdgeInsets workspacePadding(BuildContext context) =>
    EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 24);

class WorkspaceContent extends StatelessWidget {
  const WorkspaceContent({
    required this.child,
    this.maxWidth = 1200,
    super.key,
  });
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

class WorkspaceHeader extends StatelessWidget {
  const WorkspaceHeader({
    required this.title,
    required this.description,
    this.actions = const [],
    super.key,
  });
  final String title;
  final String description;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final heading = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
      final buttons = Wrap(spacing: 8, runSpacing: 8, children: actions);
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: constraints.maxWidth < 700
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heading,
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    buttons,
                  ],
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: heading),
                  const SizedBox(width: 16),
                  buttons,
                ],
              ),
      );
    },
  );
}

class WorkspacePanel extends StatelessWidget {
  const WorkspacePanel({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}
