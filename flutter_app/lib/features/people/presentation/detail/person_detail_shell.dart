import 'package:flutter/material.dart';

import '../hub/people_hub_route.dart';

class PersonDetailShell extends StatelessWidget {
  const PersonDetailShell({
    super.key,
    required this.personId,
    required this.body,
    this.editAction,
  });

  final String personId;
  final Widget body;
  final Widget? editAction;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= peopleHubWideBreakpoint;
    return Column(
      children: [
        if (wide && editAction != null)
          Align(alignment: Alignment.centerRight, child: editAction!),
        Expanded(child: body),
      ],
    );
  }
}
