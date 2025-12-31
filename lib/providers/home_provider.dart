import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/home_state.dart';
import 'repository_provider.dart';

/// 홈 카드 상태 Provider (Now Tab용)
final homeCardStateProvider = FutureProvider<List<HomeCardModel>>((ref) async {
  final repository = ref.watch(recordRepositoryProvider);

  // Repository가 변경되면(예: Mock <-> Real 전환) 자동으로 재실행됨
  return repository.getHomeCardStates();
});
