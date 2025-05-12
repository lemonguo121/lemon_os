import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/util/CommonUtil.dart';
import 'package:lemon_tv/util/widget/LoadingImage.dart';

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
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: themeController.currentAppTheme.normalTextColor,
        ),
        title: Text(
          "下载管理",
          style:
              TextStyle(color: themeController.currentAppTheme.normalTextColor),
        ),
      ),
      body: Obx(() {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView.builder(
            itemCount: downloadController.downloads.length,
            itemBuilder: (context, index) {
              final item = downloadController.downloads[index];
              return InkWell(
                onTap: () {
                  if (item.status == DownloadStatus.completed &&
                      item.localPath != null) {
                    Routes.goLocalVideoPage(File(item.localPath ?? ''));
                  } else {
                    Get.snackbar("提示", "视频未下载完成");
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 左边封面图
                      SizedBox(
                        width: 120.r,
                        height: 150.r,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: LoadingImage(pic: item.vodPic),
                        ),
                      ),
                      SizedBox(width: 20.w),

                      Expanded(
                        child: SizedBox(
                          height: 150.r,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.vodName} ${item.playTitle}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Spacer(), // 让下面状态到底
                              Text(
                                getDownLoadStatus(item),
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 右侧操作按钮区域
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              downloadController.deleteDownload(item.url);
                            },
                          ),
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
                                downloadController.resumeDownload(item.url);
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  String getDownLoadStatus(DownloadItem item) {
    switch (item.status) {
      case DownloadStatus.completed:
        return CommonUtil.formatSize(getFileSize(item.localPath ?? ''));
      case DownloadStatus.downloading:
      case DownloadStatus.paused:
        return "进度: ${item.progress}%  ${CommonUtil.formatSize(item.downloadedBytes)}";
      case DownloadStatus.conversioning:
        return "格式转换中";
      case DownloadStatus.failed:
        return "下载失败";
    }
  }

  double getFileSize(String filePath) {
    if(filePath.isEmpty){
      return 0;
    }
    final file = File(filePath);
    if (file.existsSync()) {
      print('文件路径: $filePath');
      return file.lengthSync().toDouble(); // 单位是字节（bytes）
    } else {
      print('文件不存在: $filePath');
      return 0;
    }
  }
}
