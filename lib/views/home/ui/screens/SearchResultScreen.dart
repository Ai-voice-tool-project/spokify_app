import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/helpers/ipconfig.dart';
import '../../../../core/helpers/searchKnowledgeBase.dart';

class AskQuestionPage extends StatefulWidget {
  const AskQuestionPage({Key? key}) : super(key: key);

  @override
  _AskQuestionPageState createState() => _AskQuestionPageState();
}

class _AskQuestionPageState extends State<AskQuestionPage> {
  List<String> transcriptions = [];
  bool isLoadingTranscriptions = true;
  String? errorLoadingTranscriptions;

  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>>? _results;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTranscriptions();
  }

  Future<void> _fetchTranscriptions() async {
    setState(() {
      isLoadingTranscriptions = true;
      errorLoadingTranscriptions = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("userId") ?? "";

      final url = Uri.parse("http://$ipAddress:4000/api/transcriptions/user/$userId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data["data"] ?? [];

        transcriptions = items
            .map<String>((item) => item["transcription"] as String? ?? "")
            .where((text) => text.isNotEmpty)
            .toList();

      } else {
        errorLoadingTranscriptions = "Failed to load transcriptions: ${response.statusCode}";
      }
    } catch (e) {
      errorLoadingTranscriptions = "Error: $e";
    }

    setState(() {
      isLoadingTranscriptions = false;
    });
  }

  void _sendQuestion() async {
    final question = _controller.text.trim();
    if (question.isEmpty) {
      setState(() {
        _error = "Please enter a question.";
        _results = null;
      });
      return;
    }

    if (transcriptions.isEmpty) {
      setState(() {
        _error = "No transcriptions available to search.";
        _results = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _results = null;
    });

    try {
      final results = await askEachQuestion(question, transcriptions);
      setState(() {
        _results = results;
      });
    } catch (e) {
      setState(() {
        _error = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingTranscriptions) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorLoadingTranscriptions != null) {
      return Scaffold(
        body: Center(child: Text(errorLoadingTranscriptions!)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Ask a Question")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Your Question",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _sendQuestion,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Ask"),
            ),
            const SizedBox(height: 20),

            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ] else if (_results != null) ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _results!.length,
                itemBuilder: (context, index) {
                  final item = _results![index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Answer ${index + 1}:",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(item["answer"] ?? "No answer."),
                          const SizedBox(height: 10),
                          Text(
                            "Related Text:",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(item["related_paragraphs"] ?? ""),
                        ],
                      ),
                    ),
                  );
                },
              )
            ],
          ],
        ),
      ),
    );
  }
}
