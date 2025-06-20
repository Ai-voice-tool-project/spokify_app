import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theming/my_colors.dart';

class ImageCircleAvatar extends StatelessWidget {
  final String userName;
  final String? imageUrl;
  final VoidCallback onImageTap;

  const ImageCircleAvatar({
    super.key,
    required this.userName,
    required this.imageUrl,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        GestureDetector(
          onTap: onImageTap,
          child: CircleAvatar(
            radius: 40,
            backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                ? (imageUrl!.startsWith('http')
                ? NetworkImage(imageUrl!)
                : FileImage(File(imageUrl!)) as ImageProvider)
                : null,
            child: (imageUrl == null || imageUrl!.isEmpty)
                ? Text(
              initials,
              style: const TextStyle(fontSize: 30, color: Colors.white),
            )
                : null,
            backgroundColor: MyColors.button1Color,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: onImageTap,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade800,
              ),
              padding: const EdgeInsets.all(5),
              child: const Icon(Icons.edit, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }
}
