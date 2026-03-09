import 'package:mockito/mockito.dart';
import 'package:pet_profile_app/features/health_tracking/data/datasources/health_remote_datasource.dart';
import 'package:pet_profile_app/features/health_tracking/data/models/health_entry_model.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';

class MockHealthRemoteDataSource extends Mock
    implements HealthRemoteDataSource {
  static final _fallbackModel = HealthEntryModel(
    id: '',
    petId: '',
    name: '',
    type: HealthEntryType.medication,
    frequency: HealthFrequency.once,
    startDate: DateTime(2025),
    nextDueDate: DateTime(2025),
  );

  @override
  Future<HealthEntryModel> createEntry(HealthEntryModel? entry) =>
      super.noSuchMethod(
        Invocation.method(#createEntry, [entry]),
        returnValue: Future.value(_fallbackModel),
      ) as Future<HealthEntryModel>;

  @override
  Future<HealthEntryModel> updateEntry(HealthEntryModel? entry) =>
      super.noSuchMethod(
        Invocation.method(#updateEntry, [entry]),
        returnValue: Future.value(_fallbackModel),
      ) as Future<HealthEntryModel>;
}
