import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../ThemeController.dart';

// 订阅为空展示
class NoSubscriptionView extends StatefulWidget {
  final VoidCallback onAddSubscription;

  const NoSubscriptionView({super.key, required this.onAddSubscription});

  @override
  State<NoSubscriptionView> createState() => _NoSubscriptionViewState();
}

class _NoSubscriptionViewState extends State<NoSubscriptionView> {
  final ThemeController themeController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => widget.onAddSubscription(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add,
                size: 64,
                color: themeController.currentAppTheme.selectedTextColor),
            const SizedBox(height: 16),
            Text('暂无订阅，点击添加',
                style: TextStyle(
                    color: themeController.currentAppTheme.selectedTextColor,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
