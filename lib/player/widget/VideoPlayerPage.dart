import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/player/controller/VideoPlayerGetController.dart';
import 'package:lemon_tv/player/widget/MenuContainerPage.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../util/SPManager.dart';
import '../LongPressOnlyWidget.dart';
import '../MenuContainer.dart';
import '../SkipFeedbackPositoned.dart';
import '../VoiceAndLightFeedbackPositoned.dart';

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({super.key,});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  VideoPlayerGetController controller = Get.find();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WakelockPlus.toggle(enable: true);
      print('******   initState');
      controller.initializePlayer();
    });
  }

  @override
  void dispose() {
    controller.controller?.removeListener(() {});
    controller.controller?.dispose();
    controller.timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    // 调用异步方法，不阻塞 dispose
    controller.saveProgressAndIndex();
    SystemChrome.setPreferredOrientations([]);
    if (controller.downloadController.checkTaskAllDone()) {
      WakelockPlus.toggle(enable: false);
    }
    print('******   dispose');
    super.dispose();
  }

  void _handleVerticalDrag(DragUpdateDetails details) {
    if (controller.isScreenLocked.value) {
      return;
    }
    double delta = details.primaryDelta ?? 0;
    if (details.localPosition.dx < MediaQuery.of(context).size.width / 2) {
      // 左侧滑动 - 调节亮度
      if (delta.abs() > 2) {
        controller.adjustBrightness(delta / 2);
      }
    } else {
      // 右侧滑动 - 调节音量
      if (delta.abs() > 2) {
        controller.adjustVolume(delta / 2);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('******    didChangeAppLifecycleState ');
    if (state == AppLifecycleState.paused) {
      // 应用退到后台，暂停播放
      if (controller.isPlaying.value) {
        controller.controller?.pause();
        controller.isPlaying.value = false;
      }
    } else if (state == AppLifecycleState.resumed) {
      // 应用回到前台，继续播放
      var isPlaying = controller.controller?.value.isPlaying ?? false;
      if (!isPlaying && !controller.isPlaying.value) {
        controller.controller?.play();
        controller.isPlaying.value = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Stack(
          children: [
            Container(
              color: Colors.black, // 设置背景色为黑色
            ),
            // 悬浮在播放器上层的加载指示器
            const Center(
              child: CircularProgressIndicator(),
            ),
          ],
        );
      }
      return RawKeyboardListener(
          focusNode: FocusNode()..requestFocus(), // 自动获取焦点以监听按键
          autofocus: true,
          onKey: (RawKeyEvent event) {
            if (event is RawKeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.space) {
                controller.togglePlayPause(); // 空格键控制播放暂停
              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                controller.seekPlayProgress(5);
              } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                controller.seekPlayProgress(-5);
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                controller.adjustVolume(-1); // 上键增加音量
              } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                controller.adjustVolume(1); // 下键降低音量
              }
            } else if (event is RawKeyUpEvent) {
              // 键盘抬起时的事件
              controller.cancelControll();
            }
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                LongPressOnlyWidget(
                  onTap: () {
                    setState(() {
                      controller.isControllerVisible.value =
                          !controller.isControllerVisible.value;
                      controller.autoCloseMenuTimer();
                    });
                  },
                  onDoubleTap: controller.togglePlayPause,
                  onVerticalDragUpdate: _handleVerticalDrag,
                  onVerticalDragEnd: controller.cancelDrag,
                  onHorizontalDragUpdate: controller.handleHorizontalDrag,
                  onHorizontalDragEnd: controller.cancelDrag,
                  onLongPressStart: () => controller.fastSpeedPlay(true),
                  onLongPressEnd: () => controller.fastSpeedPlay(false),
                  child: _buildVideoPlayer(),
                ),
                if (controller.showFeedback.value)
                  VoiceAndLightFeedbackPositoned(
                    isAdjustingBrightness:
                        controller.isAdjustingBrightness.value,
                    text:
                        "${((controller.isAdjustingBrightness.value ? controller.currentBrightness.value : controller.currentVolume.value) * 100).toInt()}%",
                    videoPlayerHeight: controller.videoPlayerHeight.value,
                  ),
                if (controller.showSkipFeedback.value)
                  SkipFeedbackPositoned(
                    text: controller.playPositonTips.value,
                    videoPlayerHeight: controller.videoPlayerHeight.value,
                  ),
                if (controller.isControllerVisible.value) MenuContainerPage(),
                if (controller.isLongPressing.value)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                        padding: EdgeInsets.only(top: 95.h),
                        child: Text(
                          '${SPManager.getLongPressSpeed()}x 加速中',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            shadows: [
                              Shadow(color: Colors.black87, blurRadius: 4),
                            ],
                          ),
                        )),
                  ),
                if (!controller.isPlaying.value && controller.initialize.value)
                  Center(
                    child: GestureDetector(
                      onTap: controller.togglePlayPause,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4), // 半透明黑色背景
                          shape: BoxShape.circle, // 圆形
                        ),
                        padding: const EdgeInsets.all(10), // 控制圆的大小
                        child: const Icon(
                          Icons.play_arrow,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ));
    });
  }

  Widget _buildVideoPlayer() {
    if (controller.isParesFail.value) {
      return Center(
        child: Container(
          color: Colors.black.withOpacity(0.7), // 背景半透明遮罩
          padding: EdgeInsets.all(16), // 增加内边距
          child: Column(
            mainAxisSize: MainAxisSize.min, // 让内容居中
            children: [
              GestureDetector(
                onTap: () {
                  controller.initializePlayer();
                  print('******   initState');
                },
                child: Column(
                  children: [
                    Icon(
                      Icons.refresh, // 重试图标
                      color: Colors.white,
                      size: 36,
                    ),
                    SizedBox(height: 8), // 间距
                    Text(
                      '视频解析失败',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    var aspectRatio = controller.controller?.value.aspectRatio ?? 0;
    var playerController = controller.controller;
    if (!controller.initialize.value || controller.isBuffering.value) {
      return Stack(
        children: [
          // 播放器，背景会显示黑色或其他你选择的背景色
          Center(
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: VideoPlayer(playerController!),
            ),
          ),
          // 悬浮在播放器上层的加载指示器
          const Center(
            child: CircularProgressIndicator(),
          ),
        ],
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: VideoPlayer(playerController!),
      ),
    );
  }
}
