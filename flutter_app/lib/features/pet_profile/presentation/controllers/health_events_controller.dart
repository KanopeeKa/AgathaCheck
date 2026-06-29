import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HealthEventsController {
  final WidgetRef ref;
  HealthEventsController(this.ref);

  void onAddEntry(BuildContext context, String petId) {
    context.go('/pet/$petId/health/add');
  }
}
