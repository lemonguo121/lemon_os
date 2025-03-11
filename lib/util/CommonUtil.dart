import 'package:flutter/material.dart';
import '../http/data/RealVideo.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CommonUtil {
  static Future showToast(String content) async {
    Fluttertoast.showToast(
      msg: content,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours != "00" ? "$hours:$minutes:$seconds" : "$minutes:$seconds";
  }

  // 获取播放列表
  static List<Map<String, String>> getPlayList(RealVideo video) {
    // 检查 vod_play_url 是否为字符串
    String vodPlayUrl = video.vodPlayUrl ?? '';
    if (vodPlayUrl.isEmpty) {
      return [];
    }
    // 处理字符串并转换为 List<Map<String, String>>
    return vodPlayUrl.split('#').map((item) {
      final parts = item.split('\$');
      // 确保 parts 有两个元素，防止出现数组越界错误
      if (parts.length == 2) {
        return {
          'title': parts[0],
          'url': parts[1],
        };
      } else {
        // 如果格式不正确，返回一个空的 Map
        return {'title': '', 'url': ''};
      }
    }).toList();
  }

  static bool isVertical(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    var screenHeight = screenSize.height;
    var screenWidth = screenSize.width;
    return screenHeight > screenWidth ? true : false;
  }

  static double getScreenWidth(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return screenSize.width;
  }

  static double getScreenHeight(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return screenSize.height;
  }
}
