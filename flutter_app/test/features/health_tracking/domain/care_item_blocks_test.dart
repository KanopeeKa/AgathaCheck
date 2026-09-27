import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/care_item_blocks.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';

void main() {
  group('CareItemBlocks', () {
    test('filteredFor keeps medication product dose only', () {
      const blocks = CareItemBlocks(
        productDose: const ProductDoseBlock(productName: 'Metacam'),
        visit: const VisitBlock(questionsToAsk: 'Boosters?'),
      );
      final med = blocks.filteredFor(CareFamily.medication);
      expect(med.productDose?.productName, 'Metacam');
      expect(med.visit, isNull);

      final vac = blocks.filteredFor(CareFamily.vaccination);
      expect(vac.visit?.questionsToAsk, 'Boosters?');
      expect(vac.productDose, isNull);
    });

    test('legacyDosageLine joins amount and unit', () {
      const block = ProductDoseBlock(doseAmount: '2', doseUnit: 'ml');
      expect(block.legacyDosageLine(), '2 ml');
    });

    test('toJson omits empty blocks', () {
      expect(const CareItemBlocks().toJson(), isEmpty);
      final json = const CareItemBlocks(
        visit: VisitBlock(questionsToAsk: 'Ask vet'),
      ).toJson();
      expect(json['visit'], {'questions_to_ask': 'Ask vet'});
    });
  });
}
