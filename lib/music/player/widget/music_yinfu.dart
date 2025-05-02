import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class AudioBarsAnimated extends StatefulWidget {
  final double barWidth;
  final double barHeight;
  final Color color;

  const AudioBarsAnimated({
    super.key,
    this.barWidth = 6,
    this.barHeight = 30,
    this.color = Colors.green,
  });

  @override
  State<AudioBarsAnimated> createState() => _AudioBarsAnimatedState();
}

class _AudioBarsAnimatedState extends State<AudioBarsAnimated> {
  List<double> heights = [0.0, 0.0, 0.0];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      setState(() {
        heights = List.generate(3, (_) => Random().nextDouble() * widget.barHeight);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        return Container(
          width: widget.barWidth,
          height: widget.barHeight,
          alignment: Alignment.bottomCenter,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: widget.barWidth,
            height: heights[index],
            color: widget.color,
          ),
        );
      }),
    );
  }
}