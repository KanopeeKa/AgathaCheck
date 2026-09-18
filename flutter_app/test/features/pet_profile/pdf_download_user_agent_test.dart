import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/data/services/pdf_download_user_agent.dart';

void main() {
  test('opens PDF in new tab on mobile user agents', () {
    expect(
      shouldOpenPdfInNewBrowserTab(
        'Mozilla/5.0 (Linux; Android 15; Pixel 9) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/150.0.0.0 Mobile Safari/537.36',
      ),
      isTrue,
    );
    expect(
      shouldOpenPdfInNewBrowserTab(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 '
        'Mobile/15E148 Safari/604.1',
      ),
      isTrue,
    );
  });

  test('uses download attribute on desktop user agents', () {
    expect(
      shouldOpenPdfInNewBrowserTab(
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
        'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      ),
      isFalse,
    );
    expect(
      shouldOpenPdfInNewBrowserTab(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
        'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      ),
      isFalse,
    );
  });
}
