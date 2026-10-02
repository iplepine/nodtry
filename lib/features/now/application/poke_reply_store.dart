import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../providers/repository_provider.dart';

/// Remembers which knocks I already answered today (per plan), so the
/// one-tap replies don't come back after a restart. Kept on the device: the
/// reply itself lives only in `cheers`, which the app never reads back.
class PokeReplyStore {
  PokeReplyStore([this._prefs]);

  /// String list of '{planId}@{yyyy-mm-dd}'.
  static const prefKey = 'poke.replied_v1';

  final SharedPreferences? _prefs;
  final Set<String> _memory = {};

  static String _key(String planId, DateTime day) =>
      '$planId@${day.year}-${day.month}-${day.day}';

  bool hasReplied(String planId, DateTime day) {
    final key = _key(planId, day);
    return _memory.contains(key) ||
        (_prefs?.getStringList(prefKey)?.contains(key) ?? false);
  }

  /// Records the reply; entries from other days are dropped.
  Future<void> markReplied(String planId, DateTime day) async {
    final key = _key(planId, day);
    _memory.add(key);
    final prefs = _prefs;
    if (prefs == null) return;
    final suffix = '@${day.year}-${day.month}-${day.day}';
    final kept = (prefs.getStringList(prefKey) ?? const [])
        .where((k) => k.endsWith(suffix) && k != key)
        .toList();
    await prefs.setStringList(prefKey, [...kept, key]);
  }
}

final pokeReplyStoreProvider = Provider<PokeReplyStore>((ref) {
  try {
    return PokeReplyStore(ref.watch(sharedPreferencesProvider));
  } catch (_) {
    return PokeReplyStore(); // no SharedPreferences (tests): memory only
  }
});
