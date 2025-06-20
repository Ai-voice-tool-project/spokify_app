import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'ipconfig.dart';

Future<List<Map<String, dynamic>>> askEachQuestion(String question, List<String> transcriptions) async {
  final uri = Uri.parse("http://$ipAddress:8000/ask_each/");

  final response = await http.post(
    uri,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "question": question,
      "items": transcriptions, // ✅ نرسل كل الترانسكريبشنات كمصفوفة
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data["results"]);
  } else {
    throw Exception("Failed to get answers: ${response.statusCode}");
  }
}
