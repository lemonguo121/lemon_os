import 'package:flutter/material.dart';

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
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
            color: Colors.white
          ),
        ),
        const SizedBox(
          height: 2.0,
        ),
        Text(
          content,
          style: const TextStyle(
            fontSize: 12.0,
              color: Colors.white
          ),
        ),
      ],
    );
  }
}
