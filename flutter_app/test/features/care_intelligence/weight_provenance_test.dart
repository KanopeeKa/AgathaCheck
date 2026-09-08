import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_intelligence/domain/weight_provenance.dart';

void main() {
  test('measurement source wire round-trip', () {
    expect(MeasurementSource.guardian.wireValue, 'guardian');
    expect(MeasurementSourceWire.fromWire('clinic'), MeasurementSource.clinic);
    expect(MeasurementSourceWire.fromWire('vet_instruction'), isNull);
  });

  test('management context defaults to none for unknown wire', () {
    expect(ManagementContextWire.fromWire(null), ManagementContext.none);
    expect(ManagementContext.vetManaged.wireValue, 'vet_managed');
  });
}
