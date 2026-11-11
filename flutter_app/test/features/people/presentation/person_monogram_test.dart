import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/people/presentation/widgets/person_monogram.dart';

void main() {
  final scheme = AppTheme.lightTheme.colorScheme;

  test(
    'personMonogramStyle never uses light container colors as foreground',
    () {
      final ids = <String>[
        'c1',
        'vet-contact-hs',
        'vet-contact-dm',
        for (var i = 0; i < 32; i++) 'contact-$i',
      ];
      for (final id in ids) {
        final style = personMonogramStyle(id, scheme);
        expect(
          style.foreground,
          isNot(equals(scheme.primaryContainer)),
          reason: 'id=$id',
        );
        expect(
          style.foreground.computeLuminance(),
          lessThan(0.35),
          reason: 'foreground too light for id=$id',
        );
        expect(style.accent, isNot(equals(AppColorTokens.petCareLight)));
      }
    },
  );

  test('personMonogramFromName extracts initials', () {
    expect(personMonogramFromName('Happy Paws Veterinary Surgery'), 'HS');
    expect(personMonogramFromName('Dr. Sarah Mitchell'), 'DM');
  });
}
