import 'package:flutter/material.dart';

class VideoControlPanel extends StatelessWidget {
  final bool isPlaying;
  final double currentPosition;
  final double totalDuration;
  final Function onPlayPause;
  final Function onSkipForward;
  final Function onSkipBackward;
  final Function onSeek;
  final Function onFullScreen;
  final bool isFullScreen;

  const VideoControlPanel({super.key, 
    required this.isPlaying,
    required this.currentPosition,
    required this.totalDuration,
    required this.onPlayPause,
    required this.onSkipForward,
    required this.onSkipBackward,
    required this.onSeek,
    required this.onFullScreen,
    required this.isFullScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Slider(
          value: currentPosition,
          min: 0.0,
          max: totalDuration,
          onChanged: (value) {
            onSeek(value);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Text("-15s"),
              onPressed: () {
                onSkipBackward();
              },
            ),
            IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () {
                onPlayPause();
              },
            ),
            IconButton(
              icon: Text("+15s"),
              onPressed: () {
                onSkipForward();
              },
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              Duration(seconds: currentPosition.toInt()).toString().split('.').first, // 当前时间
              style: TextStyle(color: Colors.white),
            ),
            Text(
              "/${Duration(seconds: totalDuration.toInt()).toString().split('.').first}", // 总时间
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        IconButton(
          icon: Icon(
            isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
            size: 30,
          ),
          onPressed: () {
            onFullScreen();
          },
        ),
      ],
    );
  }
}