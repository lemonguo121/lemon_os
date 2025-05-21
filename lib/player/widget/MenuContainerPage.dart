import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/download/DownloadController.dart';
import 'package:lemon_tv/player/controller/VideoPlayerGetController.dart';

import '../../util/CommonUtil.dart';
import '../../util/SPManager.dart';
import '../BatteryTimeWidget.dart';

class MenuContainerPage extends StatefulWidget {
  const MenuContainerPage({super.key});

  @override
  State<MenuContainerPage> createState() => _MenuContainerPageState();
}

class _MenuContainerPageState extends State<MenuContainerPage> {
  VideoPlayerGetController controller = Get.find();
  DownloadController downloadController = Get.find();
  bool isAdjustProgress = false;
  Duration changeProgress = Duration(milliseconds: 0);

  Widget _buildMenuText(String content) {
    return Text(content,
        style: const TextStyle(color: Colors.white, fontSize: 13));
  }

  void showPlayPositionfeedback() {
    setState(() {
      controller.showSkipFeedback(true);
      controller.playPositonTips(controller.playPositonTips.value);
      Future.delayed(Duration(seconds: 1), () {
        setState(() {
          controller.showSkipFeedback(false);
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      var value = controller.controller.value;

      var bufferedRanges = value.buffered;
      var isNotEmpty = bufferedRanges.isNotEmpty;

      var bufferedProgress =
          isNotEmpty ? bufferedRanges.last.end.inMilliseconds.toDouble() : 0.0;

      Size size = value.size ;

      final max = controller.currentDuration.value.inMilliseconds.toDouble();
      final positon = (!isAdjustProgress
              ? controller.currentPosition.value.inMilliseconds.toDouble()
              : changeProgress.inMilliseconds.toDouble())
          .clamp(0.0, max); // 限制值范围

      if (max <= 0) {
        // 初始化或出错时不显示 Slider
        return const SizedBox.shrink();
      }

      return Stack(
        children: [
          if (!controller.isScreenLocked.value)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部控制栏
                Container(
                  color: Colors.black.withOpacity(0.2),
                  padding: EdgeInsets.only(left: 8.w, right: 16.w),
                  child: Padding(
                    padding: EdgeInsets.only(top: 15.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 返回按钮 + 标题
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            // 保证返回按钮和标题垂直对齐
                            children: [
                              Container(
                                margin: EdgeInsets.only(top: 30.r),
                                width: 120.r, // 扩大点击区域
                                height: 120.r,
                                child: InkWell(
                                  // 保证整个区域可点击
                                  onTap: () {
                                    if (controller.isFullScreen.value) {
                                      controller.toggleFullScreen();
                                    } else {
                                      Get.back(result: true);
                                    }
                                  },
                                  child: const Icon(Icons.arrow_back,
                                      color: Colors.white),
                                ),
                              ),

                              SizedBox(width: 4.w), // 按钮和标题之间的间距
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 35.0.h),
                                  child: Text(
                                    "${controller.videoPlayer.value.vodName} ${controller.videoPlayerList[controller.currentIndex.value].playTitle}",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 电量 & 时间
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: EdgeInsets.only(top: 10.0.h, right: 16.w),
                            child: BatteryTimeWidget(
                                isFullScreen: controller.isFullScreen.value ||
                                    controller.isAlsoShowTime.value),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 10.h,
                ),
                _buildMenuText(
                    "     ${size.width.toInt()} x ${size.height.toInt()}"),
                const Spacer(flex: 1),
                // 底部菜单
                Container(
                  color: Colors.black.withOpacity(0.2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 15.h,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.skip_previous,
                                  color: Colors.white),
                              onPressed: controller.playPreviousVideo,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 2.h),
                            child: _buildMenuText(CommonUtil.formatDuration(
                                controller.controller.value.position )),
                          ),
                          Expanded(
                            child: SizedBox(
                              child: Slider(
                                  value: positon,
                                  min: 0.0,
                                  max: max,
                                  onChanged: (double value) {
                                    setState(() {
                                      isAdjustProgress = true;
                                      controller
                                          .changingProgress(isAdjustProgress);
                                      changeProgress =
                                          Duration(milliseconds: value.toInt());

                                      controller.playPositonTips(
                                          "${CommonUtil.formatDuration(changeProgress)}/${CommonUtil.formatDuration(controller.controller.value.duration)}");
                                    });
                                  },
                                  onChangeStart: (double value) {
                                    setState(() {
                                      isAdjustProgress = true;
                                      controller
                                          .changingProgress(isAdjustProgress);
                                      controller.showSkipFeedback(true);
                                      controller.playPositonTips(
                                          "${CommonUtil.formatDuration(changeProgress)}/${CommonUtil.formatDuration(controller.controller.value.duration )}");
                                    });
                                  },
                                  onChangeEnd: (double value) {
                                    controller.seekToPosition(
                                        Duration(milliseconds: value.toInt()));
                                    Future.delayed(Duration(seconds: 1), () {
                                      setState(() {
                                        isAdjustProgress = false;
                                        controller
                                            .changingProgress(isAdjustProgress);
                                        controller.showSkipFeedback(false);
                                      });
                                    });
                                  },
                                  activeColor: Colors.white,
                                  // 自定义颜色
                                  inactiveColor: Colors.white54,
                                  // 自定义颜色
                                  secondaryActiveColor: Colors.grey,
                                  secondaryTrackValue: bufferedProgress),
                            ),
                          ),
                          Padding(
                              padding: EdgeInsets.only(top: 2.h),
                              child: _buildMenuText(CommonUtil.formatDuration(
                                  controller.controller.value.duration ))),
                          SizedBox(
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.skip_next,
                                  color: Colors.white),
                              onPressed: controller.playNextVideo,
                            ),
                          ),
                          SizedBox(
                            child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  controller.isFullScreen.value
                                      ? Icons.fullscreen_exit
                                      : Icons.fullscreen,
                                  color: Colors.white,
                                ),
                                onPressed: controller.toggleFullScreen),
                          ),
                        ],
                      ),
                      Container(
                          width: double.infinity,
                          padding: EdgeInsets.zero,
                          child: SingleChildScrollView(
                              padding: EdgeInsets.zero,
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20.0.w,
                                  ),
                                  GestureDetector(
                                      onLongPress: () {
                                        controller.changePlaySpeed(1.0);
                                      },
                                      onTap: () {
                                        var speed =
                                            controller.playSpeed.value + 0.25;
                                        if (speed > 3.0) {
                                          speed = 0.25;
                                        }
                                        controller.changePlaySpeed(speed);
                                      },
                                      child: Obx(() => _buildMenuText(
                                          "    x${controller.playSpeed.value}    "))),
                                  SizedBox(
                                    height: 20.0,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.fast_rewind,
                                          color: Colors.white),
                                      onPressed: () {
                                        controller.playPositonTips.value =
                                            "-15s";
                                        showPlayPositionfeedback();
                                        final currentPosition = controller
                                                .controller.value.position;
                                        controller.seekToPosition(
                                            currentPosition -
                                                const Duration(seconds: 15));
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    height: 20.0,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                        controller.isPlaying.value
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Colors.white,
                                      ),
                                      onPressed: controller.togglePlayPause,
                                    ),
                                  ),
                                  SizedBox(
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.fast_forward,
                                          color: Colors.white),
                                      onPressed: () {
                                        controller.playPositonTips.value =
                                            "+15s";
                                        showPlayPositionfeedback();
                                        final currentPosition = controller
                                                .controller?.value.position ??
                                            Duration();
                                        controller.seekToPosition(
                                            currentPosition +
                                                const Duration(seconds: 15));
                                      },
                                    ),
                                  ),
                                  _buildMenuText("片头/片尾"),
                                  SizedBox(
                                    width: 8.0,
                                  ),
                                  // 显示跳过片头时间
                                  GestureDetector(
                                      onTap: () async {
                                        controller.setSkipHead();
                                      },
                                      onLongPress: () async {
                                        controller.cleanSkipHead();
                                      },
                                      child: _buildMenuText(
                                     '   ${CommonUtil.formatDuration(
                                         SPManager.getSkipHeadTimes(
                                             controller.videoPlayer.value
                                                 .vodId))}  ')),
                                   SizedBox(
                                    width: 8.w,
                                  ),
                                  // 显示跳过片尾时间
                                  GestureDetector(
                                    onTap: () async {
                                      controller.setSkipTail();
                                    },
                                    onLongPress: () async {
                                      controller.cleanSkipTail();
                                    },
                                    child: _buildMenuText('  ${CommonUtil.formatDuration(
                                        SPManager.getSkipTailTimes(
                                            controller
                                                .videoPlayer.value.vodId))}   '
                                   ),
                                  ),
                                ],
                              ))),
                      SizedBox(
                        height: 20.h,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          // 锁屏按钮
          Positioned(
            right: 40.w,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: controller.toggleScreenLock,
              child: Icon(
                controller.isScreenLocked.value ? Icons.lock : Icons.lock_open,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      );
    });
  }
}
