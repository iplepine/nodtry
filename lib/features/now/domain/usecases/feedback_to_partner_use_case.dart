import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../repositories/record_repository.dart';
import '../../../../providers/repository_provider.dart';

final feedbackToPartnerUseCaseProvider = Provider<FeedbackToPartnerUseCase>((
  ref,
) {
  final recordRepository = ref.watch(recordRepositoryProvider);
  return FeedbackToPartnerUseCase(recordRepository: recordRepository);
});

class FeedbackToPartnerUseCase {
  final RecordRepository _recordRepository;

  FeedbackToPartnerUseCase({required RecordRepository recordRepository})
    : _recordRepository = recordRepository;

  Future<void> execute({
    required String planId,
    required String reactionType,
    String? message,
  }) async {
    await _recordRepository.cheerPartner(
      planId,
      reactionType,
      message: message,
    );
  }
}
