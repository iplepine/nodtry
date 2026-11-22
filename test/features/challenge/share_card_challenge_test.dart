import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/challenge/application/challenge_providers.dart';
import 'package:nod_try/features/challenge/presentation/challenge_labels.dart';
import 'package:nod_try/features/duo/application/duo_stats_provider.dart';
import 'package:nod_try/features/duo/presentation/duo_share_card.dart';
import 'package:nod_try/l10n/app_localizations.dart';

ChallengeStatus _status(
  ChallengePhase phase, {
  bool joined = true,
  int day = 7,
}) => ChallengeStatus(
  challenge: kNewYear2027Challenge,
  phase: phase,
  joined: joined,
  hasPartner: true,
  dayNumber: day,
  daysUntilStart: 0,
  daysLeft: 21 - day + 1,
  headlineDays: 4,
);

Future<AppLocalizations> _l10n(WidgetTester tester, String locale) async {
  late AppLocalizations l10n;
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          l10n = AppLocalizations.of(context)!;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return l10n;
}

void main() {
  testWidgets('the label: day N while running, 완주 after, nothing else', (
    tester,
  ) async {
    final ko = await _l10n(tester, 'ko');
    expect(challengeShareLabel(ko, null), isNull);
    expect(
      challengeShareLabel(ko, _status(ChallengePhase.running, joined: false)),
      isNull,
    );
    expect(challengeShareLabel(ko, _status(ChallengePhase.teaser)), isNull);
    expect(
      challengeShareLabel(ko, _status(ChallengePhase.running)),
      '#새해둘운완 7일째',
    );
    expect(
      challengeShareLabel(ko, _status(ChallengePhase.result, day: 21)),
      '#새해둘운완 완주',
    );
    final en = await _l10n(tester, 'en');
    expect(
      challengeShareLabel(en, _status(ChallengePhase.running)),
      '#NewYearDuoDone · day 7',
    );
  });

  testWidgets('the share card carries the challenge frame only when given', (
    tester,
  ) async {
    DuoShareCardData data(String? label) => DuoShareCardData(
      streak: 5,
      date: DateTime(2027, 1, 7),
      meLabel: '나',
      partnerLabel: '자기',
      me: const DuoPersonDay(
        status: DuoDayStatus.done,
        doneWorkoutTypes: ['running'],
      ),
      partner: const DuoPersonDay(
        status: DuoDayStatus.done,
        doneWorkoutTypes: ['gym'],
      ),
      challengeLabel: label,
    );
    Widget app(DuoShareCardData d) => MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: FittedBox(child: DuoShareCard(data: d)),
        ),
      ),
    );

    await tester.pumpWidget(app(data('#새해둘운완 7일째')));
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('share-card-challenge')), findsOneWidget);
    expect(find.text('#새해둘운완 7일째'), findsOneWidget);
    expect(find.text('#둘운완 연속 5일'), findsOneWidget);

    await tester.pumpWidget(app(data(null)));
    expect(find.byKey(const ValueKey('share-card-challenge')), findsNothing);
  });
}
