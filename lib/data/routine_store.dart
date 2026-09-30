import 'package:shared_preferences/shared_preferences.dart';

import '../domain/routine.dart';

abstract class RoutineStore {
  Future<Routine?> read();
  Future<void> write(Routine routine);
}

class LocalRoutineStore implements RoutineStore {
  LocalRoutineStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'petit_depart_routine_v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<Routine?> read() async {
    final value = await _preferences.getString(_key);
    return value == null ? null : Routine.fromJsonString(value);
  }

  @override
  Future<void> write(Routine routine) =>
      _preferences.setString(_key, routine.toJsonString());
}
