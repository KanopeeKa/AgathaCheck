import '../../../pet_profile/domain/entities/care_family.dart';

/// Item-level category block fields (D-CIE-019).
class CareItemBlocks {
  const CareItemBlocks({this.productDose, this.visit});

  final ProductDoseBlock? productDose;
  final VisitBlock? visit;

  bool get isEmpty =>
      (productDose == null || productDose!.isEmpty) &&
      (visit == null || visit!.isEmpty);

  CareItemBlocks copyWith({
    ProductDoseBlock? productDose,
    VisitBlock? visit,
    bool clearProductDose = false,
    bool clearVisit = false,
  }) {
    return CareItemBlocks(
      productDose: clearProductDose
          ? null
          : (productDose ?? this.productDose),
      visit: clearVisit ? null : (visit ?? this.visit),
    );
  }

  static CareItemBlocks fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const CareItemBlocks();
    return CareItemBlocks(
      productDose: ProductDoseBlock.fromJson(
        json['product_dose'] as Map<String, dynamic>?,
      ),
      visit: VisitBlock.fromJson(json['visit'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() {
    final out = <String, dynamic>{};
    final pd = productDose?.toJson();
    if (pd != null && pd.isNotEmpty) out['product_dose'] = pd;
    final v = visit?.toJson();
    if (v != null && v.isNotEmpty) out['visit'] = v;
    return out;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CareItemBlocks &&
          productDose == other.productDose &&
          visit == other.visit;

  @override
  int get hashCode => Object.hash(productDose, visit);

  /// Blocks allowed for [family] after category change.
  CareItemBlocks filteredFor(CareFamily? family) {
    if (family == null) return const CareItemBlocks();
    switch (family) {
      case CareFamily.medication:
      case CareFamily.parasitePrevention:
      case CareFamily.dental:
        return CareItemBlocks(productDose: productDose);
      case CareFamily.vaccination:
      case CareFamily.wellnessReview:
        return CareItemBlocks(visit: visit);
      case CareFamily.weightMonitoring:
      case CareFamily.grooming:
      case CareFamily.nailCare:
      case CareFamily.other:
        return const CareItemBlocks();
    }
  }
}

class ProductDoseBlock {
  const ProductDoseBlock({
    this.productName = '',
    this.form = '',
    this.strength = '',
    this.doseAmount = '',
    this.doseUnit = '',
    this.routeMethod = '',
  });

  final String productName;
  final String form;
  final String strength;
  final String doseAmount;
  final String doseUnit;
  final String routeMethod;

  bool get isEmpty =>
      productName.trim().isEmpty &&
      form.trim().isEmpty &&
      strength.trim().isEmpty &&
      doseAmount.trim().isEmpty &&
      doseUnit.trim().isEmpty &&
      routeMethod.trim().isEmpty;

  bool get hasAnyValue => !isEmpty;

  ProductDoseBlock copyWith({
    String? productName,
    String? form,
    String? strength,
    String? doseAmount,
    String? doseUnit,
    String? routeMethod,
  }) {
    return ProductDoseBlock(
      productName: productName ?? this.productName,
      form: form ?? this.form,
      strength: strength ?? this.strength,
      doseAmount: doseAmount ?? this.doseAmount,
      doseUnit: doseUnit ?? this.doseUnit,
      routeMethod: routeMethod ?? this.routeMethod,
    );
  }

  static ProductDoseBlock? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final block = ProductDoseBlock(
      productName: json['product_name'] as String? ?? '',
      form: json['form'] as String? ?? '',
      strength: json['strength'] as String? ?? '',
      doseAmount: json['dose_amount'] as String? ?? '',
      doseUnit: json['dose_unit'] as String? ?? '',
      routeMethod: json['route_method'] as String? ?? '',
    );
    return block.isEmpty ? null : block;
  }

  Map<String, dynamic> toJson() {
    final out = <String, dynamic>{};
    void put(String key, String value) {
      final t = value.trim();
      if (t.isNotEmpty) out[key] = t;
    }

    put('product_name', productName);
    put('form', form);
    put('strength', strength);
    put('dose_amount', doseAmount);
    put('dose_unit', doseUnit);
    put('route_method', routeMethod);
    return out;
  }

  String legacyDosageLine() {
    final amount = doseAmount.trim();
    final unit = doseUnit.trim();
    if (amount.isEmpty && unit.isEmpty) return '';
    return [amount, unit].where((s) => s.isNotEmpty).join(' ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductDoseBlock &&
          productName == other.productName &&
          form == other.form &&
          strength == other.strength &&
          doseAmount == other.doseAmount &&
          doseUnit == other.doseUnit &&
          routeMethod == other.routeMethod;

  @override
  int get hashCode => Object.hash(
    productName,
    form,
    strength,
    doseAmount,
    doseUnit,
    routeMethod,
  );
}

class VisitBlock {
  const VisitBlock({this.questionsToAsk = ''});

  final String questionsToAsk;

  bool get isEmpty => questionsToAsk.trim().isEmpty;

  bool get hasAnyValue => !isEmpty;

  VisitBlock copyWith({String? questionsToAsk}) {
    return VisitBlock(questionsToAsk: questionsToAsk ?? this.questionsToAsk);
  }

  static VisitBlock? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final block = VisitBlock(
      questionsToAsk: json['questions_to_ask'] as String? ?? '',
    );
    return block.isEmpty ? null : block;
  }

  Map<String, dynamic> toJson() {
    final q = questionsToAsk.trim();
    if (q.isEmpty) return {};
    return {'questions_to_ask': q};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisitBlock && questionsToAsk == other.questionsToAsk;

  @override
  int get hashCode => questionsToAsk.hashCode;
}
