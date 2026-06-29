import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../health_tracking/domain/entities/health_entry.dart';

class OtherEventsController {
  OtherEventsController(this.ref);

  final WidgetRef ref;

  void onAddEntry(BuildContext context, String petId, {HealthEntryType? type}) {
    final query = type != null ? '?type=${type.name}' : '';
    context.go('/pet/$petId/other/add$query');
  }
}
