import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserLocalDataSource {
  final SharedPreferences _prefs;
  static const _keyUser = 'cached_user_profile';

  UserLocalDataSource(this._prefs);

  Future<void> saveUser(UserModel user) async {
    final jsonString = jsonEncode(user.toJson());
    await _prefs.setString(_keyUser, jsonString);
  }

  UserModel? getUser() {
    final jsonString = _prefs.getString(_keyUser);
    if (jsonString != null) {
      try {
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        return UserModel.fromJson(jsonMap);
      } catch (e) {
        // 데이터 손상 시 삭제
        clearUser();
        return null;
      }
    }
    return null;
  }

  Future<void> clearUser() async {
    await _prefs.remove(_keyUser);
  }
}
