import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/util/ThemeController.dart';

class NoDataView extends StatefulWidget {
  final VoidCallback reload;
  final String errorTips;

  const NoDataView({super.key, required this.reload,required this.errorTips});

  @override
  State<NoDataView> createState() => _NoDataViewState();
}

class _NoDataViewState extends State<NoDataView> {
  ThemeController themeController=Get.find();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: widget.reload,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh,
                size: 64,
                color: themeController.currentAppTheme.selectedTextColor),
            SizedBox(height: 16),
            Text(widget.errorTips.isEmpty?'暂无数据，点击刷新':widget.errorTips,
                style: TextStyle(
                    color: themeController.currentAppTheme.selectedTextColor,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
