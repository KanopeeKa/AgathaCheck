import 'package:flutter_riverpod/flutter_riverpod.dart';

class PetListController extends StateNotifier<PetListState> {
  PetListController() : super(PetListState());

  void setOrgFilter(String? orgId) {
    state = state.copyWith(orgFilter: orgId);
  }

  // Add more methods for business logic as needed
}

class PetListState {
  final String? orgFilter;

  PetListState({this.orgFilter});

  PetListState copyWith({String? orgFilter}) {
    return PetListState(
      orgFilter: orgFilter ?? this.orgFilter,
    );
  }
}
