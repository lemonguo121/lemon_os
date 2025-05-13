import 'package:flutter/material.dart';

class MiniIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final double size;
  final double boxSize;

  const MiniIconButton({
    Key? key,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.size = 20,
    this.boxSize = 32,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: size, color: color),
      onPressed: onPressed,
      constraints: BoxConstraints.tightFor(
        width: boxSize,
        height: boxSize,
      ),
      padding: EdgeInsets.zero,
      splashRadius: boxSize / 2, // 点按反馈范围
    );
  }
}