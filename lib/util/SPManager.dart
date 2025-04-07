import 'dart:convert';

import 'package:lemon_tv/http/data/ParesVideo.dart';

import '../http/data/RealVideo.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../http/data/SubscripBean.dart';
import '../http/data/storehouse_bean_entity.dart';

class SPManager {
  static const String _isrealfun = "isrealfun";
  static const String _progressKey = "video_progress";
  static const String _videoFromProgress = "video_from_progress";
  static const String _playSpeedKey = "_play_speedKey";
  static const String _skipHeadKey = "skip_head_time";
  static const String _skipTailKey = "skip_tail_time";
  static const String _videoHistory = "video_history";
  static const String _current_volume = "_current_volume";
  static const String _search_key = "_current_volume";
  static const String _subscriptinKey = "_subscriptinKey";
  static const String _currentSubscriptinKey = "_currentSubscriptinKey";
  static const String _currentSitetinKey = "_currentSitetinKey";
  static const String _pares_url_video = "pares_url_video";
  static const String is_agree = "is_agree";
  static const String selectedTheme = "selectedTheme";

  static Future<bool> isRealFun() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isrealfun) ?? false;
  }

  static Future<void> saveRealFun() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_isrealfun, true);
  }

  static Future<bool> isAgree() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(is_agree) ?? false;
  }

  static Future<void> saveIsAgree() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(is_agree, true);
  }

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

  // 保存播放速度（全局）
  static void savePlaySpeed(double speed) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble(_playSpeedKey, speed);
  }

  static Future<double> getPlaySpeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_playSpeedKey) ?? 1.0;
  }

  // 保存播放到多少集
  static Future<void> saveIndex(RealVideo video, int position) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt("$_progressKey${video.vodId}", position);
  }

  // 获取播放到多少集
  static Future<int?> getIndex(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("$_progressKey$videoId");
  }

  // 保存播放的来源索引
  static Future<void> saveFromIndex(RealVideo video, int position) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt("$_videoFromProgress${video.vodId}", position);
  }

  // 获取播放的来源索引
  static Future<int?> getFromIndex(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("$_videoFromProgress$videoId");
  }

  // 获取保存的音量
  static Future<double> getCurrentVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_current_volume) ?? 0.1;
  }

  // 保存音量
  static Future<void> saveVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble(_current_volume, volume);
  }

  // 记录跳过片头
  static Future<void> saveSkipHeadTimes(
      String videoId, Duration headTime) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt("$_skipHeadKey-$videoId", headTime.inMilliseconds);
  }

  // 记录跳过片尾
  static Future<void> saveSkipTailTimes(
      String videoId, Duration headTime, Duration tailTime) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt("$_skipTailKey-$videoId", tailTime.inMilliseconds);
  }

  // 获取跳过片头
  static Future<Duration> getSkipHeadTimes(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    int? headTime = prefs.getInt("$_skipHeadKey-$videoId");
    return Duration(milliseconds: headTime ?? 0);
  }

  // 获取跳过片尾
  static Future<Duration> getSkipTailTimes(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    int? tailTime = prefs.getInt("$_skipTailKey-$videoId");
    return Duration(milliseconds: tailTime ?? 0);
  }

  // 清除跳过片头
  static Future<void> clearSkipHeadTimes(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove("$_skipHeadKey-$videoId");
  }

  // 清除跳过片尾
  static Future<void> clearSkipTailTimes(String videoId) async {
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

  // 保存指定仓库
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

  // 获取所有的仓库
  static Future<List<StorehouseBean>> getSubscriptions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString(_subscriptinKey);
    if (jsonString == null) {
      return [];
    }
    List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => StorehouseBean.fromJson(e)).toList();
  }

  // 删除指定仓库
  static Future<void> removeSubscription(String name) async {
    List<StorehouseBean> subscriptions = await getSubscriptions();
    subscriptions.removeWhere((item) {
      return item.name == name;
    });
    await saveSubscription(subscriptions);
  }

  // 获取当前选择的仓库
  static Future<StorehouseBean?> getCurrentSubscription() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString(_currentSubscriptinKey);
    if (jsonString != null) {
      Map<String, dynamic> scriptionMap = jsonDecode(jsonString);
      return StorehouseBean.fromJson(scriptionMap);
    }
    return null;
  }

  // 记录当前选择的仓库
  static Future<void> saveCurrentSubscription(
      StorehouseBean storehouseBean) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String storehouseJson =
        jsonEncode(storehouseBean.toJson()); // 序列化为 JSON 字符串
    prefs.setString(_currentSubscriptinKey, storehouseJson);
  }

  // 记录当前的站点
  static Future<void> saveCurrentSite(StorehouseBeanSites site) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String siteJson = jsonEncode(site.toJson()); // 序列化为 JSON 字符串
    prefs.setString(_currentSitetinKey, siteJson);
  }

  // 获取当前的站点
  static Future<StorehouseBeanSites?> getCurrentSite() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? siteJson = prefs.getString(_currentSitetinKey);
    if (siteJson != null) {
      Map<String, dynamic> siteMap = jsonDecode(siteJson);
      return StorehouseBeanSites.fromJson(siteMap);
    }
    return null;
  }

  // 清除当前站点
  static Future<void> cleanCurrentSite() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(_currentSitetinKey);
  }

  // 保存解析的视频资源
  static Future<void> saveParesVideo(ParesVideo videoData) async {
    final prefs = await SharedPreferences.getInstance();
    var pareHisList = await getParesVideoHisList();
    pareHisList.removeWhere((item) => item.vodPlayUrl == videoData.vodPlayUrl);
    pareHisList.insert(0, videoData); // 新记录放在列表的最前面
    await prefs.setString(_pares_url_video, jsonEncode(pareHisList));
  }

  //  获取解析的视频资源集合
  static Future<List<ParesVideo>> getParesVideoHisList() async {
    final prefs = await SharedPreferences.getInstance();
    final paresHisList = prefs.getString(_pares_url_video);
    if (paresHisList == null) {
      return [];
    }
    final history = List<Map<String, dynamic>>.from(jsonDecode(paresHisList));
    return history.map((item) => ParesVideo.fromJson2(item)).toList();
  }

  //  删除单条记录
  static Future<void> removeParesItem(ParesVideo videoData) async {
    final prefs = await SharedPreferences.getInstance();
    var pareHisList = await getParesVideoHisList();
    pareHisList.removeWhere((item) => videoData.vodPlayUrl == item.vodPlayUrl);
    await prefs.setString(_pares_url_video, jsonEncode(pareHisList));
  }

  static Future<void> selectThemeData(String themeKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(selectedTheme, themeKey);
  }

  static Future<String> getThemeData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(selectedTheme)??"浅色";
  }
}
