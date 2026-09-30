import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/session.dart';

abstract class SessionStore {
  Future<SessionDraft?> readActive();
  Future<void> writeActive(SessionDraft draft);
  Future<void> clearActive();
  Future<List<SessionRecord>> readRecords();
  Future<void> saveRecord(SessionRecord record);
}

class LocalSessionStore implements SessionStore {
  LocalSessionStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  // SharedPreferencesAsync on Web keeps this exact key in localStorage.
  // index.html uses it to defer a PWA reload during a session.
  static const activeKey = 'petit_depart_active_session_v1';
  static const recordsKey = 'petit_depart_session_history_v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<SessionDraft?> readActive() async {
    final value = await _preferences.getString(activeKey);
    return value == null ? null : SessionDraft.fromJsonString(value);
  }

  @override
  Future<void> writeActive(SessionDraft draft) =>
      _preferences.setString(activeKey, draft.toJsonString());

  @override
  Future<void> clearActive() => _preferences.remove(activeKey);

  @override
  Future<List<SessionRecord>> readRecords() async {
    final value = await _preferences.getString(recordsKey);
    if (value == null) return [];
    final raw = jsonDecode(value) as List;
    return raw
        .map((item) => SessionRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveRecord(SessionRecord record) async {
    final records = await readRecords();
    final index = records.indexWhere((saved) => saved.id == record.id);
    if (index < 0) {
      records.add(record);
    } else {
      records[index] = record;
    }
    await _preferences.setString(
      recordsKey,
      jsonEncode(records.map((item) => item.toJson()).toList()),
    );
  }
}
