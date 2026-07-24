import 'package:flutter/material.dart';

import '../../domain/entities/pet.dart';
import 'ownership_accent.dart';

/// Photo ring / accent: org-guardianship pets use org green; guardian pets use plum.
Color resolvePetAccentColor(BuildContext context, Pet pet) =>
    resolvePetOwnershipAccentColor(context, pet);
