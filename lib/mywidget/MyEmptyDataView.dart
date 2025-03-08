import 'package:flutter/material.dart';

class MyEmptyDataView extends StatefulWidget {
  final VoidCallback retry;

  const MyEmptyDataView({super.key, required this.retry});

  @override
  State<MyEmptyDataView> createState() => _MyEmptyDataViewState();
}

class _MyEmptyDataViewState extends State<MyEmptyDataView> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: widget.retry, // 点击文本时触发重试
              child: const Text(
                '暂无视频内容，点击重试',
                style: TextStyle(
                  color: Colors.grey, // 设置为蓝色，突出可点击效果
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
