import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../util/ThemeController.dart';

class LyricLineView extends StatelessWidget {
  final String text;
  final bool isActive;
  final double opacity;

   LyricLineView({
    super.key,
    required this.text,
    required this.isActive,
    required this.opacity,
  });
  final ThemeController themeController = Get.find();

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
              color: isActive ? themeController.currentAppTheme.selectedTextColor : Colors.white70,
              fontWeight:
              isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}