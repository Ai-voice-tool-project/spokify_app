import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:gradprj/core/theming/my_colors.dart';
import 'package:gradprj/views/home/ui/widgets/transcription_container.dart';
import 'package:gradprj/views/home/ui/widgets/enhanced_text_container.dart';
import 'package:gradprj/views/home/ui/widgets/summary_container.dart';
import 'package:gradprj/views/home/ui/widgets/topics_list.dart';
import 'package:gradprj/views/home/ui/widgets/tasks_list.dart';
import 'package:gradprj/views/home/ui/widgets/action_buttons_row.dart';

import '../../../../core/helpers/ipconfig.dart';
import '../widgets/add_trallo.dart';

// مفتاح Trello
const String trelloApiKey = "e398b664116ed0be68c419dc0d0807df";

class TextProcessingScreen extends StatefulWidget {
  final String transcription;
  final String audioFilePath;

  const TextProcessingScreen({
    super.key,
    required this.transcription,
    required this.audioFilePath,
  });

  @override
  State<TextProcessingScreen> createState() => _TextProcessingScreenState();
}

class _TextProcessingScreenState extends State<TextProcessingScreen> {
  String enhancedText = '';
  String summaryText = '';
  List<String> detectedTopics = [];
  List<String> extractedTasks = [];

  bool isEnhancing = false;
  bool isSummarizing = false;
  bool isLoadingTopics = false;
  bool isLoadingTasks = false;

  String? enhanceError;
  String? summaryError;
  String? topicsError;
  String? tasksError;
  String? userId;

  bool showTasks = false;
  bool showTopics = false;
  bool showSsummarization = false;

  bool get isAnyLoading =>
      isEnhancing || isSummarizing || isLoadingTopics || isLoadingTasks;

  @override
  void initState() {
    super.initState();
    loadUserId();
  }

  Future<void> saveTranscriptionToApi() async {
    if (userId == null ||
        userId!.isEmpty ||
        widget.transcription.isEmpty ||
        widget.audioFilePath.isEmpty ||
        !File(widget.audioFilePath).existsSync()) {
      print("⚠️ Missing required data for saving");
      return;
    }

    try {
      FormData formData = FormData.fromMap({
        "transcription": widget.transcription,
        "enhanced": enhancedText,
        "summary": summaryText,
        "tasks": extractedTasks.join('\n'),
        "topics": detectedTopics.join('\n'),
        "User": userId,
        "audio": await MultipartFile.fromFile(
          widget.audioFilePath,
          filename: widget.audioFilePath.split(Platform.pathSeparator).last,
          contentType: MediaType('audio', 'mpeg'),
        ),
      });

      final response = await Dio().post(
        "http://$ipAddress:4000/api/transcriptions",
        data: formData,
        options: Options(contentType: "multipart/form-data"),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Saved successfully!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save: ${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error saving transcription: $e')));
    }
  }

  Future<void> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('userId');
    print("📦 Loaded userId: $id");

    setState(() {
      userId = id;
    });

    if (id != null) {
      fetchEnhancedText();
    }
  }

  Future<void> fetchEnhancedText() async {
    setState(() {
      isEnhancing = true;
      enhanceError = null;
    });

    try {
      final response = await Dio().post(
        'http://$ipAddress:8000/enhance_text/',
        data: {'text': widget.transcription},
      );

      if (response.statusCode == 200) {
        setState(() => enhancedText = response.data['enhanced_text'] ?? '');
      } else {
        setState(() {
          enhanceError = "Failed to enhance text.";
        });
      }
    } catch (e) {
      setState(() {
        enhanceError = "Enhance Error: $e";
      });
    } finally {
      setState(() => isEnhancing = false);
    }
  }

  Future<void> fetchSummary() async {
    setState(() {
      isSummarizing = true;
      summaryError = null;
    });

    try {
      final response = await Dio().get(
        'http://$ipAddress:8000/summarize/',
      );

      if (response.statusCode == 200) {
        setState(() => summaryText = response.data['summary']);
      } else {
        setState(() {
          summaryError = "Failed to summarize.";
        });
      }
    } catch (e) {
      setState(() {
        summaryError = "Summary Error: $e";
      });
    } finally {
      setState(() => isSummarizing = false);
    }
  }

  Future<void> fetchTopics() async {
    setState(() {
      isLoadingTopics = true;
      topicsError = null;
      detectedTopics.clear();
    });

    try {
      final response = await Dio().get(
        'http://$ipAddress:8000/detect_topics/',
      );

      final rawTopics = response.data['topics'];

      if (rawTopics is String) {
        detectedTopics = rawTopics
            .split('\n')
            .where((t) => t.trim().isNotEmpty)
            .toList();
      } else if (rawTopics is List) {
        detectedTopics = List<String>.from(rawTopics);
      } else {
        setState(() {
          topicsError = "Invalid topics format.";
        });
      }
    } catch (e) {
      setState(() {
        topicsError = "Topics Error: $e";
      });
    } finally {
      setState(() => isLoadingTopics = false);
    }
  }

  Future<void> fetchTasks() async {
    setState(() {
      isLoadingTasks = true;
      tasksError = null;
      extractedTasks.clear();
    });

    try {
      final response = await Dio().get(
        'http://$ipAddress:8000/extract_tasks/',
      );

      extractedTasks = (response.data['tasks'] as String)
          .split('\n')
          .where((task) => task.trim().isNotEmpty)
          .toList();
    } catch (e) {
      setState(() {
        tasksError = "Tasks Error: $e";
      });
    } finally {
      setState(() => isLoadingTasks = false);
    }
  }

  Future<void> checkTokenAndShowTrelloDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('trello_token');

    if (token == null || token.isEmpty) {
      final newToken = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => TrelloTokenScreen()),
      );

      if (newToken == null || newToken.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must provide Trello token to continue.')),
        );
        return;
      }

      await prefs.setString('trello_token', newToken);
    }

    showTrelloInputDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: MyColors.backgroundColor,
          appBar: AppBar(
            backgroundColor: MyColors.backgroundColor,
            leading: IconButton(
              icon: Image.asset("assets/images/arrow.png", width: 35, height: 35),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.save, color: Colors.white),
                tooltip: 'Save Record',
                onPressed: saveTranscriptionToApi,
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranscriptionContainer(transcription: widget.transcription),
                  const SizedBox(height: 30),

                  // Enhanced text with loading indicator
                  isEnhancing
                      ? const Center(child: CircularProgressIndicator())
                      : EnhancedTextContainer(
                    enhancedText: enhancedText,
                    isEnhancing: isEnhancing,
                    enhanceError: enhanceError,
                  ),

                  const SizedBox(height: 30),

                  // Action buttons row
                  ActionButtonsRow(
                    onFetchTasks: () async {
                      await fetchTasks();
                      setState(() => showTasks = !showTasks);
                    },
                    onFetchSummary: () async {
                      await fetchSummary();
                      setState(() => showSsummarization = !showSsummarization);
                    },
                    onFetchTopics: () async {
                      await fetchTopics();
                      setState(() => showTopics = !showTopics);
                    },
                    onTrelloPressed: () => checkTokenAndShowTrelloDialog(context),
                  ),

                  const SizedBox(height: 30),

                  // Summary section with loading indicator
                  if (showSsummarization)
                    isSummarizing
                        ? const Center(child: CircularProgressIndicator())
                        : SummaryContainer(
                      summaryText: summaryText,
                      isSummarizing: isSummarizing,
                      summaryError: summaryError,
                    ),

                  // Topics section with loading indicator
                  if (showTopics)
                    isLoadingTopics
                        ? const Center(child: CircularProgressIndicator())
                        : TopicsList(topics: detectedTopics),

                  // Tasks section with loading indicator
                  if (showTasks)
                    isLoadingTasks
                        ? const Center(child: CircularProgressIndicator())
                        : TasksList(tasks: extractedTasks),
                ],
              ),
            ),
          ),
        ),

        // Overlay loading indicator when any loading
        if (isAnyLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}

/// صفحة WebView لجلب توكن Trello
class TrelloTokenScreen extends StatefulWidget {
  @override
  _TrelloTokenScreenState createState() => _TrelloTokenScreenState();
}

class _TrelloTokenScreenState extends State<TrelloTokenScreen> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (url.contains('token=')) {
              final uri = Uri.parse(url);
              final token = uri.fragment.split('token=').last;
              Navigator.pop(context, token);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(
          'https://trello.com/1/authorize?expiration=never&name=SpokifyApp&scope=read,write&response_type=token&key=$trelloApiKey'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authorize Trello'),
        backgroundColor: Colors.black87,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
