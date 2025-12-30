import 'dart:io';
import '../repositories/user_repository.dart';

import '../datasources/user_local_data_source.dart';

class UpdateProfileUseCase {
  final UserRepository _repository;
  final UserLocalDataSource _userLocalDataSource;

  UpdateProfileUseCase(this._repository, this._userLocalDataSource);

  Future<void> execute({
    String? name,
    String? statusMessage,
    File? image,
  }) async {
    // 비즈니스 로직: 유효성 검사 등
    if (name != null && name.isEmpty) {
      throw Exception('Name cannot be empty');
    }

    // 1. 서버 업데이트
    await _repository.updateProfile(
      name: name,
      statusMessage: statusMessage,
      image: image,
    );

    // 2. 최신 데이터 조회 및 캐싱
    // (서버에서 처리된 데이터 - 예를 들어 이미지 URL 등을 확실히 가져오기 위해 조회)
    final updatedUser = await _repository.getMyProfile();
    if (updatedUser != null) {
      await _userLocalDataSource.saveUser(updatedUser);
    }
  }
}
