import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveTrelloToken(String userId, String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('trello_token_$userId', token);
}

Future<String?> getTrelloToken(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('trello_token_$userId');
}
