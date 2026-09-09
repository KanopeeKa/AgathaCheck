import '../entities/care_pending_moment.dart';

abstract class CareProgressionMomentsRepository {
  Future<CarePendingMomentsResponse> getPendingMoments(String petId);

  Future<void> acknowledgePresented({
    required String petId,
    required String bundleId,
  });
}
