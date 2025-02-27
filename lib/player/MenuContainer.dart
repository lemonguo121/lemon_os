import 'package:flutter/material.dart';
import '../util/CommonUtil.dart';
import 'package:video_player/video_player.dart';

import '../util/SPManager.dart';

class MenuContainer extends StatefulWidget {
  final int videoId;
  final String videoTitle;
  final VideoPlayerController controller;
  final Function(void Function()) onSetState;
  final ValueChanged<bool> showSkipFeedback;
  final ValueChanged<String> playPositonTips;
  final ValueChanged<Duration> seekToPosition;
  final bool isPlaying;
  final VoidCallback togglePlayPause;
  final VoidCallback playPreviousVideo;
  final VoidCallback playNextVideo;
  final VoidCallback toggleFullScreen;
  final bool isFullScreen;

  const MenuContainer({
    super.key,
    required this.videoId,
    required this.videoTitle,
    required this.controller,
    required this.onSetState,
    required this.showSkipFeedback,
    required this.playPositonTips,
    required this.seekToPosition,
    required this.isPlaying,
    required this.togglePlayPause,
    required this.playPreviousVideo,
    required this.playNextVideo,
    required this.toggleFullScreen,
    required this.isFullScreen,
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
    double bottomBarHeight = widget.isFullScreen ? 70.0 : 65.0;
    return Column(
      children: [
        // 顶部控制栏
        Container(
          height: 70.0,
          color: Colors.black.withOpacity(0.7),
          padding: EdgeInsets.only(
              left: 16,
              top:  35,
              right: 16,
              bottom: 0),
          child: Row(
            children: [
              Center(
                  child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (widget.isFullScreen) {
                    widget.toggleFullScreen();
                  } else {
                    Navigator.pop(context);
                  }
                },
              )),
              Flexible(child:  Text(
                widget.videoTitle,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ))
             ,
            ],
          ),
        ),
        const Spacer(flex: 4),
        Container(
          height: bottomBarHeight,
          color: Colors.black.withOpacity(0.7),
          child: Column(
            children: [
              SizedBox(
                height: 30,
                child: Row(
                  // crossAxisAlignment: CrossAxisAlignment.center,
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
                      child: Padding(
                        padding:
                            const EdgeInsets.only(left: 12, right: 12, top: 7),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: EdgeInsets.zero,
                            child: VideoProgressIndicator(
                              widget.controller,
                              allowScrubbing: true,
                              colors: const VideoProgressColors(
                                playedColor: Colors.red,
                                backgroundColor: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: _buildMenuText(CommonUtil.formatDuration(
                            widget.controller.value.duration))),
                    SizedBox(
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.skip_next, color: Colors.white),
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
                        onPressed: widget.toggleFullScreen,
                      ),
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
                                  value: widget.controller.value.playbackSpeed,
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
                                    widget.controller.setPlaybackSpeed(speed!);
                                    widget.onSetState;
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
                              final currentTime =
                                  widget.controller.value.position;
                              await SPManager.saveSkipHeadTimes(
                                  widget.videoId, currentTime);
                              widget.onSetState;
                            },
                            onLongPress: () async {
                              await SPManager.clearSkipHeadTimes(
                                  widget.videoId);
                              widget.onSetState;
                            },
                            child: FutureBuilder<Duration>(
                              future: SPManager.getSkipHeadTimes(
                                  widget.videoId),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
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
                              final currentTime =
                                  widget.controller.value.position;
                              await SPManager.saveSkipTailTimes(
                                widget.videoId,
                                (await SPManager.getSkipTailTimes(
                                    widget.videoId)),
                                currentTime,
                              );
                              widget.onSetState;
                            },
                            onLongPress: () async {
                              await SPManager.clearSkipTailTimes(
                                  widget.videoId);
                              widget.onSetState;
                            },
                            child: FutureBuilder<Duration>(
                              future: SPManager.getSkipTailTimes(
                                  widget.videoId),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
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
        )
      ],
    );
  }
}
