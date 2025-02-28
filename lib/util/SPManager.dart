import 'dart:convert';

import '../http/data/RealVideo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SPManager {
  static const String _progressKey = "video_progress";
  static const String _skipHeadKey = "skip_head_time";
  static const String _skipTailKey = "skip_tail_time";
  static const String _videoHistory = "video_history";
  static const String _subscriptionKey = "subscriptions";
  static const String _current_subscriptionKey = "current_subscriptions";

  // 保存播放进度
  static Future<void> saveProgress(String videoUrl, Duration position) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt("$_progressKey$videoUrl", position.inSeconds);
  }

  // 获取播放进度
  static Future<Duration> getProgress(String videoUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final seconds = prefs.getInt("$_progressKey$videoUrl") ?? 0;
    return Duration(seconds: seconds);
  }

  // 保存播放到多少集
  static Future<void> saveIndex(int videoId, int position) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt("$_progressKey$videoId", position);
  }

  // 获取播放到多少集
  static Future<int?> getIndex(int videoId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("$_progressKey$videoId");
  }

  // 记录跳过片头
  static Future<void> saveSkipHeadTimes(int videoId, Duration headTime) async {
    final prefs = await SharedPreferences.getInstance();
    print("dddddd saveSkipHeadTimes $_skipHeadKey-$videoId  headTime= ${headTime.inMilliseconds}");
    prefs.setInt("$_skipHeadKey-$videoId", headTime.inMilliseconds);
  }

  // 记录跳过片尾
  static Future<void> saveSkipTailTimes(
      int videoId, Duration headTime, Duration tailTime) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt("$_skipTailKey-$videoId", tailTime.inMilliseconds);
  }

  // 获取跳过片头
  static Future<Duration> getSkipHeadTimes(int videoId) async {
    final prefs = await SharedPreferences.getInstance();
    int? headTime = prefs.getInt("$_skipHeadKey-$videoId");
    print("dddddd getSkipHeadTimes $_skipHeadKey-$videoId  headTime= $headTime");
    return Duration(milliseconds: headTime ?? 0);
  }

  // 获取跳过片尾
  static Future<Duration> getSkipTailTimes(int videoId) async {
    final prefs = await SharedPreferences.getInstance();
    int? tailTime = prefs.getInt("$_skipTailKey-$videoId");
    return Duration(milliseconds: tailTime ?? 0);
  }

  // 清除跳过片头
  static Future<void> clearSkipHeadTimes(int videoId) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove("$_skipHeadKey-$videoId");
  }

  // 清除跳过片尾
  static Future<void> clearSkipTailTimes(int videoId) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove("$_skipTailKey-$videoId");
  }

  // 保存历史记录
  static Future<void> saveHistory(RealVideo video) async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString(_videoHistory);
    List<Map<String, dynamic>> history = historyString != null
        ? List<Map<String, dynamic>>.from(jsonDecode(historyString))
        : [];
    history.removeWhere((item) => item['vodId'] == video.vodId);
    history.insert(0, video.toJson()); // 新记录放在列表的最前面
    await prefs.setString(_videoHistory, jsonEncode(history));
  }

  // 获取历史记录
  static Future<List<RealVideo>> getHistoryList() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString(_videoHistory);
    if (historyString == null) {
      return [];
    }
    final history = List<Map<String, dynamic>>.from(jsonDecode(historyString));
    return history.map((item) => RealVideo.fromJson2(item)).toList();
  }

  static Future<void> removeSingleHistory(RealVideo video) async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString(_videoHistory);
    List<Map<String, dynamic>> history = historyString != null
        ? List<Map<String, dynamic>>.from(jsonDecode(historyString))
        : [];
    history.removeWhere((item) => item['vodId'] == video.vodId);
    await prefs.setString(_videoHistory, jsonEncode(history));
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> history = [];
    await prefs.setString(_videoHistory, jsonEncode(history));
  }

  // 保存站点列表
  static Future<void> saveSubscription(String name, String domain) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> subscriptions = prefs.getStringList(_subscriptionKey) ?? [];

    // 确保不会重复添加相同站点
    String newSite = jsonEncode({"name": name, "domain": domain});
    if (!subscriptions.contains(newSite)) {
      subscriptions.add(newSite);
      await prefs.setStringList(_subscriptionKey, subscriptions);
    }
  }

  // 获取站点列表
  static Future<List<Map<String, String>>> getSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> subscriptions = prefs.getStringList(_subscriptionKey) ?? [];
    return subscriptions.map((item) => Map<String, String>.from(jsonDecode(item))).toList();
  }

  // 删除指定站点
  static Future<void> removeSubscription(String name) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> subscriptions = prefs.getStringList(_subscriptionKey) ?? [];

    subscriptions.removeWhere((item) {
      Map<String, String> site = Map<String, String>.from(jsonDecode(item));
      return site['name'] == name;
    });

    await prefs.setStringList(_subscriptionKey, subscriptions);
  }

  // 更新站点信息
  static Future<void> updateSubscription(String oldName, String newName, String newDomain) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> subscriptions = prefs.getStringList(_subscriptionKey) ?? [];

    for (int i = 0; i < subscriptions.length; i++) {
      Map<String, String> site = Map<String, String>.from(jsonDecode(subscriptions[i]));
      if (site['name'] == oldName) {
        subscriptions[i] = jsonEncode({"name": newName, "domain": newDomain});
        break;
      }
    }
    await prefs.setStringList(_subscriptionKey, subscriptions);
  }

// 保存当前选中的站点
  static Future<void> saveCurrentSubscription(String name, String domain) async {
    final prefs = await SharedPreferences.getInstance();
    String currentSite = jsonEncode({"name": name, "domain": domain});
    await prefs.setString(_current_subscriptionKey, currentSite);
  }

// 获取当前选中的站点
  static Future<Map<String, String>?> getCurrentSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    String? currentSite = prefs.getString(_current_subscriptionKey);
    if (currentSite != null) {
      return Map<String, String>.from(jsonDecode(currentSite));
    }
    return null; // 返回 null 如果没有选中的站点
  }
}
