// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/helpers/ipconfig.dart';
import '../../../../core/theming/my_colors.dart';
import '../../../../core/theming/my_fonts.dart';
import '../widgets/action_buttons_row.dart';
import '../widgets/add_trallo.dart';
import '../widgets/enhanced_text_container.dart';
import '../widgets/recording_controls.dart';
import '../widgets/recording_waveform.dart';
import '../widgets/summary_container.dart';
import '../widgets/tasks_list.dart';
import '../widgets/topics_list.dart';
import '../widgets/transcription_container.dart';
import 'TrelloTokenScreen.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with SingleTickerProviderStateMixin {
  late RecorderController recorderController;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  bool isRecording = false;
  bool showEnhancedPage = false;
  bool showSummary = false;
  bool showTopics = false;
  bool showTasks = false;
  bool isEnhancing = false;
  bool isSummarizing = false;
  bool isLoadingTopics = false;
  bool isLoadingTasks = false;

  int recordingSeconds = 0;
  Timer? _timer;
  String? userId;
  String filePath = '';
  String? transcription;
  String? enhancedText;
  String? summaryText;
  List<String> detectedTopics = [];
  List<String> extractedTasks = [];

  String? enhanceError;
  String? summaryError;
  String? topicsError;
  String? tasksError;

  @override
  void initState() {
    super.initState();
    _initUserId();

    recorderController = RecorderController()
      ..updateFrequency = const Duration(milliseconds: 100)
      ..sampleRate = 16000
      ..bitRate = 16000
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4;

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    startRecording();
  }

  Future<void> _initUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedUserId = prefs.getString('userId');
    if (storedUserId == null || storedUserId.isEmpty) {
      storedUserId = '684d864f58651cab5c4cb4d2';
      await prefs.setString('userId', storedUserId);
    }
    setState(() => userId = storedUserId);
  }

  @override
  void dispose() {
    recorderController.dispose();
    _controller.dispose();
    stopTimer();
    super.dispose();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => recordingSeconds++);
    });
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> startRecording() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      filePath = '${dir.path}/recording.m4a';
      await recorderController.record(path: filePath);
      setState(() {
        isRecording = true;
        recordingSeconds = 0;
      });
      startTimer();
    } catch (e) {
      print("❌ Error starting recording: $e");
    }
  }

  Future<void> stopRecording() async {
    try {
      await recorderController.stop();
      stopTimer();
      setState(() => isRecording = false);

      // افتح صفحة تحميل أو انتظار (loading)
      showLoadingDialog();

      // ارفع الملف وخذ النص بدون حظر واجهة المستخدم
      await uploadAudio();

      if (transcription?.isNotEmpty ?? false) {
        await fetchEnhancedText(transcription!);
      }

      // أغلق صفحة التحميل (loading)
      Navigator.pop(context);

      setState(() => showEnhancedPage = true);
      _controller.forward(from: 0);
    } catch (e) {
      print("❌ Error stopping recording: $e");
    }
  }
  void showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          color: MyColors.button1Color,
        ),
      ),
    );
  }


  Future<void> uploadAudio() async {
    if (filePath.isEmpty || !File(filePath).existsSync()) return;

    try {
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          filePath,
          contentType: MediaType('audio', 'mpeg'),
        ),
      });

      final response = await Dio().post(
        "http://$ipAddress:8000/transcribe/",
        data: formData,
        options: Options(headers: {"Content-Type": "multipart/form-data"}),
      );

      setState(() => transcription = response.data["transcription"]);

      // ✅ بعد ما نستلم النص نحدث الكاش في السيرفر
      await Dio().post(
        "http://$ipAddress:8000/cache_transcription/",
        data: {"text": transcription}, // نرسل النص كـ JSON
        options: Options(contentType: Headers.jsonContentType),
      );
    } catch (e) {
      print("❌ Upload error: $e");
    }
  }


  Future<void> fetchEnhancedText(String inputText) async {
    setState(() {
      isEnhancing = true;
      enhanceError = null;
    });

    try {
      final response = await Dio().post(
        'http://$ipAddress:8000/enhance_text/',
        data: {"text": inputText},
        options: Options(contentType: Headers.jsonContentType),
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
    setState(() {
      isSummarizing = true;
      summaryError = null;
    });

    try {
      final response = await Dio().get('http://$ipAddress:8000/summarize/');
      if (response.statusCode == 200) {
        setState(() => summaryText = response.data['summary']);
      } else {
        summaryError = "Failed to summarize.";
      }
    } catch (e) {
      summaryError = "Summary Error: $e";
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
      final response = await Dio().get('http://$ipAddress:8000/detect_topics/');
      final rawTopics = response.data['topics'];

      if (rawTopics is String) {
        detectedTopics = rawTopics.split('\n').where((t) => t.trim().isNotEmpty).toList();
      } else if (rawTopics is List) {
        detectedTopics = List<String>.from(rawTopics);
      } else {
        topicsError = "Invalid topics format.";
      }
    } catch (e) {
      topicsError = "Topics Error: $e";
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
      final response = await Dio().get('http://$ipAddress:8000/extract_tasks/');
      extractedTasks = (response.data['tasks'] as String)
          .split('\n')
          .where((task) => task.trim().isNotEmpty)
          .toList();
    } catch (e) {
      tasksError = "Tasks Error: $e";
    } finally {
      setState(() => isLoadingTasks = false);
    }
  }

  Future<void> refreshRecording() async {
    try {
      recorderController.reset();
      await recorderController.stop();
      stopTimer();

      final dir = await getApplicationDocumentsDirectory();
      filePath = '${dir.path}/recording.m4a';

      await recorderController.record(path: filePath);
      setState(() {
        recordingSeconds = 0;
        isRecording = true;
      });
      startTimer();
    } catch (e) {
      print("❌ Error refreshing recording: $e");
    }
  }

  Future<void> saveTranscriptionToApi() async {
    if (userId?.isEmpty ?? true || transcription!.isEmpty ?? true || filePath.isEmpty || !File(filePath).existsSync()) {
      print("⚠️ Missing required data for saving");
      return;
    }

    try {
      FormData formData = FormData.fromMap({
        "transcription": transcription ?? "",
        "enhanced": enhancedText ?? "",
        "summary": summaryText ?? "",
        "tasks": extractedTasks.join('\n'),
        "topics": detectedTopics.join('\n'),
        "User": userId,
        "audio": await MultipartFile.fromFile(
          filePath,
          filename: filePath.split(Platform.pathSeparator).last,
          contentType: MediaType('audio', 'mpeg'),
        ),
      });

      final response = await Dio().post(
        "http://$ipAddress:4000/api/transcriptions",
        data: formData,
        options: Options(contentType: "multipart/form-data"),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: ${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving transcription: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (showEnhancedPage) {
      return Scaffold(
        backgroundColor: MyColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: MyColors.backgroundColor,
          leading: IconButton(
            icon: Image.asset("assets/images/arrow.png", width: 35, height: 35),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save, size: 28),
              tooltip: 'Save',
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
                TranscriptionContainer(transcription: transcription),
                const SizedBox(height: 30),
                EnhancedTextContainer(
                  isEnhancing: isEnhancing,
                  enhancedText: enhancedText,
                  enhanceError: enhanceError,
                ),
                const SizedBox(height: 30),
                ActionButtonsRow(
                  onFetchTasks: () async {
                    showLoadingDialog();
                    await fetchTasks();
                    Navigator.pop(context);
                    setState(() => showTasks = !showTasks);
                  },
                  onFetchSummary: () async {
                    showLoadingDialog();
                    await fetchSummary();
                    Navigator.pop(context);
                    setState(() => showSummary = !showSummary);
                  },
                  onFetchTopics: () async {
                    showLoadingDialog();
                    await fetchTopics();
                    Navigator.pop(context);
                    setState(() => showTopics = !showTopics);
                  },

                  onTrelloPressed: () async {
                    final token = await getTrelloToken();
                    if (token == null || token.isEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TrelloTokenScreen()),
                      );
                    } else {
                      showTrelloInputDialog(context);
                    }
                  },
                  onSavePressed: saveTranscriptionToApi,
                ),
                const SizedBox(height: 30),
                if (showSummary)
                  SummaryContainer(
                    summaryText: summaryText,
                    isSummarizing: isSummarizing,
                    summaryError: summaryError,
                  ),
                if (showTopics) TopicsList(topics: detectedTopics),
                if (showTasks) TasksList(tasks: extractedTasks),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Spokify", style: MyFontStyle.font38Bold.copyWith(color: Colors.white)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [MyColors.button1Color, MyColors.button2Color]),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                children: [
                  Text(
                    "${(recordingSeconds ~/ 60).toString().padLeft(2, '0')}:${(recordingSeconds % 60).toString().padLeft(2, '0')}",
                    style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  RecordingWaveform(recorderController: recorderController),
                  const SizedBox(height: 20),
                  RecordingControls(
                    onClose: () => Navigator.pop(context),
                    refreshRecording: refreshRecording,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: stopRecording,
              child: Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [MyColors.button1Color, MyColors.button2Color]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stop, color: Colors.white, size: 35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
