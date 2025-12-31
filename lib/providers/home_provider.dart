import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/home_state.dart';
import 'repository_provider.dart';

/// 홈 카드 상태 Provider (Now Tab용)
final homeCardStateProvider = FutureProvider<List<HomeCardModel>>((ref) async {
  final useCase = ref.watch(getNowCardsUseCaseProvider);
  return useCase.execute();
});
