import 'dart:math';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lemon_tv/music/music_utils/MusicSPManage.dart';
import 'package:marquee/marquee.dart';
import '../../../util/widget/LoadingImage.dart';
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

  int _currentIndex = 0;
  final _scrollController = ScrollController();

  late AnimationController _rotationController;
  static const double _lineHeight = 37;
  bool showMiniBar = false;
  MusicPlayerController playerController = Get.find();
  Rx<PlayMode> playMode = (MusicSPManage.getCurrentPlayMode()).obs;
  late AnimationController _needleController;
  late Animation<double> _needleAnimation;
  @override
  void initState() {
    super.initState();
    _rotationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();
    if (playerController.player.playerState.processingState==ProcessingState.idle) {
      playerController.upDataSong(playerController.songBean.value);
    }
    _initPlayerAndData();

    _needleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _needleAnimation = Tween<double>(
      begin: -0.5, // -0.5 radians ≈ -30度，移开状态
      end: 0.0,    // 0 radians，贴合状态
    ).animate(CurvedAnimation(
      parent: _needleController,
      curve: Curves.easeInOut,
    ));
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
          _needleController.forward(); // 针靠近
        } else {
          _rotationController.stop();
          _needleController.reverse(); // 针移开
        }
      }
    });
  }
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



  void _handleBackPressed() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _rotationController.dispose();
    _needleController.reverse(); // 针移开
    _needleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 背景模糊图层...
            Stack(
              children: [
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: playerController.getCover(),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 40.0, sigmaY: 40.0),
                    child: Container(color: Colors.black.withOpacity(0.2)),
                  ),
                ),
              ],
            ),

            Container(color: Colors.black.withOpacity(0.4)),

            playerController.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : Column(
              children: [
                const SizedBox(height: 120),
                // 🎯 将唱针与唱片用 Stack 包裹起来
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    RotationTransition(
                      turns: _rotationController,
                      child: CircleAvatar(
                        radius: 60,
                        child: ClipOval(
                          child: LoadingImage(
                            pic: playerController.getCover(),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -35,
                      right: 20,
                      child: AnimatedBuilder(
                        animation: _needleAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _needleAnimation.value,
                            alignment: Alignment.topLeft,
                            child: child,
                          );
                        },
                        child: Image.asset(
                          'assets/music/needle.png',
                          width: 60,
                          height: 100,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Expanded(child: _buildLyricList()),

                MusicBottomBar(
                  isPlaying: playerController.player.playing,
                  position: playerController.currentPosition.value,
                  total: playerController.totalDuration.value,
                  onPlayPause: () {
                    playerController.player.playing
                        ? playerController.player.pause()
                        : playerController.player.play();
                  },
                  onPrev: playerController.onPrev,
                  onNext: playerController.onNext,
                  showMenu: showBottomMenu,
                  onSeek: (value) {
                    final newPos = Duration(seconds: value.toInt());
                    playerController.player.pause();
                    playerController.player.seek(newPos);
                    playerController.player.play();
                  },
                ),
              ],
            ),

            playerController.isLoading.value ? SizedBox.shrink() : _buildTitle(),
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
      builder: (_) => Wrap(
        children: const [
          PlayListHistory(),
        ],
      ),
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
              text: playerController.getTitle(),
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

}
