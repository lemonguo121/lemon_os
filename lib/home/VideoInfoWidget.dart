import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Videoinfowidget extends StatelessWidget {
  final String title;
  final String content;

  const Videoinfowidget({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
              fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(
          height: 2.0,
        ),
        GestureDetector(
          onLongPress: (){
            Clipboard.setData(ClipboardData(text: content));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("文本已复制")),
            );
          },
          child: Text(
            content,
            style: const TextStyle(fontSize: 12.0, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
