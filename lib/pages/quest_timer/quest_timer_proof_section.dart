import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart' as neu;

class QuestTimerProofSection extends StatelessWidget {
  const QuestTimerProofSection({
    super.key,
    required this.proofImagePath,
    required this.isCompleting,
    required this.onPickGallery,
    required this.onClearImage,
  });

  final String? proofImagePath;
  final bool isCompleting;
  final VoidCallback onPickGallery;
  final VoidCallback onClearImage;

  @override
  Widget build(BuildContext context) {
    if (proofImagePath == null) {
      return GestureDetector(
        onTap: isCompleting ? null : onPickGallery,
        child: Opacity(
          opacity: isCompleting ? 0.48 : 1,
          child: neu.Neumorphic(
            style: neu.NeumorphicStyle(
              depth: -5,
              intensity: 0.92,
              surfaceIntensity: 0.22,
              color: const Color(0xFFF1F3F8),
              shadowLightColor: Colors.white,
              shadowDarkColor: const Color(0xFFD0D7E5),
              boxShape: neu.NeumorphicBoxShape.roundRect(
                BorderRadius.circular(12),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Column(
                  children: [
                    Icon(Icons.upload_outlined, size: 20, color: Colors.black),
                    SizedBox(height: 3),
                    Text(
                      '사진 업로드',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        neu.Neumorphic(
          style: neu.NeumorphicStyle(
            depth: 7,
            intensity: 0.9,
            surfaceIntensity: 0.18,
            color: const Color(0xFFF1F3F8),
            shadowLightColor: Colors.white,
            shadowDarkColor: const Color(0xFFD0D7E5),
            boxShape: neu.NeumorphicBoxShape.roundRect(
              BorderRadius.circular(12),
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(proofImagePath!),
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 14,
          right: 14,
          child: _QuestTimerProofIconButton(
            icon: Icons.close_rounded,
            onTap: isCompleting ? null : onClearImage,
            size: 38,
          ),
        ),
      ],
    );
  }
}

class _QuestTimerProofIconButton extends StatelessWidget {
  const _QuestTimerProofIconButton({
    required this.icon,
    required this.onTap,
    this.size = 42,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: neu.Neumorphic(
          style: const neu.NeumorphicStyle(
            depth: 6,
            intensity: 0.9,
            surfaceIntensity: 0.18,
            color: Color(0xFFF1F3F8),
            shadowLightColor: Colors.white,
            shadowDarkColor: Color(0xFFD0D7E5),
            boxShape: neu.NeumorphicBoxShape.circle(),
          ),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: 20, color: const Color(0xFF667085)),
          ),
        ),
      ),
    );
  }
}
