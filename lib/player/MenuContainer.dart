import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import '../util/CommonUtil.dart';
import 'package:video_player/video_player.dart';

import '../util/SPManager.dart';
import 'BatteryTimeWidget.dart';

class MenuContainer extends StatefulWidget {
  final int videoId;
  final String videoTitle;
  final VlcPlayerController controller;
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
  final bool isFullScreen;
  final bool isScreenLocked;

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
    required this.isFullScreen,
    required this.isScreenLocked,
  });

  @override
  _MenuContainerState createState() => _MenuContainerState();
}

class _MenuContainerState extends State<MenuContainer> {
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
    var bufferedProgress = widget.controller.value.bufferPercent;

    double bottomBarHeight = widget.isFullScreen ? 80.0 : 70.0;
    return Stack(
      children: [
        if (!widget.isScreenLocked)
        Column(
          children: [
            // 顶部控制栏
            Container(
              height: 70.0,
              color: Colors.black.withOpacity(0.2),
              padding: const EdgeInsets.only(left: 8, right: 16),
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
                          padding: const EdgeInsets.only(top: 35.0),
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
                        const SizedBox(width: 4), // 按钮和标题之间的间距
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 35.0),
                            child: Text(
                              widget.videoTitle,
                              style: const TextStyle(
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
                      padding: EdgeInsets.only(top: 10.0,right: 16),
                      child:
                          BatteryTimeWidget(isFullScreen: widget.isFullScreen),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 4),
            // 底部菜单
            Container(
              height: bottomBarHeight,
              color: Colors.black.withOpacity(0.2),
              child: Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: Row(
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
                          padding: const EdgeInsets.only(top: 2),
                          child: _buildMenuText(CommonUtil.formatDuration(
                              widget.controller.value.position)),
                        ),
                        Expanded(
                          child: SizedBox(
                            child: Slider(
                                value: widget
                                    .controller.value.position.inMilliseconds
                                    .toDouble(),
                                min: 0.0,
                                max: widget
                                    .controller.value.duration.inMilliseconds
                                    .toDouble(),
                                onChanged: (double value) {
                                  setState(() {
                                    widget.seekToPosition(
                                        Duration(milliseconds: value.toInt()));
                                  });
                                },
                                activeColor: Colors.blue,
                                // 自定义颜色
                                inactiveColor: Colors.white,
                                // 自定义颜色
                                secondaryActiveColor: Colors.grey,
                                secondaryTrackValue: bufferedProgress),
                          ),
                        ),
                        Padding(
                            padding: const EdgeInsets.only(top: 2),
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
                  ),
                  Container(
                      margin: const EdgeInsets.only(top: 0),
                      height: 30,
                      width: double.infinity,
                      padding: EdgeInsets.zero,
                      child: SingleChildScrollView(
                          padding: EdgeInsets.zero,
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                  margin: EdgeInsets.symmetric(horizontal: 14),
                                  height: 20.0, // 设置你想要的高度
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<double>(
                                      padding: EdgeInsets.zero,
                                      value:
                                          widget.controller.value.playbackSpeed,
                                      dropdownColor: Colors.black,
                                      style: TextStyle(color: Colors.white),
                                      items: [0.5, 1.0, 1.5, 2.0, 2.5, 3.0]
                                          .map(
                                            (speed) => DropdownMenuItem<double>(
                                              value: speed,
                                              child: _buildMenuText("$speed"),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (speed) {
                                        widget.changePlaySpeed(speed!);
                                      },
                                    ),
                                  )),
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
                              // 显示跳过片头时间
                              GestureDetector(
                                onTap: () async {
                                  widget.setSkipHead();
                                },
                                onLongPress: () async {
                                  widget.cleanSkipHead();
                                },
                                child: FutureBuilder<Duration>(
                                  future: SPManager.getSkipHeadTimes(
                                      widget.videoId),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData &&
                                        snapshot.data != null) {
                                      final headTime = snapshot.data!;
                                      return _buildMenuText(
                                          CommonUtil.formatDuration(headTime));
                                    } else {
                                      return _buildMenuText("00:00");
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(
                                width: 16,
                              ),
                              // 显示跳过片尾时间
                              GestureDetector(
                                onTap: () async {
                                  widget.setSkipTail();
                                },
                                onLongPress: () async {
                                  widget.cleanSkipTail();
                                },
                                child: FutureBuilder<Duration>(
                                  future: SPManager.getSkipTailTimes(
                                      widget.videoId),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData &&
                                        snapshot.data != null) {
                                      final headTime = snapshot.data!;
                                      return _buildMenuText(
                                          CommonUtil.formatDuration(headTime));
                                    } else {
                                      return _buildMenuText("00:00");
                                    }
                                  },
                                ),
                              ),
                            ],
                          )))
                ],
              ),
            ),
          ],
        ),
        // 锁屏按钮
        Positioned(
          right: 40,
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
