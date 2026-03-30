import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../health_tracking/domain/entities/health_entry.dart';
import '../../../health_tracking/presentation/providers/health_providers.dart';

class HealthEventsController {
  final WidgetRef ref;
  HealthEventsController(this.ref);

  void onAddEntry(BuildContext context, String petId, HealthEntryType? selectedFilter) {
    if (selectedFilter != null) {
      context.go('/health/add?petId=$petId&type=${selectedFilter.name}');
    } else {
      context.go('/health/add?petId=$petId');
    }
  }
}
