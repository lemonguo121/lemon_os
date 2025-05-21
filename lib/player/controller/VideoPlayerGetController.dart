import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/download/DownloadController.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../history/HistoryController.dart';
import '../../http/data/RealVideo.dart';
import '../../http/data/VideoPlayerBean.dart';
import '../../http/data/storehouse_bean_entity.dart';
import '../../util/CommonUtil.dart';
import '../../util/SPManager.dart';

class VideoPlayerGetController extends GetxController {
  final HistoryController historyController = Get.find();

  var isBuffering = false.obs; //是否在缓冲
  var lastIsVer = true.obs; //进入全屏前记录手机是否是竖直的
  var isScreenLocked = false.obs; //是否锁住屏幕
  var isParesFail = false.obs; //是否解析失败
  var isLoading = true.obs; //是否加载
  var fromIndex = 0.obs; // 用于跟踪当前选中播放的播放源(来源)
  var currentIndex = 0.obs; //用于跟踪当前选中的播放项(剧集)
  var videoPlayerList = <VideoPlayerBean>[].obs; //播放列表
  late VideoPlayerController controller;
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
  var batteryLevel = 100.obs; // 默认100%
  var playSpeed = 1.0.obs; // 倍速

  Timer? timer;
  var videoPlayer = VideoPlayerBean(
    vodId: '',
    vodName: '',
    vodPlayUrl: '',
    playTitle: '',
  ).obs;

  initializePlayer() async {
    isParesFail.value = false;
    isBuffering.value = true;
    isLoading.value = true;
    initialize.value = false;
    currentBrightness.value = await ScreenBrightness().current; // 获取系统亮度
    currentVolume.value = SPManager.getCurrentVolume(); // 获取保存的音量
    videoPlayer.value = videoPlayerList[currentIndex.value];
    var vodPlayUrl = videoPlayer.value.vodPlayUrl;
    if (vodPlayUrl.isEmpty) {
      isLoading.value = false;
      isParesFail.value = true;
      CommonUtil.showToast('播放地址为空');
      return;
    }
    print('******   vodPlayUrl = $vodPlayUrl');
    var vodId = videoPlayer.value.vodId;
    var vodName = videoPlayer.value.vodName;
    controller = VideoPlayerController.networkUrl(Uri.parse(vodPlayUrl));
    try {
      await controller.initialize();
      isLoading.value = false;
      initialize.value = true;
    } catch (e) {
      print("play error = $e");
    }
    isLoadVideoPlayed.value = false; // 确保每次初始化时复位
    var isSkipTail = false;
    final savedPosition = SPManager.getProgress(vodPlayUrl);

    // 获取跳过时间
    headTime.value = SPManager.getSkipHeadTimes(vodId);

    if (savedPosition > Duration.zero && savedPosition > headTime.value) {
      controller.seekTo(savedPosition);
    }
    if (headTime.value > Duration.zero && headTime.value > savedPosition) {
      CommonUtil.showToast("自动跳过片头");
      controller.seekTo(headTime.value);
    }

    tailTime.value = SPManager.getSkipTailTimes(vodId);
    playSpeed.value = SPManager.getPlaySpeed();
    controller.setPlaybackSpeed(playSpeed.value);
    controller.addListener(() {
      if (controller.value.hasError == true) {
        isLoading.value = false;
        isParesFail.value = true;
        print("play error = ${controller.value.errorDescription}");
      }
      currentDuration.value = controller.value.duration;
      if (currentDuration.value > Duration.zero && !isLoadVideoPlayed.value) {
        var skipTime = const Duration(milliseconds: 0);
        if (tailTime.value >= const Duration(milliseconds: 1000)) {
          isSkipTail = true;
          skipTime = tailTime.value;
        } else {
          isSkipTail = false;
          skipTime = controller.value.duration;
        }
        currentPosition.value = controller.value.position;
        if (currentPosition.value >= skipTime) {
          if (isSkipTail) {
            CommonUtil.showToast("自动跳过片尾");
          } else {
            CommonUtil.showToast("下一集");
          }
          playNextVideo();
        }
      }
      final value = controller.value;
      final buffered = value.buffered;
      final bufferedProgress = buffered.isNotEmpty
          ? buffered.last.end.inMilliseconds.toDouble()
          : 0.0;
      final currentPositionr = value.position.inMilliseconds.toDouble();
      isBuffering.value = value.isBuffering &&
          (currentPositionr >= bufferedProgress) &&
          (currentPosition.value < currentDuration.value);
    });
    toggleFullScreen;

    controller.play();
    isPlaying.value = true;
  }

  void togglePlayPause() async {
    autoCloseMenuTimer();
    if (isScreenLocked.value) {
      return;
    }
    if (isPlaying.value) {
      await controller.pause();
    } else {
      await controller.play();
    }
    isPlaying.value = !isPlaying.value;
  }

  void playPreviousVideo() async {
    autoCloseMenuTimer();
    saveProgressAndIndex();
    if (currentIndex.value > 0) {
      currentIndex.value--;
      isLoadVideoPlayed.value = true;
      await controller.pause();
      await controller.dispose();
      initializePlayer();
    } else {
      CommonUtil.showToast('已经是第一集');
    }
  }

  void playNextVideo() async {
    autoCloseMenuTimer();
    saveProgressAndIndex();
    if (currentIndex.value < videoPlayerList.length - 1) {
      currentIndex.value++;
      isLoadVideoPlayed.value = true;
      await controller.pause();
      await controller.dispose();
      initializePlayer();
    } else {
      CommonUtil.showToast('已经是最后一集');
      controller.removeListener(() {});
      isBuffering.value = false;
      isLoading.value = false;
      isPlaying.value = false;
      await controller.pause();
    }
  }

  void setSkipHead() {
    autoCloseMenuTimer();
    headTime.value = controller.value.position;
    SPManager.saveSkipHeadTimes(videoPlayer.value.vodId, headTime.value);
  }

  void cleanSkipHead() {
    autoCloseMenuTimer();
    SPManager.clearSkipHeadTimes(videoPlayer.value.vodId);
  }

  void setSkipTail() {
    autoCloseMenuTimer();
    tailTime.value = controller.value.position;
    SPManager.saveSkipTailTimes(
      videoPlayer.value.vodId,
      tailTime.value,
    );
  }

  void cleanSkipTail() {
    autoCloseMenuTimer();
    SPManager.clearSkipTailTimes(videoPlayer.value.vodId);
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
    var position = controller.value.position;
    var duration = controller.value.duration;
    Duration newPosition = position + Duration(seconds: delta);
    playPositonTips.value =
        "${CommonUtil.formatDuration(newPosition)}/${CommonUtil.formatDuration(duration)}";
    seekToPosition(newPosition);
    showSkipFeedback.value = true;
  }

  void seekToPosition(Duration position) {
    controller.seekTo(position);
    autoCloseMenuTimer();
  }

  void adjustVolume(double dy) async {
    currentVolume.value = (currentVolume.value - dy * 0.01).clamp(0.0, 1.0);
    await controller.setVolume(currentVolume.value);
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
      controller.setPlaybackSpeed(SPManager.getLongPressSpeed());
    } else {
      controller.setPlaybackSpeed(SPManager.getPlaySpeed());
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
    playSpeed.value = speed;
    controller.setPlaybackSpeed(speed);
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
      saveProgressAndIndex();
      currentIndex.value = index;
      isLoadVideoPlayed.value = true;
      await controller.pause();
      await controller.dispose();
      initializePlayer();
    }
  }

  saveProgressAndIndex() {
    SPManager.saveProgress(
        videoPlayer.value.vodPlayUrl, controller.value.position);
    print('****** saveProgressAndIndex');
  }

  bool isVerticalVideo() {
    final aspectRatio = controller.value.aspectRatio;
    return aspectRatio < 1.0;
  }

  void dispose() async {
    initialize.value = false;
    isFullScreen.value = false;
    timer?.cancel();
    await controller.dispose();
    controller.removeListener(() {});
  }
}
