import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plan_model.dart';
import '../providers/repository_provider.dart';

/// 특정 유저의 활성 계획 목록을 제공하는 Provider
final activePlansProvider = StreamProvider.family
    .autoDispose<List<Plan>, String>((ref, userId) {
      final repository = ref.watch(recordRepositoryProvider);
      return repository.getPlansByUserIdStream(userId);
    });

/// 특정 유저의 모든 계획 목록을 제공하는 Provider
final allPlansProvider = StreamProvider.family.autoDispose<List<Plan>, String>((
  ref,
  userId,
) {
  final repository = ref.watch(recordRepositoryProvider);
  return repository.getAllPlansByUserIdStream(userId);
});
