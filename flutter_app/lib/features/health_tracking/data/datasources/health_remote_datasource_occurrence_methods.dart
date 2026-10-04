part of 'health_remote_datasource.dart';

mixin _HealthRemoteOccurrenceMethods {
  http.Client get _occurrenceHttpClient;
  String get _occurrenceBaseUrl;
  Map<String, String> _occurrenceAuthHeaders({bool jsonBody = false});

  @override
  Future<List<HealthOccurrenceModel>> getOpenOccurrences(String entryId) {
    return fetchOpenOccurrences(
      client: _occurrenceHttpClient,
      baseUrl: _occurrenceBaseUrl,
      headers: _occurrenceAuthHeaders(),
      checkResponse: checkHealthRemoteResponse,
      entryId: entryId,
    );
  }

  @override
  Future<List<HealthOccurrenceModel>> getPastOccurrences(String entryId) {
    return fetchPastOccurrences(
      client: _occurrenceHttpClient,
      baseUrl: _occurrenceBaseUrl,
      headers: _occurrenceAuthHeaders(),
      checkResponse: checkHealthRemoteResponse,
      entryId: entryId,
    );
  }

  @override
  Future<HealthOccurrenceModel> completeOccurrence(
    String entryId,
    String occurrenceId, {
    String notes = '',
    DateTime? completedOn,
    bool skipEarlierMissed = false,
  }) {
    return postCompleteOccurrence(
      client: _occurrenceHttpClient,
      baseUrl: _occurrenceBaseUrl,
      headers: _occurrenceAuthHeaders(jsonBody: true),
      checkResponse: checkHealthRemoteResponse,
      entryId: entryId,
      occurrenceId: occurrenceId,
      notes: notes,
      completedOn: completedOn,
      skipEarlierMissed: skipEarlierMissed,
    );
  }

  @override
  Future<HealthOccurrenceModel> skipOccurrence(
    String entryId,
    String occurrenceId, {
    String notes = '',
  }) {
    return postSkipOccurrence(
      client: _occurrenceHttpClient,
      baseUrl: _occurrenceBaseUrl,
      headers: _occurrenceAuthHeaders(jsonBody: true),
      checkResponse: checkHealthRemoteResponse,
      entryId: entryId,
      occurrenceId: occurrenceId,
      notes: notes,
    );
  }

  @override
  Future<int> skipMissedOccurrences(String entryId) async {
    final open = await fetchOpenOccurrences(
      client: _occurrenceHttpClient,
      baseUrl: _occurrenceBaseUrl,
      headers: _occurrenceAuthHeaders(),
      checkResponse: checkHealthRemoteResponse,
      entryId: entryId,
    );
    final now = DateTime.now();
    final missed = open
        .where((o) => o.status == 'pending' && isOccurrenceMissed(o, now))
        .map((o) => o.id)
        .toList();
    if (missed.isEmpty) return 0;
    final body = await postResolveStack(
      client: _occurrenceHttpClient,
      baseUrl: _occurrenceBaseUrl,
      headers: _occurrenceAuthHeaders(jsonBody: true),
      checkResponse: checkHealthRemoteResponse,
      entryId: entryId,
      given: const [],
      notGiven: missed,
    );
    final notGiven = body['not_given'];
    if (notGiven is List) return notGiven.length;
    return missed.length;
  }

  @override
  Future<HealthOccurrenceModel> undoOccurrence(
    String entryId,
    String occurrenceId,
  ) {
    return postUndoOccurrence(
      client: _occurrenceHttpClient,
      baseUrl: _occurrenceBaseUrl,
      headers: _occurrenceAuthHeaders(jsonBody: true),
      checkResponse: checkHealthRemoteResponse,
      entryId: entryId,
      occurrenceId: occurrenceId,
    );
  }

  @override
  Future<HealthOccurrenceModel> updateOccurrenceNotes(
    String entryId,
    String occurrenceId,
    String notes, {
    String? providerContactId,
    String? providerTypedName,
  }) {
    return patchOccurrenceNotes(
      client: _occurrenceHttpClient,
      baseUrl: _occurrenceBaseUrl,
      headers: _occurrenceAuthHeaders(jsonBody: true),
      checkResponse: checkHealthRemoteResponse,
      entryId: entryId,
      occurrenceId: occurrenceId,
      notes: notes,
      providerContactId: providerContactId,
      providerTypedName: providerTypedName,
    );
  }

  @override
  Future<RescheduleOccurrenceRemoteResult> rescheduleOccurrence(
    String entryId,
    String occurrenceId,
    DateTime scheduledDate, {
    String? reasonCode,
  }) {
    return postRescheduleOccurrence(
      client: _occurrenceHttpClient,
      baseUrl: _occurrenceBaseUrl,
      headers: _occurrenceAuthHeaders(jsonBody: true),
      checkResponse: checkHealthRemoteResponse,
      entryId: entryId,
      occurrenceId: occurrenceId,
      scheduledDate: scheduledDate,
      reasonCode: reasonCode,
    );
  }

  @override
  Future<void> completeWeightOccurrence({
    required String petId,
    required String entryId,
    required String occurrenceId,
    required double weightKg,
    required DateTime date,
    String notes = '',
    String unit = 'kg',
    String measurementSource = 'guardian',
  }) {
    return completeWeightOccurrenceRemote(
      client: _occurrenceHttpClient,
      baseUrl: _occurrenceBaseUrl,
      headers: _occurrenceAuthHeaders(jsonBody: true),
      checkResponse: checkHealthRemoteResponse,
      petId: petId,
      entryId: entryId,
      occurrenceId: occurrenceId,
      weightKg: weightKg,
      date: date,
      notes: notes,
      unit: unit,
      measurementSource: measurementSource,
    );
  }
}
