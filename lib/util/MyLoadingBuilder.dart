import 'package:flutter/material.dart';

class MyLoadingBuilder {
  static Widget build(
      BuildContext context,
      Widget child,
      ImageChunkEvent? loadingProgress
      ) {
    // 当图片正在加载时显示占位图
    if (loadingProgress == null) {
      return child; // 加载完成，直接返回图片
    }

    // 显示灰色背景占位图
    return Container(
      color: Colors.grey.withOpacity(0.7), // 设置背景颜色为灰色
      alignment: Alignment.center, // 图标居中
      child: const Icon(
        Icons.photo,
        color: Colors.white,
        size: 50,
      ),
    );
  }

  // 如果图片加载失败，显示占位图
  static Widget errorBuilder(BuildContext context, Object error, StackTrace? stackTrace) {
    return Container(
      color: Colors.grey.withOpacity(0.7), // 设置背景颜色为灰色
      alignment: Alignment.center, // 图标居中
      child: const Icon(
        Icons.broken_image, // 加载失败显示破损图标
        color: Colors.white,
        size: 50,
      ),
    );
  }
}