import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lemon_tv/music/music_utils/MusicSPManage.dart';
import 'package:marquee/marquee.dart';

import '../../libs/music_download.dart';
import '../PlayListHistory.dart';
import '../music_controller.dart';
import 'music_bottom_bar.dart';

class MusicPlayerPage extends StatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage>
    with TickerProviderStateMixin {
  late DownloadManager _downloadManager;
  bool _isDownloading = false;
  bool _downloadCompleted = false;

  List<String> bgImages = ["music_bg1.png", "music_bg2.png", "music_bg3.png"];
  String bgImageName = '';

  int _currentIndex = 0;
  final _scrollController = ScrollController();

  late AnimationController _rotationController;
  PlayMode _playMode = MusicSPManage.getCurrentPlayMode();
  static const double _lineHeight = 37;
  bool showMiniBar = false;
  MusicPlayerController playerController = Get.find();

  @override
  void initState() {
    super.initState();
    bgImageName = 'assets/music/${bgImages[Random().nextInt(bgImages.length)]}';
    _rotationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();
    _initPlayerAndData();
    _downloadManager = DownloadManager(); // 初始化下载管理器
  }

  Future<void> _initPlayerAndData() async {
    _rotationController.repeat();
    ever(playerController.currentPosition, (_) {
      if (mounted && !playerController.isLoading.value) {
        _onPositionChanged();
      }
    });
    playerController.player.playerStateStream.listen((state) {
      if (mounted) {
        // 检查 Widget 是否还挂载
        if (state.playing) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
        }
      }
    });
  }

  // Future<void> _downloadSong() async {
  //   setState(() {
  //     _isDownloading = true;
  //   });
  //
  //   try {
  //     final audioResp = await Dio().get(_currentSongPath);
  //     final audioUrl = audioResp.data['url'];
  //
  //     await _downloadManager.downloadSong(audioUrl,  playerController.songName.value,
  //         (received, total) {
  //       if (total != -1) {
  //         final progress = (received / total * 100).toStringAsFixed(0);
  //         print("Downloading: $progress%");
  //       }
  //     });
  //
  //     setState(() {
  //       _downloadCompleted = true;
  //       _isDownloading = false;
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _isDownloading = false;
  //     });
  //     print("Download failed: $e");
  //   }
  // }

  void _onPositionChanged() {
    var _lyrics = playerController.lyrics.value;
    var position = playerController.currentPosition.value;

    for (int i = 0; i < _lyrics.length - 1; i++) {
      if (position >= _lyrics[i].time && position < _lyrics[i + 1].time) {
        if (_currentIndex != i) {
          setState(() => _currentIndex = i);

          final targetOffset = (i - 4) * _lineHeight;
          final safeOffset = max(
            0.0,
            min(
              targetOffset.toDouble(),
              _scrollController.position.maxScrollExtent,
            ),
          );

          _scrollController.animateTo(
            safeOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        break;
      }
    }
  }

  void _togglePlayMode() {
    setState(() {
      _playMode = _playMode == PlayMode.loop ? PlayMode.single : PlayMode.loop;
    });
    playerController.player
        .setLoopMode(_playMode == PlayMode.loop ? LoopMode.all : LoopMode.one);
    MusicSPManage.saveCurrentPlayMode(_playMode);
  }

  void _handleBackPressed() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                bgImageName,
                fit: BoxFit.cover,
              ),
              Container(color: Colors.black.withOpacity(0.4)),
              playerController.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        const SizedBox(height: 120),
                        RotationTransition(
                          turns: _rotationController,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage:
                                AssetImage('assets/music/record.png'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: _buildLyricList(),
                        ),
                        MusicBottomBar(
                          isPlaying: playerController.player.playing,
                          position: playerController.currentPosition.value,
                          total: playerController.totalDuration.value,
                          onPlayPause: () {
                            playerController.player.playing
                                ? playerController.player.pause()
                                : playerController.player.play();
                          },
                          onPrev: () {
                            playerController.onPrev();
                          },
                          onNext: () {
                            playerController.onNext();
                          },
                          showMenu: () {
                            showBottomMenu();
                          },
                          onSeek: (value) {
                            final newPos = Duration(seconds: value.toInt());
                            playerController.player.seek(newPos);
                          },
                          onModeTap: _togglePlayMode,
                        ),
                      ],
                    ),
              playerController.isLoading.value
                  ? SizedBox.shrink()
                  : _buildTitle(),
            ],
          ),
        ));
  }

  Widget _buildLyricList() {
    var _lyrics = playerController.lyrics.value;
    return ListView.builder(
      controller: _scrollController,
      itemCount: _lyrics.length,
      padding: const EdgeInsets.symmetric(vertical: 20),
      itemBuilder: (_, i) {
        final line = _lyrics[i];
        final distance = (i - _currentIndex).abs();
        final opacity = (1.0 - distance * 0.2).clamp(0.2, 1.0);

        return Opacity(
          opacity: opacity,
          child: SizedBox(
            height: _lineHeight,
            child: Center(
              child: Text(
                line.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: i == _currentIndex ? Colors.blue : Colors.white70,
                  fontWeight:
                      i == _currentIndex ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void showBottomMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlayListHistory(),
    );
  }

  Widget _buildTitle() {
    return Positioned(
      top: 44,
      left: 0,
      right: 0,
      height: 66,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _handleBackPressed,
          ),
          SizedBox(
            width: 240,
            height: 20,
            child: Marquee(
              text: getTitle(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              scrollAxis: Axis.horizontal,
              blankSpace: 60.0,
              velocity: 30.0,
              pauseAfterRound: Duration.zero,
              startPadding: 0.0,
              accelerationDuration: Duration.zero,
              accelerationCurve: Curves.linear,
              decelerationDuration: Duration.zero,
              decelerationCurve: Curves.easeOut,
            ),
          ),
          const SizedBox(width: 48), // 占位（跟返回按钮宽度对齐）
        ],
      ),
    );
  }
  String getTitle() {
    var songBean = playerController.songBean.value;
    var title = songBean.title;
    var artist = songBean.artist;
    if (artist.isEmpty && title.isEmpty) {
      return '未知歌曲';
    }
    return '$title $artist';
  }
}
