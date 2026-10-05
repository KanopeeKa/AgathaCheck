class DeleteAccountResult {
  final String message;
  final String? operationId;

  /// `true` when the server returned HTTP 202 (async erasure accepted).
  final bool accepted;

  const DeleteAccountResult({
    required this.message,
    this.operationId,
    required this.accepted,
  });
}
