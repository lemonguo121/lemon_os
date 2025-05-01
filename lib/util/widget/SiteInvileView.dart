import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../ThemeController.dart';

// 站点不可用
class SiteInvileView extends StatefulWidget {
  final VoidCallback reload;

  const SiteInvileView({super.key, required this.reload});

  @override
  State<SiteInvileView> createState() => _SiteInvileViewState();
}

class _SiteInvileViewState extends State<SiteInvileView> {
  final ThemeController themeController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => widget.reload(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh,
                size: 64,
                color: themeController.currentAppTheme.selectedTextColor),
            SizedBox(height: 16),
            Text('站点不可用，点击重试，或切换订阅',
                style: TextStyle(
                    color: themeController.currentAppTheme.selectedTextColor,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
