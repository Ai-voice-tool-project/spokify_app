import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gradprj/core/helpers/ipconfig.dart';
import 'package:gradprj/core/helpers/spacing.dart';
import 'package:gradprj/core/theming/my_colors.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/emailService.dart';

class CustomDraggableScrollableSheet extends StatefulWidget {
  final String transcriptionText;
  final VoidCallback? onDelete;
  final String? summaryText;
  final List<String>? tasks;
  final List<String>? topics;
  final String TranscriptionId;
  const CustomDraggableScrollableSheet({
    Key? key,
    required this.transcriptionText,
    this.onDelete,
    this.summaryText,
    this.tasks,
    this.topics, required this.TranscriptionId,
  }) : super(key: key);

  @override
  State<CustomDraggableScrollableSheet> createState() =>
      _CustomDraggableScrollableSheetState();
}

class _CustomDraggableScrollableSheetState
    extends State<CustomDraggableScrollableSheet> {
  bool _isEmailFormVisible = false;
  final ScreenshotController screenshotController = ScreenshotController();
  String? _summaryText;
  bool _isLoadingSummary = false;
  String? _summaryError;
  final TextEditingController _fromEmailController = TextEditingController();
  final TextEditingController _toEmailController = TextEditingController();

  bool _isSending = false;

  @override
  void dispose() {
    _fromEmailController.dispose();
    _toEmailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('userEmail') ?? '';
    setState(() {
      _fromEmailController.text = userEmail;
    });
  }

  void _toggleEmailForm() {
    setState(() {
      _isEmailFormVisible = !_isEmailFormVisible;
    });
  }

  void showImageSizeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2E3244),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Create a shareable image",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _sizeOption(context, 200, 300, "Small", 60, 90),
                  _sizeOption(context, 300, 400, "Medium", 80, 120),
                  _sizeOption(context, 400, 500, "Large", 100, 150),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sizeOption(
      BuildContext context,
      double imgWidth,
      double imgHeight,
      String label,
      double boxWidth,
      double boxHeight,
      ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        createImageFromText(context, imgWidth, imgHeight);
      },
      child: Container(
        width: boxWidth,
        height: boxHeight,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white30),
        ),
        child: Center(
          child: Text(label, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  List<String> splitTextByWords(String text, int maxWordsPerChunk) {
    List<String> words = text.split(' ');
    List<String> chunks = [];

    for (int i = 0; i < words.length; i += maxWordsPerChunk) {
      int end = (i + maxWordsPerChunk < words.length)
          ? i + maxWordsPerChunk
          : words.length;
      chunks.add(words.sublist(i, end).join(' '));
    }

    return chunks;
  }

  void createImageFromText(BuildContext context, double width, double height) async {
    final controller = ScreenshotController();
    const int maxWordsPerImage = 50;

    final chunks = splitTextByWords(widget.transcriptionText, maxWordsPerImage);
    final tempDir = await getTemporaryDirectory();
    List<XFile> imageFiles = [];

    for (int i = 0; i < chunks.length; i++) {
      final chunkText = chunks[i];

      final imageWidget = Screenshot(
        controller: controller,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: const Color(0xFF2E3244),
          ),
          width: width,
          height: height,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      chunkText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      softWrap: true,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  ' ${i + 1}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );

      try {
        final imageBytes = await controller.captureFromWidget(imageWidget);
        final imagePath = '${tempDir.path}/transcription_$i.png';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(imageBytes);
        imageFiles.add(XFile(imagePath));
      } catch (e) {
        print('Error capturing image for chunk $i: $e');
      }
    }

    if (imageFiles.isNotEmpty) {
      await Share.shareXFiles(imageFiles, text: 'Transcription Images');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No images generated')),
      );
    }
  }

  Future<void> _sendEmail() async {
    final String fromEmail = _fromEmailController.text.trim();
    final String toEmail = _toEmailController.text.trim();
    final String message = widget.transcriptionText.trim();

    final emailRegex = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if (fromEmail.isEmpty || !emailRegex.hasMatch(fromEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your valid email address.')),
      );
      return;
    }
    if (toEmail.isEmpty || !emailRegex.hasMatch(toEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid recipient email address.')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    final bool success = await EmailService.sendEmail(
      fromEmail: fromEmail,
      toEmail: toEmail,
      message: message,
    );

    setState(() {
      _isSending = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email sent successfully!')),
      );
      _toEmailController.clear();
      _toggleEmailForm();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send the email. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DraggableScrollableSheet(
          initialChildSize: 0.12,
          minChildSize: 0.12,
          maxChildSize: 0.85,
          builder: (context, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF2E3244),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              child: ListView(
                controller: controller,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.white),
                        onPressed: _toggleEmailForm,
                      ),
                      IconButton(
                          icon: const Icon(Icons.image, color: Colors.white),
                          onPressed: () {
                            showImageSizeSelector(context);
                          }),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: widget.transcriptionText),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Text copied!")),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: widget.onDelete != null
                            ? () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: MyColors.backgroundColor,
                              title: const Text("Confirm Delete", style: TextStyle(color: Colors.white)),
                              content: const Text(
                                "Are you sure you want to delete this transcription?",
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(); // close dialog
                                    widget.onDelete!();          // just call the delete function
                                  },
                                  child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            ),
                          );
                        }
                            : null,

                      )

                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24),
                  verticalSpace(20),
                  verticalSpace(20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          if (widget.transcriptionText.isNotEmpty) {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: MyColors.backgroundColor,
                                title: const Text("Full Transcription",
                                    style: TextStyle(color: Colors.white)),
                                content: SingleChildScrollView(
                                  child: Text(
                                    widget.transcriptionText,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () async {
                                      await Clipboard.setData(ClipboardData(
                                          text: widget.transcriptionText));
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                          content: Text(
                                              "Transcription copied to clipboard")));
                                    },
                                    child: const Text("Copy",
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Close",
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("No transcription available.")),
                            );
                          }
                        },
                        child:
                        const Text("View Transcript", style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 50),
                      OutlinedButton(
                        onPressed: () async {
                          showDialog(
                            context: context,
                            builder: (_) => const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                            barrierDismissible: false,
                          );

                          final url = Uri.parse('http://$ipAddress:4000/api/getTrancriptionById/${widget.TranscriptionId}');
                          try {
                            final response = await http.get(url);
                            Navigator.pop(context); // Close loading spinner

                            if (response.statusCode == 200) {
                              final fullData = json.decode(response.body);
                              final data = fullData['data'];
                              print("FULL DATA: $data");

                              final dynamic tasksField = data['tasks'] ?? data['metadata']?['tasks'];
                              print("TASKS FIELD: $tasksField");

                              List<String> tasksList = [];

                              if (tasksField != null) {
                                if (tasksField is List) {
                                  tasksList = tasksField
                                      .map((e) => e.toString().trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList();
                                } else if (tasksField is String) {
                                  tasksList = tasksField
                                      .split('\n')
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList();
                                }
                              }

                              if (tasksList.isNotEmpty) {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    backgroundColor: MyColors.backgroundColor,
                                    title: const Text("Tasks List", style: TextStyle(color: Colors.white)),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: tasksList.map(
                                              (task) => Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text("• ", style: TextStyle(color: Colors.white, fontSize: 18)),
                                                Expanded(
                                                  child: Text(task, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ).toList(),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () async {
                                          final allTasksText = tasksList.join('\n');
                                          await Clipboard.setData(ClipboardData(text: allTasksText));
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Tasks copied to clipboard")),
                                          );
                                        },
                                        child: const Text("Copy", style: TextStyle(color: Colors.white)),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Close", style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("No tasks available.")),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error fetching tasks: ${response.statusCode}")),
                              );
                            }
                          } catch (e) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }
                        },
                        child: const Text("View Tasks", style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                      ),

                    ],
                  ),
                  verticalSpace(20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      OutlinedButton(
                        onPressed: () async {
                          showDialog(
                            context: context,
                            builder: (_) => const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                            barrierDismissible: false,
                          );

                          final url = Uri.parse('http://$ipAddress:4000/api/getTrancriptionById/${widget.TranscriptionId}');
                          try {
                            final response = await http.get(url);

                            Navigator.pop(context); // إغلاق شاشة الانتظار

                            if (response.statusCode == 200) {
                              // هنا تفك JSON وترى شكل البيانات
                              final data = json.decode(response.body);

                              final dataField = data['data'];
                              print('Data field: $dataField');

                              final metadata = dataField != null ? dataField['metadata'] : null;
                              print('Metadata: $metadata');

                              final summary = metadata != null ? metadata['summary'] : null;
                              print('Summary raw: $summary');

                              final cleanedSummary = summary?.toString().trim() ?? "";

                              if (cleanedSummary.isNotEmpty) {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    backgroundColor: MyColors.backgroundColor,
                                    title: const Text("Summary", style: TextStyle(color: Colors.white)),
                                    content: SingleChildScrollView(
                                      child: SelectableText(
                                        cleanedSummary,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () async {
                                          await Clipboard.setData(ClipboardData(text: cleanedSummary));
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Summary copied to clipboard")),
                                          );
                                        },
                                        child: const Text("Copy", style: TextStyle(color: Colors.white)),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Close", style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("No summary available.")),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error fetching summary: ${response.statusCode}")),
                              );
                            }
                          } catch (e) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }
                        },
                        child: const Text("Show Summary", style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 50),
                      OutlinedButton(
                        onPressed: () async {
                          showDialog(
                            context: context,
                            builder: (_) => const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                            barrierDismissible: false,
                          );

                          final url = Uri.parse('http://$ipAddress:4000/api/getTrancriptionById/${widget.TranscriptionId}');
                          try {
                            final response = await http.get(url);
                            Navigator.pop(context); // Close loading spinner

                            if (response.statusCode == 200) {
                              final fullData = json.decode(response.body);
                              final data = fullData['data'];
                              print("FULL DATA: $data");

                              final dynamic topicsField = data['topics'] ?? data['metadata']?['topics'];
                              print("TOPICS FIELD: $topicsField");

                              List<String> topicsList = [];

                              if (topicsField != null) {
                                if (topicsField is List) {
                                  topicsList = topicsField
                                      .map((e) => e.toString().trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList();
                                } else if (topicsField is String) {
                                  topicsList = topicsField
                                      .split('\n')
                                      .map((e) => e.replaceFirst("*", "").trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList();
                                }
                              }

                              if (topicsList.isNotEmpty) {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    backgroundColor: MyColors.backgroundColor,
                                    title: const Text("Topics List", style: TextStyle(color: Colors.white)),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: topicsList.map(
                                              (topic) => Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text("• ", style: TextStyle(color: Colors.white, fontSize: 18)),
                                                Expanded(
                                                  child: Text(topic, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ).toList(),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () async {
                                          final allTopicsText = topicsList.join('\n');
                                          await Clipboard.setData(ClipboardData(text: allTopicsText));
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Topics copied to clipboard")),
                                          );
                                        },
                                        child: const Text("Copy", style: TextStyle(color: Colors.white)),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Close", style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("No topics available.")),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error fetching topics: ${response.statusCode}")),
                              );
                            }
                          } catch (e) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }
                        },
                        child: const Text("View Topics", style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                      ),


                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
        if (_isEmailFormVisible)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  margin:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E3244),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Send Transcription via Email',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _fromEmailController,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: 'Your Email (from)',
                          hintStyle: TextStyle(color: Colors.white54),
                          fillColor: const Color(0xFF3A3F55),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _toEmailController,
                        decoration: InputDecoration(
                          hintText: 'Recipient Email (to)',
                          hintStyle: TextStyle(color: Colors.white54),
                          fillColor: const Color(0xFF3A3F55),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3A3F55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.transcriptionText,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _toggleEmailForm,
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _isSending ? null : _sendEmail,
                            child: _isSending
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Text('Send'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
