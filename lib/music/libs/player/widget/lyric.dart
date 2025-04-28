import 'package:flutter/material.dart';

class LyricLineView extends StatelessWidget {
  final String text;
  final bool isActive;
  final double opacity;

  const LyricLineView({
    super.key,
    required this.text,
    required this.isActive,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        height: 32,
        child: Align(
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: isActive ? Colors.blue : Colors.white70,
              fontWeight:
              isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}