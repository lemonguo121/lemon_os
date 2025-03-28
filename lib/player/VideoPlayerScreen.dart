import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:video_player/video_player.dart';

import '../http/data/RealVideo.dart';
import '../player/MenuContainer.dart';
import '../util/CommonUtil.dart';
import '../util/SPManager.dart';
import 'SkipFeedbackPositoned.dart';
import 'VoiceAndLightFeedbackPositoned.dart';
import 'package:http/http.dart' as http;

class VideoPlayerScreen extends StatefulWidget {
  final int initialIndex;
  final int fromIndex;
  final RealVideo video;
  final ValueChanged<bool> onFullScreenChanged;
  final ValueChanged<int> onChangePlayPositon;
  final double videoPlayerHeight;
  static final GlobalKey<_VideoPlayerScreenState> _globalKey =
  GlobalKey<_VideoPlayerScreenState>();

  static _VideoPlayerScreenState? of(BuildContext context) {
    return _globalKey.currentState;
  }

  VideoPlayerScreen({
    required this.initialIndex,
    required this.fromIndex,
    required this.video,
    required this.onFullScreenChanged,
    required this.onChangePlayPositon,
    required this.videoPlayerHeight,
  }) : super(key: _globalKey);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late VideoPlayerController _controller;
  late int _currentIndex;
  late List<Map<String, String>> videoList; // 确保类型为 List<Map<String, String>>
  String playUrl = ""; // 确保类型为 List<Map<String, String>>
  int videoId = 0;
  bool _isControllerVisible = true;
  bool _isPlaying = false;
  bool _isFullScreen = false;
  bool _isLoadVideoPlayed = false; // 新增的标志，确保下一集只跳转一次
  double _currentBrightness = 0.5; // 默认亮度
  double _currentVolume = 0.5; // 默认音量
  bool _isAdjustingBrightness = true;
  bool _showFeedback = false; //音量、亮度调节反馈开关
  bool _showSkipFeedback = false; //跳过、回退调节反馈开关
  String _playPositonTips = ""; //调节进度时候的文案
  bool _isBuffering = false; //是否在缓冲
  bool lastIsVer = true; //进入全屏前记录手机是否是竖直的
  bool isScreenLocked = false; //是否锁住屏幕
  bool isParesFail = false; //是否解析失败
  Duration headTime = Duration(milliseconds: 0);
  Duration tailTime = Duration(milliseconds: 0);
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex;
    _initializeSystemSettings();
    _initializePlayer();
  }

  Future<void> _initializeSystemSettings() async {
    _currentBrightness = await ScreenBrightness().current; // 获取系统亮度
    _currentVolume = await SPManager.getCurrentVolume(); // 获取保存的音量
    setState(() {});
  }

  // 入口函数：解析 M3U8，判断类型，并处理广告
  Future<String> processM3U8(String m3u8Url) async {
    final response = await http.get(Uri.parse(m3u8Url));
    if (response.statusCode != 200) {
      return "无法加载 M3U8 文件";
    }

    List<String> lines = LineSplitter().convert(response.body);

    if (lines.any((line) => line.startsWith("#EXT-X-STREAM-INF"))) {
      print("检测到多码率自适应流，解析子 M3U8...");
      return await processMasterPlaylist(lines, m3u8Url);
    } else if (lines.any((line) => line.startsWith("#EXTINF"))) {
      print("检测到普通片段列表，过滤广告...");
      return await filterAndSaveM3U8(lines, m3u8Url);
    } else {
      return "未知格式的 M3U8";
    }
  }

// 处理多码率自适应流
  Future<String> processMasterPlaylist(List<String> lines,
      String baseUrl) async {
    for (String line in lines) {
      if (line.startsWith("#EXT-X-STREAM-INF")) {
        continue; // 跳过流信息
      }
      if (line.isNotEmpty && !line.startsWith("#")) {
        // 拼接完整子 M3U8 URL
        String subM3u8Url = Uri.parse(baseUrl).resolve(line).toString();
        print("解析子 M3U8: $subM3u8Url");
        return await processM3U8(subM3u8Url); // 递归处理子 M3U8
      }
    }
    return "未找到子 M3U8 URL";
  }

// 过滤广告并生成新 M3U8
  Future<String> filterAndSaveM3U8(List<String> lines, String m3u8Url) async {
    List<String> newM3U8 = [];
    bool isAdSegment = false; // 用来标记是否是广告片段
    bool isInMainContent = m3u8Url.contains("#EXT-X-KEY"); // 判断是否包含 EXT-X-KEY，如果包含则正文从第一个 EXT-X-KEY 开始
    Uri baseUri = Uri.parse(m3u8Url); // 获取 Base URL

    for (String line in lines) {
      // 如果包含 EXT-X-KEY，就开始正文内容，跳过广告
      if (isInMainContent && line.startsWith("#EXT-X-KEY")) {
        newM3U8.add(processKeyUri(line, baseUri)); // 添加 KEY 信息
        isAdSegment = false; // 进入正文，广告结束
        continue; // 跳过到下一个
      }

      // 如果是广告分隔符 EXT-X-DISCONTINUITY
      if (line.startsWith("#EXT-X-DISCONTINUITY")) {
        // 如果没有 #EXT-X-KEY，认为是广告分隔符
        if (isInMainContent) {
          // 如果正文已开始，后面是广告
          isAdSegment = true;
        }
        continue; // 跳过该广告标记
      }

      // 处理 EXTINF 片段
      if (line.startsWith("#EXTINF")) {
        if (!isAdSegment) {
          // 不是广告片段才加入
          newM3U8.add(line);
        }
      }
      // 处理 .ts 片段
      else if (line.isNotEmpty && !line.startsWith("#")) {
        if (!isAdSegment) {
          newM3U8.add(processTsUri(line, baseUri)); // 添加 TS 文件链接
        }
      }
      // 处理 #EXT-X-ENDLIST
      else if (line.startsWith("#EXT-X-ENDLIST")) {
        newM3U8.add(line);
        break; // 结束处理
      }
    }

    // 添加 M3U8 头部信息
    newM3U8.insert(0, "#EXTM3U");
    newM3U8.insert(1, "#EXT-X-VERSION:3");
    newM3U8.insert(2, "#EXT-X-TARGETDURATION:6");
    newM3U8.insert(3, "#EXT-X-MEDIA-SEQUENCE:0");
    newM3U8.insert(4, "#EXT-X-PLAYLIST-TYPE:VOD");

    return await saveM3U8File(newM3U8);
  }

  String processKeyUri(String line, Uri baseUri) {
    RegExp keyPattern = RegExp(r'URI="([^"]+)"');
    Match? match = keyPattern.firstMatch(line);

    if (match != null) {
      String keyUri = match.group(1)!;
      if (!keyUri.startsWith("http")) {
        keyUri = baseUri.resolve(keyUri).toString(); // 拼接完整 URL
      }
      return line.replaceAll(
          RegExp(r'URI="([^"]+)"'), 'URI="$keyUri"'); // 替换原 URL
    }
    return line;
  }

  String processTsUri(String line, Uri baseUri) {
    if (!line.startsWith("http")) {
      return baseUri.resolve(line).toString(); // 拼接完整 URL
    }
    return line;
  }

// 保存 M3U8 到本地
  Future<String> saveM3U8File(List<String> content) async {
    Directory dir = await getApplicationDocumentsDirectory();
    String filePath = "${dir.path}/filtered_video.m3u8";
    File file = File(filePath);
    await file.writeAsString(content.join("\n"));
    print("过滤后的 M3U8 已保存: $filePath");
    return filePath;
  }

  Future<void> _initializePlayer() async {
    setState(() {
      isParesFail = false;
      _isBuffering = true;
      isLoading = true;
    });
    videoList =
    CommonUtil
        .getPlayListAndForm(widget.video)
        .playList[widget.fromIndex];
    playUrl = videoList[_currentIndex]['url'] ?? "";
    print("sourse play url = $playUrl");
    if (playUrl.endsWith("m3u8")) {
      playUrl = await processM3U8(playUrl);
    }
    isLoading = false;
    print("play url = $playUrl");
    _controller = VideoPlayerController.network(playUrl);
    try {
      await _controller.initialize();
    } catch (e) {
      print("play error = $e");
    }
    _isLoadVideoPlayed = false; // 确保每次初始化时复位
    var isSkipTail = false;
    final savedPosition = await SPManager.getProgress(playUrl);
    videoId = widget.video.vodId;
    SPManager.saveIndex(videoId, _currentIndex);
    SPManager.saveFromIndex(videoId, widget.fromIndex);
    // 获取跳过时间
    headTime = await SPManager.getSkipHeadTimes(videoId);

    if (savedPosition > Duration.zero && savedPosition > headTime) {
      _controller.seekTo(savedPosition);
    }
    if (headTime > Duration.zero && headTime > savedPosition) {
      CommonUtil.showToast("自动跳过片头");
      _controller.seekTo(headTime);
    }

    tailTime = await SPManager.getSkipTailTimes(videoId);
    var playSpeed = await SPManager.getPlaySpeed();
    _controller.setPlaybackSpeed(playSpeed);
    _controller.addListener(() {
      if (_controller.value.hasError) {
        isParesFail = true;
        setState(() {});
        print("play error = ${_controller.value.errorDescription}");
      }
      if (_controller.value.duration > Duration.zero && !_isLoadVideoPlayed) {
        var skipTime = const Duration(milliseconds: 0);
        if (tailTime >= const Duration(milliseconds: 1000)) {
          isSkipTail = true;
          skipTime = tailTime;
        } else {
          isSkipTail = false;
          skipTime = _controller.value.duration;
        }
        if (_controller.value.position >= skipTime) {
          if (isSkipTail) {
            CommonUtil.showToast("自动跳过片尾");
          } else {
            CommonUtil.showToast("下一集");
          }
          _playNextVideo();
        }
      }

      setState(() {
        _isBuffering = _controller.value.isBuffering;
      });
    });
    _toggleFullScreen;
    setState(() {});
    _controller.play();
    _isPlaying = true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SPManager.saveProgress(playUrl, _controller.value.position);
    SPManager.saveIndex(videoId, _currentIndex);
    SPManager.saveFromIndex(videoId, widget.fromIndex);
    SPManager.saveHistory(widget.video);
    SystemChrome.setPreferredOrientations([]);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // 应用退到后台，暂停播放
      if (_controller.value.isPlaying) {
        _controller.pause();
        setState(() {
          _isPlaying = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      // 应用回到前台，继续播放
      if (!_controller.value.isPlaying && !_isPlaying) {
        _controller.play();
        setState(() {
          _isPlaying = true;
        });
      }
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (!isVerticalVideo()) {
        if (_isFullScreen) {
          lastIsVer = CommonUtil.isVertical(context);
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeRight,
            DeviceOrientation.landscapeLeft
          ]);
        } else {
          if (lastIsVer) {
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
    });
    widget.onFullScreenChanged(_isFullScreen);
  }

  void _togglePlayPause() {
    if (isScreenLocked) {
      return;
    }
    setState(() {
      if (_isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  void _playPreviousVideo() {
    if (_currentIndex > 0) {
      setState(() async {
        await SPManager.saveProgress(playUrl, _controller.value.position);
        _currentIndex--;
        _isLoadVideoPlayed = true;
        await _controller.pause();
        await _controller.dispose();
        _initializePlayer();
        widget.onChangePlayPositon(_currentIndex);
        SPManager.saveHistory(widget.video);
      });
    }
  }

  void _playNextVideo() {
    if (_currentIndex < videoList.length - 1) {
      setState(() async {
        await SPManager.saveProgress(playUrl, _controller.value.position);
        _currentIndex++;
        _isLoadVideoPlayed = true;
        await _controller.pause();
        await _controller.dispose();
        _initializePlayer();
        widget.onChangePlayPositon(_currentIndex);
      });
    }
  }

  Future<void> _setSkipHead() async {
    headTime = _controller.value.position;
    await SPManager.saveSkipHeadTimes(videoId, headTime);
    setState(() {});
  }

  Future<void> _cleanSkipHead() async {
    await SPManager.clearSkipHeadTimes(videoId);
    setState(() {});
  }

  Future<void> _setSkipTail() async {
    tailTime = _controller.value.position;
    await SPManager.saveSkipTailTimes(
      videoId,
      (await SPManager.getSkipTailTimes(videoId)),
      tailTime,
    );
    setState(() {});
  }

  Future<void> _cleanSkipTail() async {
    await SPManager.clearSkipTailTimes(videoId);
    setState(() {});
  }

  // 判断视频是横还是竖屏
  bool isVerticalVideo() {
    return _controller.value.aspectRatio < 1.0; // 宽高比小于1是竖屏
  }

  Widget _buildVideoPlayer() {
    if (isParesFail) {
      return Center(
        child: Container(
          color: Colors.black.withOpacity(0.7), // 可以设置背景颜色，给提示区域加个遮罩
          child: const Center(
            child: Text(
              '视频解析失败，换个线路试试', // 错误信息
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }
    if (!_controller.value.isInitialized || _isBuffering) {
      return Stack(
        children: [
          // 播放器，背景会显示黑色或其他你选择的背景色
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
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
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      ),
    );
  }

  void _handleVerticalDrag(DragUpdateDetails details) {
    if (isScreenLocked) {
      return;
    }
    double delta = details.primaryDelta ?? 0;
    if (details.localPosition.dx < MediaQuery
        .of(context)
        .size
        .width / 2) {
      // 左侧滑动 - 调节亮度
      if (delta.abs() > 1) {
        _adjustBrightness(delta / 2);
      }
    } else {
      // 右侧滑动 - 调节音量
      if (delta.abs() > 1) {
        _adjustVolume(delta / 2);
      }
    }
  }

  void _handleHorizontalDrag(DragUpdateDetails details) {
    if (isScreenLocked) {
      return;
    }
    double delta = details.primaryDelta ?? 0;
    if (delta.abs() > 1) {
      _seekPlayProgress((delta).toInt());
    }
  }

  void _seekPlayProgress(int delta) {
    Duration newPosition =
        _controller.value.position + Duration(minutes: delta);
    _playPositonTips =
    "${CommonUtil.formatDuration(newPosition)}/${CommonUtil.formatDuration(
        _controller.value.duration)}";
    _seekToPosition(newPosition);
    _showSkipFeedback = true;
  }

  void _adjustBrightness(double dy) async {
    _currentBrightness = (_currentBrightness - dy * 0.01).clamp(0.0, 1.0);
    await ScreenBrightness().setScreenBrightness(_currentBrightness);
    _showTemporaryFeedback(true);
  }

  void _adjustVolume(double dy) async {
    _currentVolume = (_currentVolume - dy * 0.01).clamp(0.0, 1.0);
    await _controller.setVolume(_currentVolume);
    await SPManager.saveVolume(_currentVolume);
    _showTemporaryFeedback(false);
  }

  void _showTemporaryFeedback(bool isBrightness) {
    setState(() {
      _showFeedback = true;
      _isAdjustingBrightness = isBrightness;
    });
  }

  void _cancelDrag(DragEndDetails details) {
    if (isScreenLocked) {
      return;
    }
    _cancelControll();
  }

  void _cancelControll() {
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _showFeedback = false;
        _showSkipFeedback = false;
      });
    });
  }

  void showSkipFeedback(bool showSkipFeedback) {
    setState(() {
      _showSkipFeedback = showSkipFeedback;
    });
  }

  void playPositonTips(String playPositonTips) {
    setState(() {
      _playPositonTips = playPositonTips;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
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
        focusNode: FocusNode()
          ..requestFocus(), // 自动获取焦点以监听按键
        autofocus: true,
        onKey: (RawKeyEvent event) {
          if (event is RawKeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.space) {
              _togglePlayPause(); // 空格键控制播放暂停
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _seekPlayProgress(5);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _seekPlayProgress(-5);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _adjustVolume(-1); // 上键增加音量
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _adjustVolume(1); // 下键降低音量
            }
          } else if (event is RawKeyUpEvent) {
            // 键盘抬起时的事件
            _cancelControll();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isControllerVisible = !_isControllerVisible;
                  });
                },
                // 监听双击事件
                onDoubleTap: _togglePlayPause,
                // 双击屏幕切换播放/暂停
                onVerticalDragUpdate: _handleVerticalDrag,
                onVerticalDragEnd: _cancelDrag,
                onHorizontalDragUpdate: _handleHorizontalDrag,
                onHorizontalDragEnd: _cancelDrag,
                child: _buildVideoPlayer(),
              ),
              if (_showFeedback)
                VoiceAndLightFeedbackPositoned(
                  isAdjustingBrightness: _isAdjustingBrightness,
                  text:
                  "${((_isAdjustingBrightness
                      ? _currentBrightness
                      : _currentVolume) * 100).toInt()}%",
                  videoPlayerHeight: widget.videoPlayerHeight,
                ),
              if (_showSkipFeedback)
                SkipFeedbackPositoned(
                  text: _playPositonTips,
                  videoPlayerHeight: widget.videoPlayerHeight,
                ),
              if (_isControllerVisible)
                MenuContainer(
                  videoId: videoId,
                  videoTitle:
                  "${widget.video
                      .vodName} ${videoList[_currentIndex]['title']!}",
                  controller: _controller,
                  showSkipFeedback: showSkipFeedback,
                  playPositonTips: playPositonTips,
                  seekToPosition: _seekToPosition,
                  changePlaySpeed: _changePlaySpeed,
                  toggleScreenLock: _toggleScreenLock,
                  isPlaying: _isPlaying,
                  togglePlayPause: _togglePlayPause,
                  playPreviousVideo: _playPreviousVideo,
                  playNextVideo: _playNextVideo,
                  setSkipHead: _setSkipHead,
                  cleanSkipHead: _cleanSkipHead,
                  setSkipTail: _setSkipTail,
                  cleanSkipTail: _cleanSkipTail,
                  toggleFullScreen: _toggleFullScreen,
                  isFullScreen: _isFullScreen,
                  isScreenLocked: isScreenLocked,
                ),
              if (!_isPlaying && _controller.value.isInitialized)
                Center(
                  child: GestureDetector(
                    onTap: _togglePlayPause,
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
  }

  void _seekToPosition(Duration position) {
    _controller.seekTo(position);
  }

  void _changePlaySpeed(double speed) {
    _controller.setPlaybackSpeed(speed);
    SPManager.savePlaySpeed(speed);
    setState(() {});
  }

  void _toggleScreenLock() {
    setState(() {
      isScreenLocked = !isScreenLocked;
    });
  }

  // 更新视频并重新初始化播放器
  void playVideo(String url, int index) {
    // 找到要播放的视频索引
    if (index != -1) {
      setState(() async {
        await SPManager.saveProgress(playUrl, _controller.value.position);
        _currentIndex = index;
        _isLoadVideoPlayed = true;
        await _controller.pause();
        await _controller.dispose();
        _initializePlayer();
      });
    }
  }
}
