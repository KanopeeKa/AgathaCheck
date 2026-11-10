import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/router/invite_return.dart';

void main() {
  group('parseInviteReturnTo', () {
    for (final prefix in kInviteRecipientRoutePrefixes) {
      test('accepts $prefix with code', () {
        expect(parseInviteReturnTo('${prefix}abc123'), '${prefix}abc123');
        expect(parseInviteReturnTo(Uri.encodeComponent('${prefix}abc123')),
            '${prefix}abc123');
      });
    }

    test('rejects absolute and protocol-relative URLs', () {
      expect(parseInviteReturnTo('https://evil.com/invite/x'), isNull);
      expect(parseInviteReturnTo('//evil.com/invite/x'), isNull);
    });

    test('rejects backslashes and unknown prefixes', () {
      expect(parseInviteReturnTo(r'\invite\code'), isNull);
      expect(parseInviteReturnTo('/login?redirect=/invite/x'), isNull);
      expect(parseInviteReturnTo('/pet/1'), isNull);
    });

    test('rejects prefix without code and extra path segments', () {
      expect(parseInviteReturnTo('/invite/'), isNull);
      expect(parseInviteReturnTo('/invite/code/extra'), isNull);
    });

    test('rejects over-long targets', () {
      final longCode = 'a' * 200;
      expect(parseInviteReturnTo('/invite/$longCode'), isNull);
      expect(parseInviteReturnTo('/invite/${'x' * 180}'), isNotNull);
    });
  });

  group('isPublicInviteRecipientPath', () {
    test('includes absence-invite prefix', () {
      expect(isPublicInviteRecipientPath('/absence-invite/abc'), isTrue);
    });
  });

  group('appendInviteReturnQuery', () {
    test('appends encoded returnTo when valid', () {
      expect(
        appendInviteReturnQuery('/app/resolve', '/invite/abc'),
        '/app/resolve?returnTo=%2Finvite%2Fabc',
      );
    });

    test('omits query when returnTo invalid', () {
      expect(appendInviteReturnQuery('/app/resolve', '/pc/home'), '/app/resolve');
    });
  });
}
