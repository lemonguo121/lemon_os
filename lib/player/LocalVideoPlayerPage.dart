import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/download/DownloadController.dart';
import 'package:lemon_tv/player/controller/VideoPlayerGetController.dart';
import 'package:lemon_tv/player/widget/VideoPlayerPage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../download/DownloadItem.dart';
import '../http/LocalHttpServer.dart';
import '../http/data/VideoPlayerBean.dart';
import '../util/CommonUtil.dart';
import '../util/SPManager.dart';

class LocalVideoPlayerPage extends StatefulWidget {
  LocalVideoPlayerPage();

  @override
  _LocalVideoPlayerPageState createState() => _LocalVideoPlayerPageState();
}

class _LocalVideoPlayerPageState extends State<LocalVideoPlayerPage> {
  DownloadController downloadController = Get.find();
  VideoPlayerGetController controller = Get.find();
  int? currentPlayIndex = 0; //这是剧集中的索引
  List<DownloadItem> playList = [];
  DownloadItem? video;
  bool isVertical = true;
  String vodId = '';

  @override
  void initState() {
    super.initState();
    var arguments = Get.arguments;
    vodId = arguments['vodId'];
    currentPlayIndex = arguments['playIndex'];
    WakelockPlus.toggle(enable: true);
    controller.isFullScreen.value = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isVertical = CommonUtil.isVertical();
    });
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    initPlayList();
    initializePlayer();
    controller.autoCloseMenuTimer();
  }

  void initPlayList() {
    if (vodId.isEmpty == true) {
      CommonUtil.showToast('无效视频');
      return;
    }
    playList = downloadController.getCurrentVodEpisodes(vodId);
    controller.currentIndex.value =
        playList.indexWhere((e) => e.playIndex == currentPlayIndex);
  }

  Future<void> initializePlayer() async {
    if (playList.isEmpty) {
      CommonUtil.showToast('无效视频');
      return;
    }
    video = playList[controller.currentIndex.value];

    if (video != null) {
      if (!Platform.isAndroid) {
        final dir = await getApplicationDocumentsDirectory();
        final folder = p.join(dir.path);
        await LocalHttpServer.start(folder);
      }

      var videoPlayerList = playList.map((play) {
        var localPath = play.localPath ?? '';
        final m3u8FileName = p.basename(localPath); // 获取文件名，例如 video.m3u8
        var localUrl = Platform.isAndroid
            ? localPath
            : 'http://127.0.0.1:12345/${play.vodName}/${play.playTitle}/$m3u8FileName';

        return VideoPlayerBean(
            vodId: play.vodId,
            vodName: play.vodName,
            vodPlayUrl: localUrl,
            playTitle: play.playTitle);
      }).toList();
      controller.videoPlayerList.value = videoPlayerList;
      // controller.initializePlayer();
    }
  }

  @override
  void dispose() async {
    controller.controller.removeListener(() {});
    LocalHttpServer.stop();
    _saveProgressAndIndex();
    controller.dispose();
    if (isVertical) {
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    } else {
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Future.delayed(const Duration(milliseconds: 300), () {
      SystemChrome.setPreferredOrientations([]);
    });
    if (downloadController.checkTaskAllDone()) {
      WakelockPlus.toggle(enable: false);
    }
    super.dispose();
  }

  _saveProgressAndIndex() {
    SPManager.saveProgress(
        video?.localPath ?? '', controller.controller.value.position);
  }

  @override
  Widget build(BuildContext context) {
    return VideoPlayerPage();
  }
}
