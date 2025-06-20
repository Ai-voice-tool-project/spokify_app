import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../core/helpers/ipconfig.dart';
import '../screens/TextProcessingScreen.dart';
import '../screens/recording_screen.dart';
import 'package:gradprj/core/helpers/spacing.dart';
import 'package:gradprj/core/theming/my_colors.dart';
import 'package:gradprj/cubit/transcription_cubit.dart';

class BottomBarHome extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const BottomBarHome({Key? key, this.onDataChanged}) : super(key: key);

  @override
  State<BottomBarHome> createState() => _BottomBarHomeState();
}

class _BottomBarHomeState extends State<BottomBarHome> {
  bool _isUploading = false;
  String _transcription = "";

  Future<void> _pickAndUploadAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav', 'mp3', 'ogg', 'webm', 'opus'],
    );

    if (result == null) return;

    String? filePath = result.files.single.path;
    if (filePath == null) return;

    File audioFile = File(filePath);

    setState(() {
      _isUploading = true;
    });

    try {
      String extension = audioFile.path.contains('.')
          ? audioFile.path.split('.').last.toLowerCase()
          : '';

      // تحقق من دعم الامتداد
      final supportedExtensions = ['mp3', 'wav', 'ogg', 'webm', 'opus'];
      if (!supportedExtensions.contains(extension)) {
        throw Exception('Unsupported audio format: .$extension');
      }

      String subtype;
      switch (extension) {
        case 'mp3':
          subtype = 'mpeg';
          break;
        case 'wav':
          subtype = 'wav';
          break;
        case 'ogg':
          subtype = 'ogg';
          break;
        case 'webm':
          subtype = 'webm';
          break;
        case 'opus':
          subtype = 'opus';
          break;
        default:
          subtype = 'mpeg';
      }

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioFile.path,
          filename: audioFile.path.split(Platform.pathSeparator).last,
          contentType: MediaType('audio', subtype),
        ),
      });

      String url = "http://$ipAddress:8000/transcribe/";
      Response response = await Dio().post(
        url,
        data: formData,
        options: Options(
          headers: {"Content-Type": "multipart/form-data"},
          sendTimeout: const Duration(seconds: 60),   // 60 ثانية لا أكثر
          receiveTimeout: const Duration(seconds: 60), // 60 ثانية لا أكثر
        ),
      );

      String transcription = response.data["transcription"] ?? "No Text";

      setState(() {
        _transcription = transcription;
      });

      // افتح صفحة معالجة النص وانتظر العودة
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: context.read<TranscriptionCubit>(),
            child: TextProcessingScreen(
              transcription: transcription,
              audioFilePath: audioFile.path,
            ),
          ),
        ),
      );

      // نخبر الصفحة الأم بالتحديث إذا كان هناك callback
      if (widget.onDataChanged != null) {
        widget.onDataChanged!();
      }
    } catch (e) {
      print("❌ Error uploading file: $e");
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: Text("Can't upload file: $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: context.read<TranscriptionCubit>(),
                          child: const RecordingScreen(),
                        ),
                      ),
                    ).then((_) {
                      if (widget.onDataChanged != null) widget.onDataChanged!();
                    });
                  },
                  icon: const Icon(
                    Icons.mic,
                    color: MyColors.button1Color,
                    size: 45,
                  ),
                ),
                horizontalSpace(20),
                IconButton(
                  onPressed: _isUploading ? null : _pickAndUploadAudio,
                  icon: const Icon(
                    Icons.file_upload_outlined,
                    color: MyColors.button1Color,
                    size: 45,
                  ),
                ),
              ],
            ),
          ],
        ),

        if (_isUploading)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60.0),
              child: const CircularProgressIndicator(
                color: MyColors.button1Color,
                strokeWidth: 4,
              ),
            ),
          ),
      ],
    );
  }
}

