import 'package:flutter/material.dart';

class MyLoadingIndicator extends StatelessWidget {
  final bool isLoading;

  const MyLoadingIndicator({super.key, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: isLoading, // 当 isLoading 为 false 时，整个组件会被移除
      child: Container(
        color: Colors.black.withOpacity(0.3), // 遮罩层，防止点击穿透
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      ),
    );
  }
}
