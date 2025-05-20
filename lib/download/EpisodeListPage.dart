import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

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

  Future<bool> _onWillPop() async {
    if (isShowEdit) {
      // 编辑状态下先退出编辑
      setState(() {
        isShowEdit = false;
      });
      return false; // 阻止页面返回
    }
    return true; // 允许页面返回
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    var arguments = Get.arguments;
    vodName = arguments['vodName'];
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('*****   didChangeAppLifecycleState state = $state');
    if (state == AppLifecycleState.resumed) {
      // 重新获取数据
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final episodes = downloadController.downloads
          .where((e) => e.vodName == vodName)
          .toList();
      return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              vodName,
              style: TextStyle(
                color: themeController.currentAppTheme.normalTextColor,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              color: themeController.currentAppTheme.normalTextColor,
              onPressed: () {
                // 自定义返回事件
                if (isShowEdit) {
                  // 如果正在编辑，先退出编辑模式
                  isShowEdit = false;
                  setState(() {});
                } else {
                  Navigator.pop(context); // 正常返回
                }
              },
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
                          color:
                              themeController.currentAppTheme.normalTextColor,
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
                      downloadController.refreshTrigger.value = false;
                      Routes.goLocalVideoPage(item.vodId, item.playIndex);
                    } else if (item.status.value ==
                        DownloadStatus.downloading) {
                      downloadController.pauseDownload(item.url, true);
                    } else if (item.status.value == DownloadStatus.paused ||
                        item.status.value == DownloadStatus.failed) {
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
                            color: themeController
                                .currentAppTheme.normalTextColor
                                .withAlpha(210),
                            onPressed: () {
                              Routes.goDetailPage(
                                  item.vodId, item.site, item.playIndex);
                            },
                          ),
                          SizedBox(
                            height: 24.h,
                          ),
                          if (item.status.value == DownloadStatus.downloading)
                            MiniIconButton(
                              icon: Icons.pause,
                              color: Colors.orange,
                              onPressed: () {
                                downloadController.pauseDownload(
                                    item.url, true);
                              },
                            ),
                          if (item.status.value == DownloadStatus.paused ||
                              item.status.value == DownloadStatus.pending)
                            MiniIconButton(
                              icon: Icons.play_arrow,
                              color: Colors.green,
                              onPressed: () {
                                downloadController.resumeDownload(item.url);
                              },
                            ),
                          if (item.status.value == DownloadStatus.failed)
                            MiniIconButton(
                              icon: Icons.error,
                              color: Colors.red,
                              onPressed: () {
                                downloadController.resumeDownload(item.url);
                              },
                            ),
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
        return "进度: ${item.progress}%  ${CommonUtil.formatSize(item.downloadedBytes)}";
      case DownloadStatus.conversioning:
        return "格式转换中";
      case DownloadStatus.failed:
        return "下载失败";
      case DownloadStatus.converfaild:
        return "格式转换失败";
      case DownloadStatus.pending:
        if (item.downloadedBytes > 10000) {
          return "等待  进度: ${item.progress}%  ${CommonUtil.formatSize(item.downloadedBytes)}";
        }
        return '等待';
    }
  }

  double getFileSize(String filePath) {
    if (filePath.isEmpty) return 0;
    final file = File(filePath);
    return file.existsSync() ? file.lengthSync().toDouble() : 0;
  }

  String getPlayPosition(DownloadItem item) {
    var localPath = item.localPath ?? '';
    final m3u8FileName = p.basename(localPath); // 获取文件名，例如 video.m3u8
    var localUrl = Platform.isAndroid
        ? localPath
        : 'http://127.0.0.1:12345/${item.vodName}/${item.playTitle}/$m3u8FileName';

    final savedPosition = SPManager.getProgress(localUrl);
    if (savedPosition == Duration.zero) {
      return '暂未观看';
    }
    return '观看至: ${CommonUtil.formatDuration(savedPosition)}';
  }
}
