import 'package:flutter/material.dart';

class MyLoadingBuilder {
  static Widget placeholderBuilder(BuildContext context, String url) {
    return _buildAdaptiveIcon(Icons.photo);
  }

  static Widget errorBuilder(BuildContext context, String url, dynamic error) {
    return _buildAdaptiveIcon(Icons.broken_image);
  }

  static Widget _buildAdaptiveIcon(IconData iconData) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: Colors.grey.withOpacity(0.7),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Icon(
              iconData,
              color: Colors.white,
              // 不设置 size，让 FittedBox 自适应
            ),
          ),
        );
      },
    );
  }
}