import 'package:flutter/material.dart';
import 'package:gradprj/core/theming/my_colors.dart';

class EnhancedTextContainer extends StatelessWidget {
  final bool isEnhancing;
  final String? enhancedText;
  final String? enhanceError;

  const EnhancedTextContainer({
    super.key,
    required this.isEnhancing,
    required this.enhancedText,
    required this.enhanceError,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enhanced Text:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: MyColors.backgroundColor,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: MyColors.button1Color.withOpacity(0.5),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: isEnhancing
              ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : Text(
            enhanceError ?? (enhancedText ?? "No enhanced text available."),
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
