/// Calm bell badge state (spec §5.4).
class NotificationBellIndicator {
  const NotificationBellIndicator({
    required this.numericCount,
    required this.showDot,
  });

  final int numericCount;
  final bool showDot;

  bool get hasIndicator => numericCount > 0 || showDot;
}
