import 'dart:io';
import '../repositories/user_repository.dart';

class UpdateProfileUseCase {
  final UserRepository _repository;

  UpdateProfileUseCase(this._repository);

  Future<void> execute({
    String? name,
    String? statusMessage,
    File? image,
  }) async {
    // 비즈니스 로직: 유효성 검사 등
    if (name != null && name.isEmpty) {
      throw Exception('Name cannot be empty');
    }

    await _repository.updateProfile(
      name: name,
      statusMessage: statusMessage,
      image: image,
    );
  }
}
