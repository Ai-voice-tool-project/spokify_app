import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';

import 'package:gradprj/core/helpers/app_bar.dart';
import 'package:gradprj/core/helpers/ipconfig.dart';
import 'package:gradprj/core/helpers/spacing.dart';
import 'package:gradprj/core/theming/my_colors.dart';
import 'package:gradprj/core/theming/my_fonts.dart';
import 'package:gradprj/views/home/ui/widgets/custom_gustor_detector.dart';
import 'package:gradprj/views/home/ui/widgets/scrollable_bottom_sheet.dart';

import '../../../../core/helpers/showBlockingLoade.dart';

class note_screen extends StatefulWidget {
  final DateTime? uploadDate;
  final String fullTranscription;

  note_screen({Key? key, this.uploadDate, required this.fullTranscription}) : super(key: key);

  @override
  _note_screenState createState() => _note_screenState();
}

class _note_screenState extends State<note_screen> {
  String title = "Loading...";
  String? transcription;
  String? enhancedText;
  String? summaryText;
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

  String formattedDate = DateFormat('MMM d, y').format(DateTime.now());

  @override
  @override
  void initState() {
    super.initState();
    _loadTitle();
    fetchEnhancedTextFor(widget.fullTranscription);
  }
  Future<void> fetchTasks() async {
    final text = enhancedText ?? widget.fullTranscription;
    if (text.isEmpty) return;

    setState(() {
      isLoadingTasks = true;
      tasksError = null;
    });

    try {
      final response = await Dio().post(
        'http://$ipAddress:8000/extract_tasks_from_text/',
        data: {"text": text},
      );

      if (response.statusCode == 200 && response.data['tasks'] != null) {
        setState(() {
          extractedTasks = List<String>.from(response.data['tasks']);
        });
      } else {
        setState(() {
          tasksError = "Failed to extract tasks.";
        });
      }
    } catch (e) {
      setState(() {
        tasksError = "Tasks Error: $e";
      });
    } finally {
      setState(() {
        isLoadingTasks = false;
      });
    }
  }

  Future<void> fetchTopics() async {
    final text = enhancedText ?? widget.fullTranscription;
    if (text.isEmpty) return;

    setState(() {
      isLoadingTopics = true;
      topicsError = null;
    });

    try {
      final response = await Dio().post(
        'http://$ipAddress:8000/detect_topics/',
        data: {"text": text},
      );

      if (response.statusCode == 200 && response.data['topics'] != null) {
        setState(() {
          detectedTopics = List<String>.from(response.data['topics']);
        });
      } else {
        setState(() {
          topicsError = "Failed to detect topics.";
        });
      }
    } catch (e) {
      setState(() {
        topicsError = "Topics Error: $e";
      });
    } finally {
      setState(() {
        isLoadingTopics = false;
      });
    }
  }
  Future<void> fetchEnhancedTextFor(String text) async {
    setState(() {
      isEnhancing = true;
      enhanceError = null;
    });

    try {
      final response = await Dio().post(
        'http://$ipAddress:8000/enhance_text/',
        data: {"text": text},
      );

      if (response.statusCode == 200) {
        setState(() => enhancedText = response.data['enhanced_text']);
      } else {
        enhanceError = "Failed to enhance text.";
      }
    } catch (e) {
      enhanceError = "Enhance Error: $e";
    } finally {
      setState(() => isEnhancing = false);
    }
  }
  Future<void> fetchSummary() async {
    final text = enhancedText ?? widget.fullTranscription;
    if (text.isEmpty) return;

    showBlockingLoader(context);
    try {
      final response = await Dio().post(
        'http://$ipAddress:8000/summarize/',
        data: {"text": text},
      );
      if (response.statusCode == 200) {
        setState(() => summaryText = response.data['summary']);
      } else {
        summaryError = "Failed to summarize.";
      }
    } catch (e) {
      summaryError = "Summary Error: $e";
    } finally {
      hideBlockingLoader(context);
    }
  }


  Future<void> _loadTitle() async {
    if (widget.fullTranscription.isEmpty) {
      setState(() {
        title = "No transcription text provided";
      });
      return;
    }

    final fetchedTitle = await fetchTitleFromText(widget.fullTranscription);
    if (fetchedTitle != null && fetchedTitle.trim().isNotEmpty) {
      setState(() {
        title = fetchedTitle;
      });
    } else {
      setState(() {
        title = "No Title Found";
      });
    }
  }

  Future<String?> fetchTitleFromText(String text) async {
    final url = Uri.parse('http://$ipAddress:8000/extract_title_from_text/');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"text": text}),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['title'];
      } else {
        print('Server error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Failed to fetch title: $e');
      return null;
    }
  }
  Future<void> fetchEnhancedText() async {
    if (widget.fullTranscription.isEmpty) return;

    setState(() {
      isEnhancing = true;
      enhanceError = null;
    });

    try {
      final url = Uri.parse('http://$ipAddress:8000/enhance_text/');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"text": widget.fullTranscription}),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() => enhancedText = jsonData['enhanced_text']);
      } else {
        setState(() => enhanceError = "Failed to enhance text.");
      }
    } catch (e) {
      setState(() => enhanceError = "Enhance Error: $e");
    } finally {
      setState(() => isEnhancing = false);
    }
  }


  void _editText(String field) {
    TextEditingController controller = TextEditingController(
      text: field == 'title' ? title : enhancedText,
    );

    showDialogEdit(field, controller);
  }

  Future<dynamic> showDialogEdit(String field, TextEditingController controller) {
    return showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: MyColors.backgroundColor,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Edit ${field == 'title' ? 'Title' : 'Content'}",
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  maxLines: field == 'title' ? 2 : 5,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: field == 'title' ? 'Enter title' : 'Enter content',
                    hintStyle: const TextStyle(color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (field == 'title') {
                        title = controller.text;
                      } else {
                        enhancedText = controller.text;
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Save",
                    style: TextStyle(color: MyColors.button1Color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editBoth() {
    TextEditingController titleController = TextEditingController(text: title);
    TextEditingController contentController = TextEditingController(text: enhancedText);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MyColors.backgroundColor,
        title: const Text("Edit Note", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Enter title',
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contentController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Enter content',
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                title = titleController.text;
                enhancedText = contentController.text;
              });
              Navigator.pop(context);
            },
            child: Text(
              "Save",
              style: TextStyle(color: MyColors.button1Color),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBarOfSpokify(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: _editBoth,
                  ),
                  Center(
                    child: Text(
                      widget.uploadDate != null
                          ? DateFormat('MMM d, y – hh:mm a').format(widget.uploadDate!)
                          : "No upload date",
                      style: MyFontStyle.font12RegularBtn.copyWith(color: MyColors.whiteColor),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomGestureDetector(
                    title: title,
                    onTap: () => _editText('title'),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    height: 4,
                    width: 40,
                    color: MyColors.button2Color,
                  ),
                  verticalSpace(10),
                  Text(
                    widget.fullTranscription.isNotEmpty ? widget.fullTranscription : "No transcription available",
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.111),
                ],
              ),
            ),
          ),
          CustomDraggableScrollableSheet(
            transcriptionText: widget.fullTranscription,
            onSummarize: fetchSummary,
            onDetectTopics: fetchTopics,
            summaryText: summaryText,
            tasks: extractedTasks, // ← Add this
            topics: detectedTopics,

// ← Add this too
          )



        ],
      ),
    );
  }
}
