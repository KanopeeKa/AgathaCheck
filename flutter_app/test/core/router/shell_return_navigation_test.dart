import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/router/shell_return_navigation.dart';

void main() {
  group('parseShellReturnTo', () {
    test('accepts encoded in-app paths', () {
      expect(parseShellReturnTo(Uri.encodeComponent('/g/pets')), '/g/pets');
    });

    test('rejects external URLs', () {
      expect(parseShellReturnTo('https://evil.test'), isNull);
    });

    test('rejects protocol-relative paths', () {
      expect(parseShellReturnTo('//evil.test'), isNull);
    });

    test('rejects empty and whitespace', () {
      expect(parseShellReturnTo(null), isNull);
      expect(parseShellReturnTo(''), isNull);
      expect(parseShellReturnTo('   '), isNull);
    });
  });

  group('petDetailLocation', () {
    test('omits query when returnTo absent', () {
      expect(petDetailLocation('abc'), '/pet/abc');
    });

    test('encodes returnTo query', () {
      expect(
        petDetailLocation('abc', returnTo: '/g/pets'),
        '/pet/abc?returnTo=%2Fg%2Fpets',
      );
    });
  });

  group('petEventViewLocation', () {
    test('omits query when returnTo absent', () {
      expect(petEventViewLocation('pet-1', 'entry-1'), '/pet/pet-1/events/entry-1');
    });

    test('encodes returnTo query', () {
      expect(
        petEventViewLocation(
          'pet-1',
          'entry-1',
          returnTo: '/pc/away/abs-1',
        ),
        '/pet/pet-1/events/entry-1?returnTo=%2Fpc%2Faway%2Fabs-1',
      );
    });
  });

  group('shellFallbackReturnPath', () {
    test('prefers explicit backPath', () {
      expect(
        shellFallbackReturnPath(
          explicitBackPath: '/explicit',
          returnTo: '/g/pets',
          defaultPath: '/g/home',
        ),
        '/explicit',
      );
    });

    test('uses returnTo when backPath absent', () {
      expect(
        shellFallbackReturnPath(returnTo: '/g/pets', defaultPath: '/g/home'),
        '/g/pets',
      );
    });

    test('falls back to defaultPath', () {
      expect(shellFallbackReturnPath(defaultPath: '/g/home'), '/g/home');
    });
  });
}
