import 'package:flutter/material.dart';

class RecordingControls extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback refreshRecording;

  const RecordingControls({super.key, required this.onClose, required this.refreshRecording});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: onClose),
        IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: refreshRecording),
      ],
    );
  }
}
