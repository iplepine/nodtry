import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/proof_photo.dart';
import 'package:nod_try/repositories/mock_record_repository.dart';

void main() {
  test(
    'completeOverduePlans completes expired pending approval plans',
    () async {
      final repository = MockRecordRepository();
      final now = DateTime.now();
      final plan = Plan(
        id: 'expired-pending',
        userId: 'me',
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now.subtract(const Duration(days: 1)),
        state: PlanState.pendingApproval,
        items: [
          PlanItem(title: 'Read', days: const [1, 2, 3, 4, 5, 6, 7], count: 1),
        ],
        createdAt: now.subtract(const Duration(days: 7)),
      );

      await repository.createPlan(plan);

      final completedPlanIds = await repository.completeOverduePlans();
      final plans = await repository.getPlansByUserId('me');
      final completedPlan = plans.firstWhere((p) => p.id == 'expired-pending');

      expect(completedPlanIds, contains('expired-pending'));
      expect(completedPlan.state, PlanState.completed);
    },
  );

  test('approvePlan restarts a pending plan on the approval day', () async {
    final repository = MockRecordRepository();
    final longAgo = DateTime.now().subtract(const Duration(days: 9));
    await repository.createPlan(
      Plan(
        id: 'pending',
        userId: 'me',
        startDate: longAgo,
        endDate: longAgo.add(const Duration(days: 27)),
        state: PlanState.pendingApproval,
        items: [
          PlanItem(title: '요가', days: const [1, 3, 5], count: 3),
        ],
        createdAt: longAgo,
      ),
    );

    await repository.approvePlan('pending');

    final approved = (await repository.getPlansByUserId(
      'me',
    )).firstWhere((p) => p.id == 'pending');
    final now = DateTime.now();
    expect(approved.state, PlanState.active);
    expect(approved.startDate, DateTime(now.year, now.month, now.day));
    expect(
      approved.endDate,
      DateTime(now.year, now.month, now.day + 27, 23, 59, 59),
    );
  });

  test('like the real one, a partner\'s plans are the ones I manage', () async {
    final repository = MockRecordRepository();
    final partnerPlans = await repository.getPlansByUserId('partner');
    expect(partnerPlans, isNotEmpty);
    expect(partnerPlans.every((p) => p.managerId == 'me'), isTrue);

    final all = await repository.getAllPlansByUserIdStream('partner').first;
    expect(all.map((p) => p.id), partnerPlans.map((p) => p.id));

    final timeline = await repository
        .getHistoryItemsByPlanIdStream('mock_plan_book', ownerId: 'partner')
        .first;
    expect(timeline.every((i) => i.planId == 'mock_plan_book'), isTrue);
  });

  test('mock cards never encode behaviour in a display string', () async {
    final repository = MockRecordRepository();
    final cards = await repository.getHomeCardStates();
    for (final card in cards) {
      expect(
        card.headerMessage,
        isNot(anyOf('함께하는 중', 'Working together', '조정 중', 'Adjusting')),
      );
    }
  });

  group('proof photos', () {
    final photo = ProofPhotoUpload(
      bytes: Uint8List.fromList(const [9, 8, 7]),
      source: ProofSource.camera,
      takenAt: DateTime(2026, 10, 2, 19, 42),
    );

    test(
      'reportCompletion keeps the photo in memory under the real path',
      () async {
        final repository = MockRecordRepository();

        final result = await repository.reportCompletion(
          'mock_plan_vitamin',
          note: '만 보',
          photo: photo,
        );

        expect(result.hasPhoto, isTrue);
        expect(
          result.photoPath,
          'proofs/me/mock_plan_vitamin/${result.actionId}.jpg',
        );
        expect(
          await repository.downloadProofPhoto(result.photoPath!),
          photo.bytes,
        );
        expect(repository.proofPhotoPaths, [result.photoPath]);

        final item = (await repository.getHistoryItem(result.actionId!))!;
        expect(item.proofPhotoPath, result.photoPath);
        expect(item.proofSource, 'camera');
        expect(item.proofTakenAt, photo.takenAt);
        expect(item.note, '만 보');

        final plan = (await repository.getPlansByUserId(
          'me',
        )).firstWhere((p) => p.id == 'mock_plan_vitamin');
        expect(plan.lastProofPhotoPath, result.photoPath);
        expect(plan.lastActionId, result.actionId);
        expect(todayProofPhotoPathOf(plan), result.photoPath);
      },
    );

    test('without a photo nothing is stored', () async {
      final repository = MockRecordRepository();
      final result = await repository.reportCompletion('mock_plan_vitamin');
      expect(result.hasPhoto, isFalse);
      expect(result.photoFailed, isFalse);
      expect(repository.proofPhotoPaths, isEmpty);
    });

    test('deleteProofPhoto removes the bytes and the fields', () async {
      final repository = MockRecordRepository();
      final result = await repository.reportCompletion(
        'mock_plan_vitamin',
        photo: photo,
      );

      await repository.deleteProofPhoto(result.photoPath!);

      expect(await repository.downloadProofPhoto(result.photoPath!), isNull);
      final item = (await repository.getHistoryItem(result.actionId!))!;
      expect(item.proofPhotoPath, isNull);
      final plan = (await repository.getPlansByUserId(
        'me',
      )).firstWhere((p) => p.id == 'mock_plan_vitamin');
      expect(plan.lastProofPhotoPath, isNull);
    });

    test('a one-tap reaction lands on today\'s record', () async {
      final repository = MockRecordRepository();
      final result = await repository.reportCompletion('mock_plan_vitamin');

      await repository.cheerPartner('mock_plan_vitamin', '❤️');

      final item = (await repository.getHistoryItem(result.actionId!))!;
      expect(item.reaction, '❤️');
      expect(item.isVerifiedByMe, isTrue);
    });

    test('verifyHistoryItem stores the reaction', () async {
      final repository = MockRecordRepository();
      // A partner record not given 인정 yet (mock fixture).
      expect((await repository.getHistoryItem('3'))!.isVerifiedByMe, isFalse);

      await repository.verifyHistoryItem('3', reaction: '👏');

      final item = (await repository.getHistoryItem('3'))!;
      expect(item.isVerifiedByMe, isTrue);
      expect(item.reaction, '👏');
    });
  });
}
