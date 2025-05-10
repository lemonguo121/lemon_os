import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/routes.dart';
import '../util/ThemeController.dart';
import 'DownloadController.dart';
import 'DownloadItem.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final downloadController = Get.find<DownloadController>();
  final ThemeController themeController = Get.find();
  @override
  Widget build(BuildContext context) {
    var downloads = downloadController.downloads;
    print('*********  downloads =  ${downloads.length}');
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
            color: themeController.currentAppTheme.normalTextColor),
        title: Text(
          "下载管理",
          style:
          TextStyle(color: themeController.currentAppTheme.normalTextColor),
        ),
      ),
      body: Obx(() {
        return ListView.builder(
          itemCount: downloadController.downloads.length,
          itemBuilder: (context, index) {
            final item = downloadController.downloads[index];
            return ListTile(
              title: Text(item.url),
              subtitle: Text("进度: ${item.progress}%, 状态: ${item.status.name}"),
              onTap: () {
                if (item.status == DownloadStatus.completed && item.localPath != null) {
                  Routes.goLocalVideoPage(File(item.localPath??''));
                } else {
                  Get.snackbar("提示", "视频未下载完成");
                }
              },
            );
          },
        );
      }),
    );
  }
}
