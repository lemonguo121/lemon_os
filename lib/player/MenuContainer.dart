import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../util/CommonUtil.dart';
import 'package:video_player/video_player.dart';

import '../util/SPManager.dart';
import 'BatteryTimeWidget.dart';

class MenuContainer extends StatefulWidget {
  final String videoId;
  final String videoTitle;
  final VideoPlayerController controller;
  final ValueChanged<bool> showSkipFeedback;
  final ValueChanged<String> playPositonTips;
  final ValueChanged<Duration> seekToPosition;
  final ValueChanged<double> changePlaySpeed;
  final VoidCallback toggleScreenLock;
  final bool isPlaying;
  final VoidCallback togglePlayPause;
  final VoidCallback playPreviousVideo;
  final VoidCallback playNextVideo;
  final VoidCallback toggleFullScreen;
  final VoidCallback setSkipTail;
  final VoidCallback cleanSkipTail;
  final VoidCallback setSkipHead;
  final VoidCallback cleanSkipHead;
  final ValueChanged<bool> changingProgress;
  final bool isFullScreen;
  final bool isScreenLocked;
  final bool isAlsoShowTime;

  const MenuContainer({
    super.key,
    required this.videoId,
    required this.videoTitle,
    required this.controller,
    required this.showSkipFeedback,
    required this.playPositonTips,
    required this.seekToPosition,
    required this.changePlaySpeed,
    required this.toggleScreenLock,
    required this.isPlaying,
    required this.togglePlayPause,
    required this.playPreviousVideo,
    required this.playNextVideo,
    required this.toggleFullScreen,
    required this.setSkipTail,
    required this.cleanSkipTail,
    required this.setSkipHead,
    required this.cleanSkipHead,
    required this.changingProgress,
    required this.isFullScreen,
    required this.isScreenLocked,
    required this.isAlsoShowTime,
  });

  @override
  _MenuContainerState createState() => _MenuContainerState();
}

class _MenuContainerState extends State<MenuContainer> {
  bool isAdjustProgress = false;
  Duration changeProgress = Duration(milliseconds: 0);
  String _playPositonTips = ""; //调节进度时候的文案
  void _showPlayPositionfeedback() {
    setState(() {
      widget.showSkipFeedback(true);
      widget.playPositonTips(_playPositonTips);
      Future.delayed(Duration(seconds: 1), () {
        setState(() {
          widget.showSkipFeedback(false);
        });
      });
    });
  }

  Widget _buildMenuText(String content) {
    return Text(content,
        style: const TextStyle(color: Colors.white, fontSize: 13));
  }

  @override
  Widget build(BuildContext context) {
    var bufferedProgress = widget.controller.value.buffered.isNotEmpty
        ? widget.controller.value.buffered.last.end.inMilliseconds.toDouble()
        : 0.0;
    var size = widget.controller.value.size;

    return Stack(
      children: [
        if (!widget.isScreenLocked)
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
                            Padding(
                              padding: EdgeInsets.only(top: 35.h),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.arrow_back,
                                    color: Colors.white),
                                onPressed: () {
                                  if (widget.isFullScreen) {
                                    widget.toggleFullScreen();
                                  } else {
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                            ),
                            SizedBox(width: 4.w), // 按钮和标题之间的间距
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(top: 35.0.h),
                                child: Text(
                                  widget.videoTitle,
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
                              isFullScreen:
                                  widget.isFullScreen || widget.isAlsoShowTime),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 10.h,
              ),
              _buildMenuText("${size.width.toInt()} x ${size.height.toInt()}"),
              const Spacer(flex: 1),
              // 底部菜单
              Container(
                color: Colors.black.withOpacity(0.2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: 15.h,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.skip_previous,
                                color: Colors.white),
                            onPressed: widget.playPreviousVideo,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 2.h),
                          child: _buildMenuText(CommonUtil.formatDuration(
                              widget.controller.value.position)),
                        ),
                        Expanded(
                          child: SizedBox(
                            child: Slider(
                                value: !isAdjustProgress
                                    ? widget.controller.value.position
                                        .inMilliseconds
                                        .toDouble()
                                    : changeProgress.inMilliseconds.toDouble(),
                                min: 0.0,
                                max: widget
                                    .controller.value.duration.inMilliseconds
                                    .toDouble(),
                                onChanged: (double value) {
                                  setState(() {
                                    isAdjustProgress = true;
                                    widget.changingProgress(isAdjustProgress);
                                    changeProgress =
                                        Duration(milliseconds: value.toInt());

                                    widget.playPositonTips(
                                        "${CommonUtil.formatDuration(changeProgress)}/${CommonUtil.formatDuration(widget.controller.value.duration)}");
                                  });
                                },
                                onChangeStart: (double value) {
                                  setState(() {
                                    isAdjustProgress = true;
                                    widget.changingProgress(isAdjustProgress);
                                    widget.showSkipFeedback(true);
                                    widget.playPositonTips(
                                        "${CommonUtil.formatDuration(changeProgress)}/${CommonUtil.formatDuration(widget.controller.value.duration)}");
                                  });
                                },
                                onChangeEnd: (double value) {
                                  widget.seekToPosition(
                                      Duration(milliseconds: value.toInt()));
                                  Future.delayed(Duration(seconds: 1), () {
                                    setState(() {
                                      isAdjustProgress = false;
                                      widget.changingProgress(isAdjustProgress);
                                      widget.showSkipFeedback(false);
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
                                widget.controller.value.duration))),
                        SizedBox(
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.skip_next,
                                color: Colors.white),
                            onPressed: widget.playNextVideo,
                          ),
                        ),
                        SizedBox(
                          child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                widget.isFullScreen
                                    ? Icons.fullscreen_exit
                                    : Icons.fullscreen,
                                color: Colors.white,
                              ),
                              onPressed: widget.toggleFullScreen),
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
                                  width: 10.0,
                                ),
                                GestureDetector(
                                    onLongPress: () {
                                      widget.changePlaySpeed(1.0);
                                    },
                                    onTap: () {
                                      var speed = widget
                                              .controller.value.playbackSpeed +
                                          0.25;
                                      if (speed > 3.0) {
                                        speed = 0.25;
                                      }
                                      widget.changePlaySpeed(speed);
                                    },
                                    child: _buildMenuText(
                                        "    x${widget.controller.value.playbackSpeed}    ")),
                                SizedBox(
                                  height: 20.0,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.fast_rewind,
                                        color: Colors.white),
                                    onPressed: () {
                                      _playPositonTips = "-15s";
                                      _showPlayPositionfeedback();
                                      final currentPosition =
                                          widget.controller.value.position;
                                      widget.seekToPosition(currentPosition -
                                          const Duration(seconds: 15));
                                    },
                                  ),
                                ),
                                SizedBox(
                                  height: 20.0,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      widget.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                    ),
                                    onPressed: widget.togglePlayPause,
                                  ),
                                ),
                                SizedBox(
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.fast_forward,
                                        color: Colors.white),
                                    onPressed: () {
                                      _playPositonTips = "+15s";
                                      _showPlayPositionfeedback();
                                      final currentPosition =
                                          widget.controller.value.position;
                                      widget.seekToPosition(currentPosition +
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
                                      widget.setSkipHead();
                                    },
                                    onLongPress: () async {
                                      widget.cleanSkipHead();
                                    },
                                    child: _buildMenuText(
                                        CommonUtil.formatDuration(
                                            SPManager.getSkipHeadTimes(
                                                widget.videoId)))),
                                const SizedBox(
                                  width: 8,
                                ),
                                // 显示跳过片尾时间
                                GestureDetector(
                                  onTap: () async {
                                    widget.setSkipTail();
                                  },
                                  onLongPress: () async {
                                    widget.cleanSkipTail();
                                  },
                                  child: _buildMenuText(
                                      CommonUtil.formatDuration(
                                          SPManager.getSkipTailTimes(
                                              widget.videoId))),
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
            onTap: widget.toggleScreenLock,
            child: Icon(
              widget.isScreenLocked ? Icons.lock : Icons.lock_open,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }
}
