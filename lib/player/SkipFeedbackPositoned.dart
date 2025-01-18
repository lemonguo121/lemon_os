import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class SkipFeedbackPositoned extends StatelessWidget {
  final String text; // 用于显示的文本
  final double videoPlayerHeight; // 用于显示的文本

  const SkipFeedbackPositoned({
    Key? key,
    required this.text,
    required this.videoPlayerHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: videoPlayerHeight / 2 - 50,
      left: MediaQuery.of(context).size.width / 2 - 50,
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