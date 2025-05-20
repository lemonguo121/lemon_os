import 'package:flutter/material.dart';

class VoiceAndLightFeedbackPositoned extends StatelessWidget {
  final bool isAdjustingBrightness;
  final String text;

  const VoiceAndLightFeedbackPositoned({
    super.key,
    required this.isAdjustingBrightness,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAdjustingBrightness ? Icons.brightness_6 : Icons.volume_up,
              color: Colors.white,
              size: 40,
            ),
            Text(
              // "${((isAdjustingBrightness ? _currentBrightness : _currentVolume) * 100).toInt()}%",
              text,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
