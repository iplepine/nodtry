class PlanSummary {
  final String planId;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final int myCount;
  final int? partnerCount;

  PlanSummary({
    required this.planId,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.myCount,
    this.partnerCount,
  });

  /// Length of the plan in whole weeks, rounded up (28 days → 4).
  int get periodWeeks {
    final duration = endDate.difference(startDate).inDays;
    return (duration / 7).ceil();
  }
}
