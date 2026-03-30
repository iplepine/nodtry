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

  String get periodString {
    final duration = endDate.difference(startDate).inDays;
    final weeks = (duration / 7).ceil();
    return '$weeks주간';
  }
}
