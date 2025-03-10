import 'package:flutter/material.dart';
import 'package:lemon_os/http/data/RealVideo.dart';

class VodForamTag extends StatefulWidget {
  final RealVideo realVideo;

  const VodForamTag({super.key, required this.realVideo});

  @override
  State<VodForamTag> createState() => _VodForamTagState();
}

class _VodForamTagState extends State<VodForamTag> {
  @override
  Widget build(BuildContext context) {
    return // 右上角的红色矩形角标
        Positioned(
      right: 0.0,
      top: 0.0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(8.0), // 右上角圆角
            bottomLeft: Radius.circular(8.0), // 左下角圆角
          ),
        ),
        child: Text(
          widget.realVideo.site['name'] ?? "",
          style: TextStyle(
            color: Colors.white,
            fontSize: 10.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
