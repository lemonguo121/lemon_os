import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../routes/routes.dart';
import '../util/CommonUtil.dart';
import '../util/SPManager.dart';
import '../util/ThemeController.dart';
import '../util/widget/LoadingImage.dart';
import 'DownloadController.dart';
import 'DownloadItem.dart';

class EpisodeListPage extends StatefulWidget {
  const EpisodeListPage({super.key});

  @override
  State<EpisodeListPage> createState() => _EpisodeListPageState();
}

class _EpisodeListPageState extends State<EpisodeListPage> {
  String vodName = '';
  var downloadController = Get.find<DownloadController>();
  var themeController = Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    var arguments = Get.arguments;
    vodName = arguments['vodName'];
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final episodes = downloadController.downloads
          .where((e) => e.vodName == vodName)
          .toList();
      return Scaffold(
        appBar: AppBar(
          title: Text(
            vodName,
            style: TextStyle(
                color: themeController.currentAppTheme.normalTextColor),
          ),
          iconTheme: IconThemeData(
            color: themeController.currentAppTheme.normalTextColor,
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView.builder(
            itemCount: episodes.length,
            itemBuilder: (context, index) {
              final item = episodes[index];

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
                      // 左侧封面图
                      SizedBox(
                        width: 150.r,
                        height: 200.r,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: LoadingImage(pic: item.vodPic),
                        ),
                      ),
                      SizedBox(width: 20.w),
                      // 中间文字信息
                      Expanded(
                        child: SizedBox(
                          height: 200.r,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 16.h,
                              ),
                              Text(
                                item.playTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: themeController
                                        .currentAppTheme.normalTextColor),
                              ),
                              Spacer(),
                              item.status == DownloadStatus.completed
                                  ? Text(
                                      getPlayPosition(item),
                                      style: TextStyle(
                                          color: themeController
                                              .currentAppTheme.normalTextColor
                                              .withAlpha(160)),
                                    )
                                  : SizedBox.shrink(),
                              SizedBox(
                                height: 8.h,
                              ),
                              Text(
                                getDownloadStatus(item),
                                style: TextStyle(
                                    color: themeController
                                        .currentAppTheme.normalTextColor
                                        .withAlpha(150)),
                              ),
                              SizedBox(
                                height: 8.h,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 右侧操作按钮
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              downloadController.deleteDownload(item.url);
                            },
                          ),
                          if (item.status.value == DownloadStatus.downloading)
                            IconButton(
                              icon: Icon(Icons.pause, color: Colors.orange),
                              onPressed: () {
                                downloadController.pauseDownload(item.url);
                              },
                            ),
                          if (item.status.value == DownloadStatus.paused)
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
        ),
      );
    });
  }

  String getDownloadStatus(DownloadItem item) {
    switch (item.status.value) {
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
    if (filePath.isEmpty) return 0;
    final file = File(filePath);
    return file.existsSync() ? file.lengthSync().toDouble() : 0;
  }

  String getPlayPosition(DownloadItem item) {
    final savedPosition = SPManager.getProgress(item.localPath ?? '');
    if (savedPosition == Duration.zero) {
      return '暂未观看';
    }
    return '观看至: ${CommonUtil.formatDuration(savedPosition)}';
  }
}
