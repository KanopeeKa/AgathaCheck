import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Composition hook for care-item observation UI keyed by [observationKind] (D-WM-013).
typedef CareItemObservationSectionBuilder =
    Widget? Function(
      BuildContext context, {
      required String petId,
      required String entryId,
      required String observationKind,
    });

final careItemObservationSectionProvider =
    Provider<CareItemObservationSectionBuilder>(
      (ref) =>
          (_, {required petId, required entryId, required observationKind}) =>
              null,
    );
