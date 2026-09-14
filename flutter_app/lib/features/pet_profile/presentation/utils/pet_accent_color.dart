import 'package:flutter/material.dart';

import '../../domain/entities/pet.dart';
import 'ownership_accent.dart';

/// Pet photo/tile accent: org-linked pets use org teal; guardian pets use plum.
Color resolvePetAccentColor(BuildContext context, Pet pet) =>
    resolvePetOwnershipAccentColor(context, pet);
