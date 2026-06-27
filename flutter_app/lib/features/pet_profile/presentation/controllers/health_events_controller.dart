import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../health_tracking/domain/entities/health_entry.dart';

class HealthEventsController {
  final WidgetRef ref;
  HealthEventsController(this.ref);

  void onAddEntry(
    BuildContext context,
    String petId,
    HealthEntryType? selectedFilter,
  ) {
    final query = selectedFilter != null ? '?type=${selectedFilter.name}' : '';
    final path = '/pet/$petId/health/add$query';
    context.go(path);
  }
}
