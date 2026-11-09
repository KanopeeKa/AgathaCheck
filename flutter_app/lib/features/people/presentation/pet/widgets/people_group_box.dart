import 'package:flutter/material.dart';

import '../../../../../core/widgets/surface_module.dart';

class PeopleGroupSection {
  const PeopleGroupSection({
    required this.heading,
    required this.rows,
    this.headingSemanticsLabel,
  });

  final String heading;
  final String? headingSemanticsLabel;
  final List<Widget> rows;
}

/// White bordered box with uppercase group headings (D-040).
class PeopleGroupBox extends StatelessWidget {
  const PeopleGroupBox({super.key, required this.sections, this.footer});

  final List<PeopleGroupSection> sections;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = <Widget>[];

    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      if (i > 0) {
        children.add(const SizedBox(height: 12));
        children.add(const Divider(height: 1, thickness: 1));
        children.add(const SizedBox(height: 12));
      }

      children.add(
        Semantics(
          header: true,
          label: section.headingSemanticsLabel ?? section.heading,
          child: Text(
            section.heading.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08 * 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
      children.add(const SizedBox(height: 4));
      children.addAll(section.rows);
    }

    if (footer != null) {
      children.add(const SizedBox(height: 8));
      children.add(footer!);
    }

    return SurfaceModule(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
