import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class SkipFeedbackPositoned extends StatelessWidget {
  final String text; // 用于显示的文本
  final double videoPlayerHeight; // 用于显示的文本

  const SkipFeedbackPositoned({
    super.key,
    required this.text,
    required this.videoPlayerHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 120,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AutoSizeText(
              text,
              style: TextStyle(color: Colors.white, fontSize: 12),
              maxLines: 1, // 限制最大行数为1
              minFontSize: 9, // 最小字体大小
              overflow: TextOverflow.ellipsis, // 超出部分显示省略号
            ),
          ],
        ),
      ),
    );
  }
}