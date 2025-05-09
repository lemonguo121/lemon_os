import 'dart:convert';

import 'package:get/get.dart';
import 'package:lemon_tv/http/data/ParesVideo.dart';
import 'package:lemon_tv/util/CommonUtil.dart';

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
  static const String _search_key = "_search_key";
  static const String _subscriptinKey = "_subscriptinKey";
  static const String _currentSubscriptinKey = "_currentSubscriptinKey";
  static const String _currentSitetinKey = "_currentSitetinKey";
  static const String _pares_url_video = "pares_url_video";
  static const String is_agree = "is_agree";
  static const String selectedTheme = "selectedTheme";
  static const String longPressSpeed = "longPressSpeed";

  static bool isRealFun() {
    SharedPreferences sp = Get.find<SharedPreferences>();
    return sp.getBool(_isrealfun) ?? false;
  }

  static saveRealFun() {
    SharedPreferences sp = Get.find<SharedPreferences>();
    sp.setBool(_isrealfun, true);
  }

  static bool isAgree() {
    SharedPreferences sp = Get.find<SharedPreferences>();
    return sp.getBool(is_agree) ?? false;
  }

  static saveIsAgree() {
    SharedPreferences sp = Get.find<SharedPreferences>();
    sp.setBool(is_agree, true);
  }

  // 保存播放进度
  static saveProgress(String videoUrl, Duration position) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    sp.setInt("$_progressKey$videoUrl", position.inSeconds);
  }

  // 获取播放进度
  static Duration getProgress(String videoUrl) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    final seconds = sp.getInt("$_progressKey$videoUrl") ?? 0;
    return Duration(seconds: seconds);
  }

  // 保存播放速度（全局）
  static void savePlaySpeed(double speed) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    sp.setDouble(_playSpeedKey, speed);
  }

  static double getPlaySpeed() {
    SharedPreferences sp = Get.find<SharedPreferences>();
    return sp.getDouble(_playSpeedKey) ?? 1.0;
  }

  // 保存播放到多少集
  static saveIndex(RealVideo video, int position) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    sp.setInt("$_progressKey${video.vodId}", position);
  }

  // 获取播放到多少集
  static int? getIndex(String videoId) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    return sp.getInt("$_progressKey$videoId");
  }

  // 保存播放的来源索引
  static saveFromIndex(RealVideo video, int position) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    sp.setInt("$_videoFromProgress${video.vodId}", position);
  }

  // 获取播放的来源索引
  static int? getFromIndex(String videoId) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    return sp.getInt("$_videoFromProgress$videoId");
  }

  // 获取保存的音量
  static double getCurrentVolume() {
    SharedPreferences sp = Get.find<SharedPreferences>();
    return sp.getDouble(_current_volume) ?? 0.1;
  }

  // 保存音量
  static saveVolume(double volume) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    sp.setDouble(_current_volume, volume);
  }

  // 记录跳过片头
  static saveSkipHeadTimes(String videoId, Duration headTime) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    sp.setInt("$_skipHeadKey-$videoId", headTime.inMilliseconds);
  }

  // 记录跳过片尾
  static saveSkipTailTimes(String videoId, Duration tailTime) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    sp.setInt("$_skipTailKey-$videoId", tailTime.inMilliseconds);
  }

  // 获取跳过片头
  static Duration getSkipHeadTimes(String videoId) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    int? headTime = sp.getInt("$_skipHeadKey-$videoId");
    return Duration(milliseconds: headTime ?? 0);
  }

  // 获取跳过片尾
  static Duration getSkipTailTimes(String videoId) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    int? tailTime = sp.getInt("$_skipTailKey-$videoId");
    return Duration(milliseconds: tailTime ?? 0);
  }

  // 清除跳过片头
  static clearSkipHeadTimes(String videoId) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    sp.remove("$_skipHeadKey-$videoId");
  }

  // 清除跳过片尾
  static clearSkipTailTimes(String videoId) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    sp.remove("$_skipTailKey-$videoId");
  }

  // 保存历史记录
  static saveHistory(RealVideo video) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    final historyString = sp.getString(_videoHistory);
    List<Map<String, dynamic>> history = historyString != null
        ? List<Map<String, dynamic>>.from(jsonDecode(historyString))
        : [];
    history.removeWhere((item) => item['vodId'] == video.vodId);
    history.insert(0, video.toJson()); // 新记录放在列表的最前面
    sp.setString(_videoHistory, jsonEncode(history));
  }

  // 获取历史记录
  static List<RealVideo> getHistoryList() {
    SharedPreferences sp = Get.find<SharedPreferences>();
    final historyString = sp.getString(_videoHistory);
    if (historyString == null) {
      return [];
    }
    final history = List<Map<String, dynamic>>.from(jsonDecode(historyString));
    return history.map((item) => RealVideo.fromJson2(item)).toList();
  }

  static removeSingleHistory(RealVideo video) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    final historyString = sp.getString(_videoHistory);
    List<Map<String, dynamic>> history = historyString != null
        ? List<Map<String, dynamic>>.from(jsonDecode(historyString))
        : [];
    history.removeWhere((item) => item['vodId'] == video.vodId);
    sp.setString(_videoHistory, jsonEncode(history));
  }

  static clearHistory() {
    SharedPreferences sp = Get.find<SharedPreferences>();
    List<Map<String, dynamic>> history = [];
    sp.setString(_videoHistory, jsonEncode(history));
  }

  // 获取搜索历史
  static List<String> getSearchHistory() {
    SharedPreferences sp = Get.find<SharedPreferences>();
    return sp.getStringList(_search_key) ?? [];
  }

  // 更新搜索历史
  static freshSearchHistory(List<String> _searchHistory) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    sp.setStringList(_search_key, _searchHistory);
  }

  // 保存指定仓库
  static saveSubscription(List<StorehouseBean> subscriptions) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    // 使用 Set 过滤掉重复 URL
    final uniqueSubscriptions = subscriptions.toSet().toList();
    // 序列化 JSON 并存储
    String jsonString =
        jsonEncode(uniqueSubscriptions.map((e) => e.toJson()).toList());
    sp.setString(_subscriptinKey, jsonString);
  }

  // 获取所有的仓库
  static List<StorehouseBean> getSubscriptions() {
    SharedPreferences sp = Get.find<SharedPreferences>();
    String? jsonString = sp.getString(_subscriptinKey);
    if (jsonString == null) {
      return [];
    }
    List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => StorehouseBean.fromJson(e)).toList();
  }

  // 删除指定仓库
  static removeSubscription(String name) {
    List<StorehouseBean> subscriptions = getSubscriptions();
    var storehouseBean = SPManager.getCurrentSubscription();

    // 如果删除的仓库是当前正在使用的，要把站点清掉
    if (storehouseBean?.name == name) {
      cleanCurrentSite();
      cleanCurrentSubscription();
    }
    subscriptions.removeWhere((item) {
      return item.name == name;
    });
    saveSubscription(subscriptions);
  }

  // 获取当前选择的仓库
  static StorehouseBean? getCurrentSubscription() {
    SharedPreferences sp = Get.find<SharedPreferences>();
    String? jsonString = sp.getString(_currentSubscriptinKey);
    if (jsonString != null) {
      Map<String, dynamic> scriptionMap = jsonDecode(jsonString);
      return StorehouseBean.fromJson(scriptionMap);
    }
    return null;
  }

  // 记录当前选择的仓库
  static saveCurrentSubscription(StorehouseBean storehouseBean) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    String storehouseJson =
        jsonEncode(storehouseBean.toJson()); // 序列化为 JSON 字符串
    sp.setString(_currentSubscriptinKey, storehouseJson);
  }

  // 记录当前的站点
  static saveCurrentSite(StorehouseBeanSites site) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    String siteJson = jsonEncode(site.toJson()); // 序列化为 JSON 字符串
    sp.setString(_currentSitetinKey, siteJson);
  }

  // 获取当前的站点
  static StorehouseBeanSites? getCurrentSite() {
    SharedPreferences sp = Get.find<SharedPreferences>();
    String? siteJson = sp.getString(_currentSitetinKey);
    if (siteJson != null) {
      Map<String, dynamic> siteMap = jsonDecode(siteJson);
      return StorehouseBeanSites.fromJson(siteMap);
    }
    return null;
  }

  // 清理当前仓库
  static cleanCurrentSubscription() {
    SharedPreferences sp = Get.find<SharedPreferences>();
    sp.remove(_currentSubscriptinKey);
  }

  // 清除当前站点
  static cleanCurrentSite() {
    SharedPreferences sp = Get.find<SharedPreferences>();
    sp.remove(_currentSitetinKey);
  }

  // 保存解析的视频资源
  static saveParesVideo(ParesVideo videoData) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    var pareHisList = getParesVideoHisList();
    pareHisList.removeWhere((item) => item.vodPlayUrl == videoData.vodPlayUrl);
    pareHisList.insert(0, videoData); // 新记录放在列表的最前面
    sp.setString(_pares_url_video, jsonEncode(pareHisList));
  }

  //  获取解析的视频资源集合
  static List<ParesVideo> getParesVideoHisList() {
    SharedPreferences sp = Get.find<SharedPreferences>();
    final paresHisList = sp.getString(_pares_url_video);
    if (paresHisList == null) {
      return [];
    }
    final history = List<Map<String, dynamic>>.from(jsonDecode(paresHisList));
    return history.map((item) => ParesVideo.fromJson2(item)).toList();
  }

  //  删除单条记录
  static removeParesItem(ParesVideo videoData) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    var pareHisList = getParesVideoHisList();
    pareHisList.removeWhere((item) => videoData.vodPlayUrl == item.vodPlayUrl);
    sp.setString(_pares_url_video, jsonEncode(pareHisList));
  }

  static selectThemeData(String themeKey) {
    Get.find<SharedPreferences>().setString(selectedTheme, themeKey);
  }

  static String getThemeData() {
    return Get.find<SharedPreferences>().getString(selectedTheme) ?? "浅色";
  }

  static double getLongPressSpeed() {
    return Get.find<SharedPreferences>().getDouble(longPressSpeed) ?? 3.0;
  }

  static void setLongPressSpeed(double speed) {
    Get.find<SharedPreferences>().setDouble(longPressSpeed, speed);
  }
}
