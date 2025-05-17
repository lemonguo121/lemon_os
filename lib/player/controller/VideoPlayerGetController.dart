import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/download/DownloadController.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:video_player/video_player.dart';

import '../../history/HistoryController.dart';
import '../../http/data/RealVideo.dart';
import '../../http/data/storehouse_bean_entity.dart';
import '../../util/CommonUtil.dart';
import '../../util/SPManager.dart';

class VideoPlayerGetController extends GetxController {
  final HistoryController historyController = Get.find();
  final DownloadController downloadController = Get.find();
  var isBuffering = false.obs; //是否在缓冲
  var lastIsVer = true.obs; //进入全屏前记录手机是否是竖直的
  var isScreenLocked = false.obs; //是否锁住屏幕
  var isParesFail = false.obs; //是否解析失败
  var isLoading = true.obs; //是否加载
  var fromIndex = 0.obs; // 用于跟踪当前选中播放的播放源(来源)
  var currentIndex = 0.obs; //用于跟踪当前选中的播放项(剧集)
  var playUrl = ''.obs; //播放地址
  var videoId = ''.obs; //视频ID
  var videoList =
      <Map<String, String>>[].obs; // 确保类型为 List<Map<String, String>>
  VideoPlayerController? controller;
  var isLoadVideoPlayed = false.obs; // 新增的标志，确保下一集只跳转一次
  var headTime = Duration(milliseconds: 0).obs;
  var tailTime = Duration(milliseconds: 0).obs;
  var isPlaying = false.obs;
  var isControllerVisible = true.obs; //是否显示控制器菜单
  var isFullScreen = false.obs; //是否全屏
  var playPositonTips = "".obs; //调节进度时候的文案
  var showSkipFeedback = false.obs; //跳过、回退调节反馈开关
  var currentVolume = 0.5.obs; // 默认音量
  var currentBrightness = 0.5.obs; // 默认亮度
  var showFeedback = false.obs; //音量、亮度调节反馈开关
  var isAdjustingBrightness = true.obs;
  var isLongPressing = false.obs;
  var videoPlayerHeight = 0.0.obs;
  var isAlsoShowTime = false.obs;
  var initialize = false.obs;
  var currentDuration = Duration(milliseconds: 0).obs;
  var currentPosition = Duration(milliseconds: 0).obs;

  Timer? timer;
  var video = RealVideo(
          vodId: 0,
          vodName: '',
          vodSub: '',
          vodPic: '',
          vodActor: '',
          vodDirector: '',
          vodBlurb: '',
          vodRemarks: '',
          vodPubdate: '',
          vodArea: '',
          typeName: '',
          vodYear: '',
          vodPlayUrl: '',
          vodFrom: '',
          site: StorehouseBeanSites(),
          typePid: 0)
      .obs;

  initializePlayer() async {
    print('******    initializePlayer');
    isParesFail.value = false;
    isBuffering.value = true;
    isLoading.value = true;
    initialize.value = false;
    currentBrightness.value = await ScreenBrightness().current; // 获取系统亮度
    currentVolume.value = SPManager.getCurrentVolume(); // 获取保存的音量
    print("******      video.value.vodPlayUrl.isEmpty = ${video.value.vodPlayUrl.isEmpty}");
    if (video.value.vodPlayUrl.isEmpty) {
      return;
    }
    videoList.value =
        CommonUtil.getPlayListAndForm(video.value).playList[fromIndex.value];

    playUrl.value = videoList[currentIndex.value]['url'] ?? "";
    print("sourse play url = ${playUrl.value}");
    controller = VideoPlayerController.networkUrl(Uri.parse(playUrl.value));
    try {
      await controller?.initialize();
      isLoading.value = false;
      initialize.value = true;
    } catch (e) {
      print("play error = $e");
    }
    isLoadVideoPlayed.value = false; // 确保每次初始化时复位
    var isSkipTail = false;
    final savedPosition = SPManager.getProgress(playUrl.value);
    videoId.value = '${video.value.vodId}';
    historyController.saveIndex(
        video.value, currentIndex.value, fromIndex.value);
    // 获取跳过时间
    headTime.value = SPManager.getSkipHeadTimes(videoId.value);

    if (savedPosition > Duration.zero && savedPosition > headTime.value) {
      controller?.seekTo(savedPosition);
    }
    if (headTime.value > Duration.zero && headTime.value > savedPosition) {
      CommonUtil.showToast("自动跳过片头");
      controller?.seekTo(headTime.value);
    }

    tailTime.value = SPManager.getSkipTailTimes(videoId.value);
    var playSpeed = SPManager.getPlaySpeed();
    controller?.setPlaybackSpeed(playSpeed);
    controller?.addListener(() {
      if (controller?.value.hasError == true) {
        isLoading.value = false;
        isParesFail.value = true;
        print("play error = ${controller?.value.errorDescription}");
      }
      currentDuration.value =
          controller?.value.duration ?? Duration(milliseconds: 0);
      if (currentDuration.value > Duration.zero && !isLoadVideoPlayed.value) {
        var skipTime = const Duration(milliseconds: 0);
        if (tailTime.value >= const Duration(milliseconds: 1000)) {
          isSkipTail = true;
          skipTime = tailTime.value;
        } else {
          isSkipTail = false;
          skipTime = controller?.value.duration ?? Duration(milliseconds: 0);
        }
        currentPosition.value =
            controller?.value.position ?? Duration(milliseconds: 0);
        if (currentPosition.value >= skipTime) {
          if (isSkipTail) {
            CommonUtil.showToast("自动跳过片尾");
          } else {
            CommonUtil.showToast("下一集");
          }
          playNextVideo();
        }
      }
      // if (mounted) {
      //   setState(() {

      final value = controller?.value;
      if (value != null) {
        final buffered = value.buffered;
        final bufferedProgress = buffered.isNotEmpty
            ? buffered.last.end.inMilliseconds.toDouble()
            : 0.0;
        final currentPosition = value.position.inMilliseconds.toDouble();

        isBuffering.value =
            value.isBuffering && (currentPosition >= bufferedProgress);
      } else {
        isBuffering.value = false;
      }
      // });
      // _checkBuffering();
      // }
    });
    toggleFullScreen;

    controller?.play();
    isPlaying.value = true;
  }

  void togglePlayPause() async {
    autoCloseMenuTimer();
    if (isScreenLocked.value) {
      return;
    }
    if (isPlaying.value) {
      await controller?.pause();
    } else {
      await controller?.play();
    }
    isPlaying.value = !isPlaying.value;
  }

  void playPreviousVideo() async {
    autoCloseMenuTimer();
    if (currentIndex.value > 0) {
      // setState(() async {
      await SPManager.saveProgress(playUrl.value,
          controller?.value.position ?? Duration(milliseconds: 0));
      currentIndex.value--;
      isLoadVideoPlayed.value = true;
      await controller?.pause();
      await controller?.dispose();
      initializePlayer();
      print('*********  playPreviousVideo');
      // TODO 外层直接用get接受，无需回调
      // widget.onChangePlayPositon(_currentIndex);
      // });
    }
  }

  void playNextVideo() async {
    autoCloseMenuTimer();
    if (currentIndex.value < videoList.length - 1) {
      // setState(() async {
      await SPManager.saveProgress(playUrl.value,
          controller?.value.position ?? Duration(milliseconds: 0));
      currentIndex.value++;
      isLoadVideoPlayed.value = true;
      await controller?.pause();
      await controller?.dispose();
      initializePlayer();
      print('*********  playNextVideo');
      // TODO 外层直接用get接受，无需回调
      // widget.onChangePlayPositon(_currentIndex);
      // });
    }
  }

  void setSkipHead() {
    autoCloseMenuTimer();
    headTime.value = controller?.value.position ?? Duration(milliseconds: 0);
    SPManager.saveSkipHeadTimes(videoId.value, headTime.value);
  }

  void cleanSkipHead() {
    autoCloseMenuTimer();
    SPManager.clearSkipHeadTimes(videoId.value);
  }

  void setSkipTail() {
    autoCloseMenuTimer();
    tailTime.value = controller?.value.position ?? Duration(milliseconds: 0);
    SPManager.saveSkipTailTimes(
      videoId.value,
      tailTime.value,
    );
  }

  void cleanSkipTail() {
    autoCloseMenuTimer();
    SPManager.clearSkipTailTimes(videoId.value);
  }

  void toggleFullScreen() {
    autoCloseMenuTimer();
    isFullScreen.value = !isFullScreen.value;
    if (!isVerticalVideo()) {
      //判断是不是竖屏的视频，例如短视频那种，这里只处理横向的视频
      if (isFullScreen.value) {
        lastIsVer.value = CommonUtil.isVertical();
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeRight,
          DeviceOrientation.landscapeLeft
        ]);
      } else {
        if (lastIsVer.value) {
          SystemChrome.setPreferredOrientations(
              [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
        } else {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeRight,
            DeviceOrientation.landscapeLeft
          ]);
        }
        SystemChrome.setPreferredOrientations([]);
      }
    }
    // });
    // TODO 外层直接用get接受，无需回调
    // widget.onFullScreenChanged(_isFullScreen);
  }

  saveProgressAndIndex() {
    SPManager.saveProgress(
        playUrl.value, controller?.value.position ?? Duration(milliseconds: 0));
    historyController.saveIndex(
        video.value, currentIndex.value, fromIndex.value);
  }

  void autoCloseMenuTimer() {
    if (isControllerVisible.value) {
      timer?.cancel();
      // 重新启动 5 秒计时
      timer = Timer(Duration(seconds: 5), () {
        isControllerVisible.value = false;
      });
    }
  }

  void seekPlayProgress(int delta) {
    var position = controller?.value.position ?? Duration(milliseconds: 0);
    var duration = controller?.value.duration ?? Duration(milliseconds: 0);
    Duration newPosition = position + Duration(seconds: delta);
    playPositonTips.value =
        "${CommonUtil.formatDuration(newPosition)}/${CommonUtil.formatDuration(duration)}";
    seekToPosition(newPosition);
    showSkipFeedback.value = true;
  }

  void seekToPosition(Duration position) {
    controller?.seekTo(position);
    autoCloseMenuTimer();
  }

  void adjustVolume(double dy) async {
    currentVolume.value = (currentVolume.value - dy * 0.01).clamp(0.0, 1.0);
    await controller?.setVolume(currentVolume.value);
    SPManager.saveVolume(currentVolume.value);
    showTemporaryFeedback(false);
  }

  void adjustBrightness(double dy) async {
    currentBrightness.value =
        (currentBrightness.value - dy * 0.01).clamp(0.0, 1.0);
    await ScreenBrightness().setScreenBrightness(currentBrightness.value);
    showTemporaryFeedback(true);
  }

  void showTemporaryFeedback(bool isBrightness) {
    showFeedback.value = true;
    isAdjustingBrightness.value = isBrightness;
  }

  void cancelControll() {
    Future.delayed(Duration(seconds: 1), () {
      showFeedback.value = false;
      showSkipFeedback.value = false;
    });
  }

  void handleHorizontalDrag(DragUpdateDetails details) {
    if (isScreenLocked.value) {
      return;
    }
    double delta = details.primaryDelta ?? 0;
    if (delta.abs() > 2) {
      seekPlayProgress((delta).toInt());
    }
  }

  void cancelDrag(DragEndDetails details) {
    if (isScreenLocked.value) {
      return;
    }
    _cancelControll();
  }

  void _cancelControll() {
    Future.delayed(Duration(seconds: 1), () {
      showFeedback.value = false;
      showSkipFeedback.value = false;
    });
  }

  void fastSpeedPlay(bool isStart) {
    if (isStart) {
      controller?.setPlaybackSpeed(SPManager.getLongPressSpeed());
    } else {
      controller?.setPlaybackSpeed(SPManager.getPlaySpeed());
    }
    isLongPressing.value = isStart;
  }

  void isShowSkipFeedback(bool isShowSkipFeedback) {
    showSkipFeedback.value = isShowSkipFeedback;
  }

  void setPlayPositonTips(String content) {
    playPositonTips.value = content;
  }

  void changePlaySpeed(double speed) {
    controller?.setPlaybackSpeed(speed);
    SPManager.savePlaySpeed(speed);
    autoCloseMenuTimer();
  }

  void toggleScreenLock() {
    autoCloseMenuTimer();
    isScreenLocked.value = !isScreenLocked.value;
  }

  void changingProgress(bool isChanging) {
    if (!isChanging) {
      autoCloseMenuTimer();
    } else {
      timer?.cancel();
      isControllerVisible.value = isChanging;
    }
  }

  void playVideo(String url, int index) async {
    // 找到要播放的视频索引
    if (index != -1) {
      SPManager.saveProgress(
          playUrl.value, controller?.value.position ?? Duration());
      currentIndex.value = index;
      isLoadVideoPlayed.value = true;
      await controller?.pause();
      await controller?.dispose();
      initializePlayer();
      print('*********  playVideo');
    }
  }

  // bool isInitialized() {
  //   return controller?.value.isInitialized ?? false;
  // }

  bool isVerticalVideo() {
    final aspectRatio = controller?.value.aspectRatio;
    return aspectRatio != null && aspectRatio < 1.0;
  }
}
