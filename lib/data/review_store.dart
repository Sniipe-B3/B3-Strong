import 'package:shared_preferences/shared_preferences.dart';

import '../domain/review.dart';

abstract class ReviewStore {
  Future<ReviewSettings> read();
  Future<void> write(ReviewSettings settings);
}

class LocalReviewStore implements ReviewStore {
  LocalReviewStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'petit_depart_review_v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<ReviewSettings> read() async {
    final value = await _preferences.getString(_key);
    return value == null
        ? const ReviewSettings()
        : ReviewSettings.fromJsonString(value);
  }

  @override
  Future<void> write(ReviewSettings settings) =>
      _preferences.setString(_key, settings.toJsonString());
}
