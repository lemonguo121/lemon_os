import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../mywidget/MiniIconButton.dart';
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

class _EpisodeListPageState extends State<EpisodeListPage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  String vodName = '';
  var downloadController = Get.find<DownloadController>();
  var themeController = Get.find<ThemeController>();
  var isShowEdit = false;

  @override
  void initState() {
    super.initState();
    var arguments = Get.arguments;
    vodName = arguments['vodName'];
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 重新获取数据
      setState(() {});
    }
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
              color: themeController.currentAppTheme.normalTextColor,
            ),
          ),
          iconTheme: IconThemeData(
            color: themeController.currentAppTheme.normalTextColor,
          ),
          actions: [
            isShowEdit
                ? TextButton(
              onPressed: () {
                isShowEdit = false;
                setState(() {});
              },
              child: Text(
                '取消',
                style: TextStyle(
                  color: themeController.currentAppTheme.normalTextColor,
                  fontSize: 16,
                ),
              ),
            )
                : SizedBox.shrink(),
          ],
        ),
        body: ListView.builder(
          itemCount: episodes.length,
          itemBuilder: (context, index) {
            final item = episodes[index];

            return InkWell(
              onTap: () {
                if (isShowEdit) {
                  downloadController.deleteDownload(item.url);
                } else {
                  if (item.status.value == DownloadStatus.completed &&
                      item.localPath != null) {
                    Routes.goLocalVideoPage(item.vodId, item.playIndex);
                  } else if (item.status.value == DownloadStatus.downloading) {
                    downloadController.pauseDownload(item.url);
                  } else if (item.status.value == DownloadStatus.paused) {
                    downloadController.resumeDownload(item.url);
                  }
                }
              },
              onLongPress: () {
                isShowEdit = true;
                setState(() {});
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 8.0,
                    ),
                    isShowEdit
                        ? SizedBox(
                      height: 200.r,
                      child: Center(
                        child: MiniIconButton(
                          icon: Icons.delete_outlined,
                          color: Colors.red,
                          onPressed: () {
                            downloadController.deleteDownload(item.url);
                          },
                        ),
                      ),
                    )
                        : SizedBox.shrink(),
                    SizedBox(
                      width: 8.0,
                    ),
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
                            item.status.value == DownloadStatus.completed
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
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        MiniIconButton(
                          icon: Icons.more_vert,
                          color: themeController.currentAppTheme.normalTextColor
                              .withAlpha(210),
                          onPressed: () {
                            Routes.goDetailPage(
                                item.vodId, item.site, item.playIndex);
                          },
                        ),
                        SizedBox(height: 24.h,),
                        if (item.status.value == DownloadStatus.downloading)
                          MiniIconButton(
                            icon: Icons.pause,
                            color: Colors.orange,
                            onPressed: () {
                              downloadController.pauseDownload(item.url);
                            },
                          ),
                        if (item.status.value == DownloadStatus.paused)
                          MiniIconButton(
                            icon: Icons.play_arrow,
                            color: Colors.green,
                            onPressed: () {
                              downloadController.resumeDownload(item.url);
                            },
                          ),
                        // if (item.status.value == DownloadStatus.failed||item.status.value == DownloadStatus.converfaild)
                        //   MiniIconButton(
                        //     icon: Icons.error,
                        //     color: Colors.red,
                        //     onPressed: () {
                        //       downloadController.mergeSegments(item);
                        //     },
                        //   ),
                      ],
                    ),
                    SizedBox(
                      width: 8.0,
                    )
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  String getDownloadStatus(DownloadItem item) {
    switch (item.status.value) {
      case DownloadStatus.completed:
        return CommonUtil.formatSize(item.downloadedBytes);
      case DownloadStatus.downloading:
      case DownloadStatus.paused:
        return "进度: ${item.progress}%  ${CommonUtil.formatSize(
            item.downloadedBytes)}";
      case DownloadStatus.conversioning:
        return "格式转换中";
      case DownloadStatus.failed:
        return "下载失败";
      case DownloadStatus.converfaild:
        return "格式转换失败";
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
