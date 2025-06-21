import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/helpers/ipconfig.dart';
import '../../../../core/helpers/searchKnowledgeBase.dart';
import '../../../../core/theming/my_colors.dart';  // استيراد ألوان المشروع

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

      // فلترة النتائج لتجاهل الإجابات التي تدل على عدم وجود محتوى مناسب
      final filteredResults = results.where((item) {
        final answer = (item["answer"] ?? "").toString().toLowerCase().trim();
        if (answer.isEmpty) return false;

        final excludePhrases = [
          "does not contain",
          "no relevant",
          "no answer",
          "not found",
          "no information",
          "no relevant paragraphs",
          "not contain relevant",
          "no results",
          "no relevant content",
          "not available",
          "cannot find",
          "not mentioned"
        ];

        for (final phrase in excludePhrases) {
          if (answer.contains(phrase)) {
            return false;
          }
        }

        return true;
      }).toList();

      setState(() {
        _results = filteredResults;
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
        backgroundColor: MyColors.backgroundColor,
        body: Center(child: CircularProgressIndicator(color: MyColors.button1Color)),
      );
    }

    if (errorLoadingTranscriptions != null) {
      return Scaffold(
        backgroundColor: MyColors.backgroundColor,
        body: Center(
          child: Text(
            errorLoadingTranscriptions!,
            style: TextStyle(color: MyColors.button1Color),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Image.asset("assets/images/arrow.png", width: 35, height: 35),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Ask a Question", style: TextStyle(color: Colors.white)),
        backgroundColor: MyColors.backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Your Question",
                labelStyle: const TextStyle(color: Colors.white70),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: MyColors.button1Color),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: MyColors.button2Color, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.button1Color,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              onPressed: _loading ? null : _sendQuestion,
              child: _loading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
                  : const Text("search", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),

            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: MyColors.button1Color)),
            ] else if (_results != null && _results!.isNotEmpty) ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _results!.length,
                itemBuilder: (context, index) {
                  final item = _results![index];
                  final answer = item["answer"] ?? "";
                  final rawParagraphs = item["related_paragraphs"];
                  final List<String> relatedParagraphs = [];

                  if (rawParagraphs != null && rawParagraphs is String && rawParagraphs.isNotEmpty) {
                    relatedParagraphs.addAll(
                        rawParagraphs.split('\n\n').where((p) => p.trim().isNotEmpty).toList()
                    );
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 6,
                    shadowColor: Colors.black.withOpacity(0.5),
                    color: MyColors.backgroundColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: MyColors.backgroundColor,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  spreadRadius: 1,
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              answer,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            "Related Paragraphs:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14, color: MyColors.button1Color),
                          ),
                          const SizedBox(height: 8),

                          ...relatedParagraphs.map((paragraph) => Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            color: MyColors.backgroundColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                paragraph.trim(),
                                style: const TextStyle(fontSize: 14, color: Colors.white),
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ] else if (_results != null && _results!.isEmpty) ...[
              Center(
                child: Text(
                  "No relevant answers found.",
                  style: TextStyle(color: MyColors.button1Color, fontSize: 16),
                ),
              )
            ],
          ],
        ),
      ),
    );
  }
}
