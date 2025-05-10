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
          color: themeController.currentAppTheme.normalTextColor,
        ),
        title: Text(
          "下载管理",
          style: TextStyle(color: themeController.currentAppTheme.normalTextColor),
        ),
      ),
      body: Obx(() {
        return ListView.builder(
          itemCount: downloadController.downloads.length,
          itemBuilder: (context, index) {
            final item = downloadController.downloads[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: Icon(Icons.download, color: Colors.blue),
                title: Text(
                  item.url,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  "进度: ${item.progress}%, 状态: ${item.status.name}",
                  style: TextStyle(color: Colors.grey),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 删除按钮
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        // 删除任务
                        downloadController.deleteDownload(item.url);
                      },
                    ),
                    // 暂停和继续按钮
                    if (item.status == DownloadStatus.downloading)
                      IconButton(
                        icon: Icon(Icons.pause, color: Colors.orange),
                        onPressed: () {
                          downloadController.pauseDownload(item.url);
                        },
                      ),
                    if (item.status == DownloadStatus.paused)
                      IconButton(
                        icon: Icon(Icons.play_arrow, color: Colors.green),
                        onPressed: () {
                          // 继续下载
                          downloadController.resumeDownload(item.url);
                        },
                      ),
                  ],
                ),
                onTap: () {
                  if (item.status == DownloadStatus.completed && item.localPath != null) {
                    Routes.goLocalVideoPage(File(item.localPath ?? ''));
                  } else {
                    Get.snackbar("提示", "视频未下载完成");
                  }
                },
              ),
            );
          },
        );
      }),
    );
  }
}