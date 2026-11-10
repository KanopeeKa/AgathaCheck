import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/sharing/presentation/sharing_error_messages.dart';
import 'package:pet_profile_app/l10n/app_localizations_en.dart';

void main() {
  final l = AppLocalizationsEn();

  test('sharingMutationErrorMessage hides raw exception text', () {
    final raw = Exception('Failed to send invitation');
    final msg = sharingMutationErrorMessage(l, raw);
    expect(msg, isNot(contains('Exception')));
    expect(msg, isNot(contains('Failed to send')));
    expect(msg, l.shareUpdateFailed);
  });

  test('sharingMutationErrorMessage maps auth failures to session copy', () {
    final msg = sharingMutationErrorMessage(l, Exception('Not authenticated'));
    expect(msg, l.shareSessionExpired);
  });
}
