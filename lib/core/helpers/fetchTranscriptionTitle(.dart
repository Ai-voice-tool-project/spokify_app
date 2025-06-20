import 'dart:convert';
import 'package:http/http.dart' as http;

import 'ipconfig.dart';

Future<String?> fetchTitleFromText(String text) async {
  final url = Uri.parse('http://$ipAddress:8000/extract_title_from_text/');

  try {
    final response = await http
        .post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode({"text": text}),
    )
        .timeout(const Duration(seconds: 15)); // إضافة timeout

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final title = jsonData['title'];
      if (title != null && title is String && title.trim().isNotEmpty) {
        return title;
      } else {
        print('Warning: Title is empty or invalid.');
        return null;
      }
    } else {
      // جرب تفك JSON داخل try-catch لأن الرد ممكن مش JSON
      try {
        final errorData = json.decode(response.body);
        print('Server Error: ${response.statusCode} - ${errorData['detail']}');
      } catch (_) {
        print('Server Error: ${response.statusCode} - Non-JSON response');
      }
      return null;
    }
  } catch (e) {
    print('Failed to fetch title: $e');
    return null;
  }
}
