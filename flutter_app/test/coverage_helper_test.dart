import 'package:flutter_test/flutter_test.dart';

import 'generated/coverage_helper_imports.dart';

void main() {
  test('coverage helper imports every eligible domain file', () {
    expect(coverageHelperDomainFileCount, greaterThan(100));
  });
}
