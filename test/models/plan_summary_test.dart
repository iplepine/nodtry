import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/plan_summary.dart';

void main() {
  test('a 28-day plan is four weeks long', () {
    final (:start, :end) = Plan.periodStartingOn(DateTime(2026, 10, 1));
    final summary = PlanSummary(
      planId: 'p',
      title: '헬스장 가기',
      startDate: start,
      endDate: end,
      myCount: 3,
    );

    expect(summary.periodWeeks, 4);
  });

  test('the week label is localized instead of a hardcoded "주간"', () async {
    final ko = await AppLocalizations.delegate.load(const Locale('ko'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));

    expect(ko.planSummaryWeeks(4), '4주간');
    expect(en.planSummaryWeeks(4), '4 weeks');
    expect(en.planSummaryWeeks(1), '1 week');
  });
}
