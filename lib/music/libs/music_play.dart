import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:dio/dio.dart';

import '../music_http/music_http_rquest.dart';
import 'music_control.dart';
import 'dart:math'; // 注意要加这个
import 'music_download.dart'; // 你需要导入下载管理器

class LyricLine {
  final Duration time;
  final String text;

  LyricLine(this.time, this.text);
}

enum PlayMode { loop, single }

class MusicPlayerPage extends StatefulWidget {
  final String id;
  final String songName;

  const MusicPlayerPage({super.key, required this.id, required this.songName});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage>
    with TickerProviderStateMixin {
  late AudioPlayer _player;
  late DownloadManager _downloadManager;
  bool _isDownloading = false;
  bool _downloadCompleted = false;
  String _currentSongPath = '';

  List<LyricLine> _lyrics = [];
  int _currentIndex = 0;
  final _scrollController = ScrollController();
  bool _isLoading = true;
  late AnimationController _rotationController;
  PlayMode _playMode = PlayMode.loop;
  static const double _lineHeight = 37;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

// 开始下载
  Future<void> _downloadSong() async {
    setState(() {
      _isDownloading = true;
    });

    final audioResp =
        await Dio().get(_currentSongPath); // 获取歌曲 URL
    final audioUrl = audioResp.data['url'];

    try {
      await _downloadManager.downloadSong(audioUrl, widget.songName,
          (received, total) {
        if (total != -1) {
          final progress = (received / total * 100).toStringAsFixed(0);
          print("Downloading: $progress%");
        }
      });

      setState(() {
        _downloadCompleted = true;
        _isDownloading = false;
      });
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      print("Download failed: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _rotationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();
    _initPlayerAndData();
  }

  Future<void> _initPlayerAndData() async {
    try {
      _player = AudioPlayer();
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      final rawLrcResp = await NetworkManager()
          .get('/lyric', queryParameters: {'id': widget.id});
      final rawLrc = rawLrcResp.data['rawLrc'] ?? '';
      _lyrics = _parseLrc(rawLrc);

      final audioResp = await NetworkManager()
          .get('/getMediaSource', queryParameters: {'id': widget.id});
      final audioUrl = audioResp.data['url'];
      await _player.setUrl(audioUrl);
      _currentSongPath = audioUrl;
      _player.play();
      _rotationController.repeat();

      _player.positionStream.listen((position) {
        setState(() {
          _currentPosition = position;
        });
        _onPositionChanged(position);
      });

      _player.durationStream.listen((duration) {
        setState(() {
          _totalDuration = duration ?? Duration.zero;
        });
      });

      _player.playerStateStream.listen((state) {
        if (state.playing) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
        }
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('加载失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onPositionChanged(Duration position) {
    for (int i = 0; i < _lyrics.length - 1; i++) {
      if (position >= _lyrics[i].time && position < _lyrics[i + 1].time) {
        if (_currentIndex != i) {
          setState(() => _currentIndex = i);

          // 计算目标偏移
          final targetOffset = (i - 4) * _lineHeight;
          final safeOffset = max(
            0.0,
            min(
              targetOffset.toDouble(),
              _scrollController.position.maxScrollExtent,
            ),
          );

          // 平滑滚动到指定位置
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

  List<LyricLine> _parseLrc(String rawLrc) {
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2})\](.*)');
    final lines = rawLrc.split('\n');
    final result = <LyricLine>[];

    for (final line in lines) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = int.parse(match.group(2)!);
        final ms = int.parse(match.group(3)!) * 10;
        final text = match.group(4)!.trim();
        result.add(LyricLine(
          Duration(minutes: min, seconds: sec, milliseconds: ms),
          text,
        ));
      }
    }
    return result;
  }

  void _togglePlayMode() {
    setState(() {
      _playMode = _playMode == PlayMode.loop ? PlayMode.single : PlayMode.loop;
    });
    _player
        .setLoopMode(_playMode == PlayMode.loop ? LoopMode.all : LoopMode.one);
  }

  @override
  void dispose() {
    _player.dispose();
    _scrollController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景图
          Image.asset(
            'assets/music/music_bg.png', // 你可以替换成自己的背景图路径
            fit: BoxFit.cover,
          ),
          // 半透明遮罩
          Container(color: Colors.black.withOpacity(0.4)),

          // 内容
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    const SizedBox(height: 50),
                    RotationTransition(
                      turns: _rotationController,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: AssetImage('assets/music/record.png'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _lyrics.length,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        itemBuilder: (_, i) {
                          final line = _lyrics[i];
                          final distance = (i - _currentIndex).abs();
                          final opacity =
                              (1.0 - distance * 0.2).clamp(0.2, 1.0);

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
                                    color: i == _currentIndex
                                        ? Colors.blue
                                        : Colors.white70,
                                    fontWeight: i == _currentIndex
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    MusicBottomBar(
                      isPlaying: _player.playing,
                      position: _currentPosition,
                      total: _totalDuration,
                      playMode: _playMode,
                      onPlayPause: () {
                        _player.playing ? _player.pause() : _player.play();
                      },
                      onPrev: () {
                        // TODO: 上一首逻辑
                      },
                      onNext: () {
                        // TODO: 下一首逻辑
                      },
                      onSeek: (value) {
                        final newPos = Duration(seconds: value.toInt());
                        _player.seek(newPos);
                        _onPositionChanged(newPos); // 同步歌词
                      },
                      onModeTap: _togglePlayMode,
                    ),
                  ],
                ),
          // Positioned(
          //   right: 30,
          //   top: 70,
          //   width: 40,
          //   height: 40,
          //   child: ElevatedButton(
          //     onPressed: _downloadCompleted || _isDownloading
          //         ? null // 禁用按钮
          //         : _downloadSong,
          //     child: _isDownloading
          //         ? CircularProgressIndicator()
          //         : Center(
          //       child: Icon(
          //         _downloadCompleted ? Icons.check_circle : Icons.download,
          //         color: _downloadCompleted ? Colors.green : Colors.blue,
          //       ),
          //     ),
          //   ),
          // )
        ],
      ),
    );
  }
}
