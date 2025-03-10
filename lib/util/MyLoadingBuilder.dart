import 'package:flutter/material.dart';

class MyLoadingBuilder {
  static Widget placeholderBuilder(BuildContext context, String url) {
    return Container(
      color: Colors.grey.withOpacity(0.7),
      alignment: Alignment.center,
      child: const Icon(
        Icons.photo,
        color: Colors.white,
        size: 50,
      ),
    );
  }

  static Widget errorBuilder(BuildContext context, String url, dynamic error) {
    return Container(
      color: Colors.grey.withOpacity(0.7),
      alignment: Alignment.center,
      child: const Icon(
        Icons.broken_image,
        color: Colors.white,
        size: 50,
      ),
    );
  }
}