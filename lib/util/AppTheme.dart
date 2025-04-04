import 'package:flutter/material.dart';

class AppTheme {
  final Color backgroundColor; // 背景色
  final Color selectedTextColor; // 选中文字颜色
  final Color unselectedTextColor; // 未选中文字颜色
  final Color normalTextColor; // 普通文字颜色
  final Color buttonColor; // 按钮颜色
  final Color iconColor; // 图标颜色
  final Color titleColr; // 标题颜色
  final Color contentColor; // 内容颜色

  AppTheme({
    required this.backgroundColor,
    required this.selectedTextColor,
    required this.unselectedTextColor,
    required this.normalTextColor,
    required this.buttonColor,
    required this.iconColor,
    required this.titleColr,
    required this.contentColor,
  });
}

