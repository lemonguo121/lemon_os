import 'dart:convert';

import '../http/data/RealVideo.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../http/data/SubscripBean.dart';

class SPManager {
  static const String _progressKey = "video_progress";
  static const String _skipHeadKey = "skip_head_time";
  static const String _skipTailKey = "skip_tail_time";
  static const String _videoHistory = "video_history";
  static const String _storehouseKey = "storehousekey";
  static const String _current_storehouse = "current_storehouse";
  static const String _current_volume = "_current_volume";
  static const String _search_key = "_current_volume";
  static const String _subscriptinKey = "_subscriptinKey";
  static const String _currentsubscriptinKey = "_currentsubscriptinKey";

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

  // 获取保存的音量
  static Future<double> getCurrentVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble("$_current_volume") ?? 0.1;
  }

  // 保存音量
  static Future<void> saveVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble("$_current_volume", volume);
  }

  // 记录跳过片头
  static Future<void> saveSkipHeadTimes(int videoId, Duration headTime) async {
    final prefs = await SharedPreferences.getInstance();
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
  // static Future<void> saveStorehouse(
  //     String name, String domain, String paresType) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   List<String> subscriptions = prefs.getStringList(_storehouseKey) ?? [];
  //
  //   // 确保不会重复添加相同站点
  //   String newSite =
  //       jsonEncode({"name": name, "domain": domain, "paresType": paresType});
  //   if (!subscriptions.contains(newSite)) {
  //     subscriptions.add(newSite);
  //     await prefs.setStringList(_storehouseKey, subscriptions);
  //   }
  // }

  // 获取站点列表
  // static Future<List<Map<String, String>>> getStorehouse() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   List<String> subscriptions = prefs.getStringList(_storehouseKey) ?? [];
  //   return subscriptions
  //       .map((item) => Map<String, String>.from(jsonDecode(item)))
  //       .toList();
  // }

  // 删除指定站点
  // static Future<void> removeStorehouse(String name) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   List<String> subscriptions = prefs.getStringList(_storehouseKey) ?? [];
  //
  //   subscriptions.removeWhere((item) {
  //     Map<String, String> site = Map<String, String>.from(jsonDecode(item));
  //     return site['name'] == name;
  //   });
  //
  //   await prefs.setStringList(_storehouseKey, subscriptions);
  // }

  // 更新站点信息
  // static Future<bool> updateStorehouse(String oldName, String newName,
  //     String newDomain, String newParesType) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   List<String> subscriptions = prefs.getStringList(_storehouseKey) ?? [];
  //
  //   var _currentSubscription = await getCurrentStorehouse();
  //   bool updated = false;
  //
  //   for (int i = 0; i < subscriptions.length; i++) {
  //     Map<String, String> site =
  //         Map<String, String>.from(jsonDecode(subscriptions[i]));
  //
  //     if (site['name'] == oldName) {
  //       subscriptions[i] = jsonEncode(
  //           {"name": newName, "domain": newDomain, "paresType": newParesType});
  //       updated = true;
  //
  //       // 如果当前选中的站点是旧站点，则更新当前订阅
  //       if ((_currentSubscription?['name'] ?? "") == oldName) {
  //         await saveCurrentStorehouse(newName, newDomain, newParesType);
  //       }
  //       break;
  //     }
  //   }
  //   if (updated) {
  //     await prefs.setStringList(_storehouseKey, subscriptions);
  //   }
  //   return updated;
  // }

// 保存当前选中的站点
//   static Future<void> saveCurrentStorehouse(
//       String name, String domain, String paresType) async {
//     final prefs = await SharedPreferences.getInstance();
//     String currentSite =
//         jsonEncode({"name": name, "domain": domain, "paresType": paresType});
//     await prefs.setString(_current_storehouse, currentSite);
//   }

// 更新当前选中的站点
//   static Future<void> updateCurrentStorehouse(
//       String newName, String domain) async {
//     final prefs = await SharedPreferences.getInstance();
//
//     // 去除空格，避免存入不必要的空格字符
//     String trimmedName = newName.trim();
//     String trimmedDomain = domain.trim();
//
//     String currentSite =
//         jsonEncode({"name": trimmedName, "domain": trimmedDomain});
//
//     // 确保 key 名正确
//     await prefs.setString(_current_storehouse, currentSite);
//   }

// 获取当前选中的站点
//   static Future<Map<String, String>?> getCurrentStorehouse() async {
//     final prefs = await SharedPreferences.getInstance();
//     String? currentSite = prefs.getString(_current_storehouse);
//     if (currentSite != null) {
//       return Map<String, String>.from(jsonDecode(currentSite));
//     }
//     return null; // 返回 null 如果没有选中的站点
//   }

  // 获取搜索历史
  static Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_search_key) ?? [];
  }

  // 更新搜索历史
  static Future<void> freshSearchHistory(List<String> _searchHistory) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_search_key, _searchHistory);
  }

  static Future<void> saveSubscription(
      List<StorehouseBean> subscriptions) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // 使用 Set 过滤掉重复 URL
    final uniqueSubscriptions = subscriptions.toSet().toList();

    // 序列化 JSON 并存储
    String jsonString =
        jsonEncode(uniqueSubscriptions.map((e) => e.toJson()).toList());
    await prefs.setString(_subscriptinKey, jsonString);
  }

  static Future<List<StorehouseBean>> getSubscriptions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString(_subscriptinKey);
    if (jsonString == null) {
      return [];
    }
    List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => StorehouseBean.fromJson(e)).toList();
  }

  static Future<void> saveCurrentStorehouse(StorehouseBean subscrip) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentsubscriptinKey, subscrip.url);
  }

  static Future<String> getCurrentStorehouse() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentsubscriptinKey)??"";
  }
}
