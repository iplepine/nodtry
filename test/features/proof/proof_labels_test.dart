import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/proof/domain/proof_analytics.dart';
import 'package:nod_try/features/proof/domain/proof_labels.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/history_item.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/proof_photo.dart';

Plan _plan({
  String? lastProofPhotoPath,
  DateTime? lastProofAt,
  String? lastActionId,
}) {
  return Plan(
    id: 'plan-1',
    userId: 'u1',
    startDate: DateTime(2026, 9, 28),
    endDate: DateTime(2026, 10, 25),
    state: PlanState.active,
    createdAt: DateTime(2026, 9, 28),
    items: [
      PlanItem(title: '헬스', days: const [5], count: 1),
    ],
    lastProofPhotoPath: lastProofPhotoPath,
    lastProofAt: lastProofAt,
    lastActionId: lastActionId,
  );
}

void main() {
  final now = DateTime(2026, 10, 2, 21, 5);

  group('proofSourceBadgeLabel', () {
    test('[ko] matches the spec copy', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
      expect(
        proofSourceBadgeLabel(
          l10n,
          source: ProofSource.camera,
          takenAt: DateTime(2026, 10, 2, 19, 42),
          now: now,
        ),
        '📸 방금 찍음 · 19:42',
      );
      expect(
        proofSourceBadgeLabel(
          l10n,
          source: ProofSource.gallery,
          takenAt: DateTime(2026, 9, 28, 7, 3),
          now: now,
        ),
        '🖼️ 앨범 · 9/28 촬영',
      );
      expect(
        proofSourceBadgeLabel(l10n, source: ProofSource.gallery, now: now),
        '🖼️ 앨범',
      );
      expect(
        proofSourceBadgeLabel(
          l10n,
          source: ProofSource.camera,
          takenAt: DateTime(2026, 9, 30, 6, 5),
          now: now,
        ),
        '📸 카메라 · 9/30 06:05',
      );
      expect(proofSourceBadgeLabel(l10n, source: null, now: now), isNull);
    });

    test('[en] has a label for every case', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(
        proofSourceBadgeLabel(
          l10n,
          source: ProofSource.camera,
          takenAt: DateTime(2026, 10, 2, 19, 42),
          now: now,
        ),
        '📸 Just taken · 19:42',
      );
      expect(
        proofSourceBadgeLabel(
          l10n,
          source: ProofSource.gallery,
          takenAt: DateTime(2026, 9, 28),
          now: now,
        ),
        '🖼️ Album · taken 9/28',
      );
    });
  });

  test('the report mail draft goes to support with the action id', () {
    final uri = proofReportMailUri(
      actionId: 'abc123',
      subject: '[둘운완] 인증샷 신고',
      body: '기록 ID: abc123',
    );
    expect(uri.scheme, 'mailto');
    expect(uri.path, kSupportEmail);
    expect(uri.toString(), isNot(contains('+')));
    expect(Uri.decodeComponent(uri.query), contains('기록 ID: abc123'));
    expect(Uri.decodeComponent(uri.query), contains('[둘운완] 인증샷 신고'));
  });

  group('analytics', () {
    test('reactionLatencyBucket', () {
      expect(reactionLatencyBucket(null), 'unknown');
      expect(reactionLatencyBucket(const Duration(seconds: -5)), 'unknown');
      expect(reactionLatencyBucket(const Duration(minutes: 2)), 'lt_5m');
      expect(reactionLatencyBucket(const Duration(minutes: 12)), '5m_30m');
      expect(reactionLatencyBucket(const Duration(minutes: 45)), '30m_2h');
      expect(reactionLatencyBucket(const Duration(hours: 3)), '2h_6h');
      expect(reactionLatencyBucket(const Duration(hours: 10)), '6h_24h');
      expect(reactionLatencyBucket(const Duration(days: 2)), 'gt_24h');
    });

    test('partner_reacted carries the latency bucket', () {
      final params = partnerReactedParams(
        reportedAt: now.subtract(const Duration(minutes: 20)),
        surface: 'now',
        reaction: '❤️',
        hasPhoto: true,
        now: now,
      );
      expect(params['latency_bucket'], '5m_30m');
      expect(params['surface'], 'now');
      expect(params['reaction'], '❤️');
      expect(params['has_photo'], true);
    });

    test('proof_uploaded says whether the photo made it and its source', () {
      expect(proofUploadedParams(const ProofCompletionResult(actionId: 'a')), {
        'has_photo': false,
        'source': 'none',
      });
      expect(
        proofUploadedParams(
          const ProofCompletionResult(
            actionId: 'a',
            photoPath: 'proofs/u/p/a.jpg',
            attemptedSource: ProofSource.camera,
          ),
        ),
        {'has_photo': true, 'source': 'camera'},
      );
      expect(
        proofUploadedParams(
          const ProofCompletionResult(
            actionId: 'a',
            attemptedSource: ProofSource.gallery,
          ),
        ),
        {'has_photo': false, 'source': 'gallery'},
      );
    });
  });

  group('proof photo paths', () {
    test('build and parse the Storage path', () {
      final path = proofPhotoPathFor(
        ownerUid: 'u1',
        planId: 'p1',
        actionId: 'a1',
      );
      expect(path, 'proofs/u1/p1/a1.jpg');
      final parts = parseProofPhotoPath(path)!;
      expect(parts.ownerUid, 'u1');
      expect(parts.planId, 'p1');
      expect(parts.actionId, 'a1');
      expect(parseProofPhotoPath('users/u1/profile.jpg'), isNull);
      expect(parseProofPhotoPath('https://example.com/a.jpg'), isNull);
      expect(parseProofPhotoPath(null), isNull);
    });

    test(
      "todayProofPhotoPathOf only returns today's photo of the last record",
      () {
        const path = 'proofs/u1/plan-1/a1.jpg';
        expect(
          todayProofPhotoPathOf(
            _plan(
              lastProofPhotoPath: path,
              lastProofAt: DateTime(2026, 10, 2, 7),
              lastActionId: 'a1',
            ),
            now: now,
          ),
          path,
        );
        // Yesterday's photo.
        expect(
          todayProofPhotoPathOf(
            _plan(
              lastProofPhotoPath: path,
              lastProofAt: DateTime(2026, 10, 1, 22),
              lastActionId: 'a1',
            ),
            now: now,
          ),
          isNull,
        );
        // A later report today without a photo moved lastActionId on.
        expect(
          todayProofPhotoPathOf(
            _plan(
              lastProofPhotoPath: path,
              lastProofAt: DateTime(2026, 10, 2, 7),
              lastActionId: 'a2',
            ),
            now: now,
          ),
          isNull,
        );
        expect(todayProofPhotoPathOf(_plan(), now: now), isNull);
        expect(todayProofPhotoPathOf(null, now: now), isNull);
      },
    );

    test('ProofSource ids are the stored values', () {
      expect(ProofSource.camera.id, 'camera');
      expect(ProofSource.gallery.id, 'gallery');
      expect(ProofSource.fromId('gallery'), ProofSource.gallery);
      expect(ProofSource.fromId('scanner'), isNull);
      expect(ProofSource.fromId(null), isNull);
    });
  });

  group('models', () {
    test('Plan writes proof fields only when set and reads them back', () {
      expect(_plan().toMap().containsKey('lastProofPhotoPath'), isFalse);
      expect(_plan().toMap().containsKey('lastProofAt'), isFalse);

      final at = DateTime(2026, 10, 2, 19, 42);
      final map = _plan(
        lastProofPhotoPath: 'proofs/u1/plan-1/a1.jpg',
        lastProofAt: at,
      ).toMap();
      expect(map['lastProofPhotoPath'], 'proofs/u1/plan-1/a1.jpg');
      expect((map['lastProofAt'] as Timestamp).toDate(), at);

      final parsed = Plan.fromMap(map, 'plan-1');
      expect(parsed.lastProofPhotoPath, 'proofs/u1/plan-1/a1.jpg');
      expect(parsed.lastProofAt, at);
      expect(parsed.asRestartTemplate().lastProofPhotoPath, isNull);
    });

    test('an old plan document without proof fields still parses', () {
      final map = _plan().toMap()..['lastProofPhotoPath'] = '';
      final parsed = Plan.fromMap(map, 'plan-1');
      expect(parsed.lastProofPhotoPath, isNull);
      expect(parsed.lastProofAt, isNull);
    });

    test('HistoryItem reads proof fields and the reaction', () {
      final item = HistoryItem.fromMap({
        'userId': 'u1',
        'planId': 'plan-1',
        'type': 'done',
        'date': Timestamp.fromDate(DateTime(2026, 10, 2, 19)),
        'title': '헬스',
        'proofPhotoPath': 'proofs/u1/plan-1/a1.jpg',
        'proofSource': 'camera',
        'proofTakenAt': Timestamp.fromDate(DateTime(2026, 10, 2, 18, 59)),
        'reaction': '🔥',
      }, 'a1');
      expect(item.proofPhotoPath, 'proofs/u1/plan-1/a1.jpg');
      expect(item.proofSourceType, ProofSource.camera);
      expect(item.proofTakenAt, DateTime(2026, 10, 2, 18, 59));
      expect(item.reaction, '🔥');
      expect(item.copyWith(clearProofPhoto: true).proofPhotoPath, isNull);

      final legacy = HistoryItem.fromMap({
        'userId': 'u1',
        'type': 'done',
        'date': Timestamp.fromDate(DateTime(2026, 10, 2)),
      }, 'old');
      expect(legacy.proofPhotoPath, isNull);
      expect(legacy.reaction, isNull);
    });
  });

  test('the one-tap reactions are the four the old app already renders', () {
    expect(kProofReactions, ['❤️', '🔥', '💪', '👏']);
  });
}
