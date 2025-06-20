import 'package:shared_preferences/shared_preferences.dart';

class TrelloTokenHelper {
  static Future<void> saveTokenForUser(String userId, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('trello_token_\$userId', token);
  }

  static Future<String?> getTokenForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('trello_token_\$userId');
  }

  static Future<void> deleteTokenForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('trello_token_\$userId');
  }

  static Future<bool> hasToken(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('trello_token_\$userId');
  }

  static Future<Map<String, String>> getAllTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final tokens = <String, String>{};

    for (var key in keys) {
      if (key.startsWith('trello_token_')) {
        final value = prefs.getString(key);
        if (value != null) {
          final userId = key.replaceFirst('trello_token_', '');
          tokens[userId] = value;
        }
      }
    }
    return tokens;
  }
}
