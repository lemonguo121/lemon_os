import 'package:flutter/material.dart';
import 'package:lemon_tv/music/music_utils/MusicSPManage.dart';
import 'package:lemon_tv/util/SubscriptionsUtil.dart';
import '../http/data/RealVideo.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../http/data/VideoPlayData.dart';
import '../http/data/VideoPlayerBean.dart';

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

  // 获取播放列表和来源，返回 VideoPlayData
  static VideoPlayData getPlayListAndForm(RealVideo video) {
    String vodPlayUrl = video.vodPlayUrl ?? '';
    String vodFrom = video.vodFrom ?? '';

    if (vodPlayUrl.isEmpty && vodFrom.isEmpty) {
      return VideoPlayData(playList: [], fromList: [], currentPlayGroup: []);
    }

    List<List<Map<String, String>>> playList = [];
    List<String> fromList = [];
    List<Map<String, String>> currentPlayGroup = [];

    // 处理 vodPlayUrl，分割并添加到结果
    if (vodPlayUrl.isNotEmpty) {
      List<String> playUrlGroups = vodPlayUrl.split(RegExp(r'\$\$\$'));
      for (var group in playUrlGroups) {
        List<Map<String, String>> playGroup = group.split('#').map((item) {
          final parts = item.split('\$');
          if (parts.length == 2) {
            return {'title': parts[0], 'url': parts[1]};
          } else {
            return {'title': '', 'url': ''};
          }
        }).toList();
        playList.add(playGroup);
      }
    }

    // 处理 vodFrom，分割并添加到结果
    if (vodFrom.isNotEmpty) {
      fromList = vodFrom.split(RegExp(r'\$\$\$'));
    }

    // 默认显示第一个 fromList 对应的 playGroup
    if (fromList.isNotEmpty && playList.isNotEmpty) {
      currentPlayGroup = playList[0]; // 默认显示第一个来源对应的播放列表
    }

    return VideoPlayData(
      playList: playList,
      fromList: fromList,
      currentPlayGroup: currentPlayGroup,
    );
  }

  static List<VideoPlayerBean> getPlayerList(
      List<Map<String, String>>? playList, RealVideo video) {
    if (playList == null || playList.isEmpty) return [];

    return playList.map((play) {
      return VideoPlayerBean(
        vodId: '${video.vodId}',
        vodName: video.vodName,
        vodPlayUrl: play['url'] ?? '',
        playTitle: play['title'] ?? '',
      );
    }).toList();
  }

  // static bool isVertical(BuildContext context) {
  //   Size screenSize = MediaQuery.of(context).size;
  //   var screenHeight = screenSize.height;
  //   var screenWidth = screenSize.width;
  //   return screenHeight > screenWidth ? true : false;
  // }

  static bool isVertical() {
    final window = WidgetsBinding.instance.window;
    final physicalSize = window.physicalSize;
    final screenWidth = physicalSize.width;
    final screenHeight = physicalSize.height;
    return screenHeight > screenWidth;
  }

  static double getScreenWidth(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return screenSize.width;
  }

  static double getScreenHeight(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return screenSize.height;
  }

  static String getCoverImg(String key) {
    return 'https://picsum.photos/seed/$key/300/200';
  }

  static String formatSize(double size) {
    // double size = bytes.toDouble();
    if (size >= 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } else if (size >= 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else if (size >= 1024) {
      return '${(size / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${size.toStringAsFixed(2)} B';
    }
  }
}
