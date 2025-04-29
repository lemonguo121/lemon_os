import 'dart:convert';

import 'package:get/get.dart';
import 'package:lemon_tv/music/data/MusicBean.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../http/data/SubscripBean.dart';
import '../music_http/data/PluginBean.dart';

class MusicSPManage {
  static const String music_plugins = "music_plugins";
  static const String music_current_plugins = "music_current_plugins";
  static const String music_currentSitetinKey = "music_currentSitetinKey";
  static const String music_search_history = "music_search_history";
  static const String music_play_list = "music_play_list";//所有记录相关前缀
  static const String history = "_history";//播放记录名字
  static const String collect = "_collect";//收藏列表


  // 保存指定仓库
  static saveSubscription(List<StorehouseBean> subscriptions) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    // 使用 Set 过滤掉重复 URL
    final uniqueSubscriptions = subscriptions.toSet().toList();
    // 序列化 JSON 并存储
    String jsonString =
        jsonEncode(uniqueSubscriptions.map((e) => e.toJson()).toList());
    sp.setString(music_plugins, jsonString);
  }

  // 获取所有的仓库
  static List<StorehouseBean> getSubscriptions() {
    SharedPreferences sp = Get.find<SharedPreferences>();
    String? jsonString = sp.getString(music_plugins);
    if (jsonString == null) {
      return [];
    }
    List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => StorehouseBean.fromJson(e)).toList();
  }

  // 删除指定仓库
  static removeSubscription(String name) {
    List<StorehouseBean> subscriptions = getSubscriptions();
    subscriptions.removeWhere((item) {
      return item.name == name;
    });
    saveSubscription(subscriptions);
  }

  // 获取当前选择的仓库
  static StorehouseBean? getCurrentSubscription() {
    SharedPreferences sp = Get.find<SharedPreferences>();
    String? jsonString = sp.getString(music_current_plugins);
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
    sp.setString(music_current_plugins, storehouseJson);
  }

  // 记录当前的站点
  static saveCurrentSite(PluginInfo site) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    String siteJson = jsonEncode(site.toJson()); // 序列化为 JSON 字符串
    sp.setString(music_currentSitetinKey, siteJson);
  }

  //
  // // 获取当前的站点
  static PluginInfo? getCurrentSite() {
    SharedPreferences sp = Get.find<SharedPreferences>();
    String? siteJson = sp.getString(music_currentSitetinKey);
    if (siteJson != null) {
      Map<String, dynamic> siteMap = jsonDecode(siteJson);
      return PluginInfo.fromJson(siteMap);
    }
    return null;
  }

  //
  // // 清除当前站点
  static cleanCurrentSite() {
    SharedPreferences sp = Get.find<SharedPreferences>();
    sp.remove(music_currentSitetinKey);
  }

  // 保存搜索历史记录
  static saveSearchHistory(List<String> searchHistory) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    sp.setStringList(music_search_history, searchHistory);
  }

  // 加载搜索历史记录
  static List<String> getSearchHistory() {
    SharedPreferences sp = Get.find<SharedPreferences>();
    return sp.getStringList(music_search_history) ?? [];
  }

  // 存储某个类型播放历史记录
  static savePlayList(List<MusicBean> playList, String listName) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    // 使用 Set 过滤掉重复 URL
    final uniquePlayList = playList.toSet().toList();
    // 序列化 JSON 并存储
    String jsonString =
        jsonEncode(uniquePlayList.map((e) => e.toJson()).toList());
    sp.setString('$music_play_list$listName', jsonString);
  }

  // 获取某个类型播放历史记录
  static List<MusicBean> getPlayList(String listName) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    String? jsonString = sp.getString('$music_play_list$listName');
    if (jsonString == null) {
      return [];
    }
    List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => MusicBean.fromJson(e)).toList();
  }

  // 删除某个类型单条记录
  static deleteSingleSong(String id, String listName) {
    var playlist = getPlayList(listName);
    // 根据 id 过滤掉要删除的歌曲
    playlist.removeWhere((song) => song.songBean.id == id);
    savePlayList(playlist, listName);
  }


// 删除某个类型所有播放记录
  static void clearAllSongs(String listName) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    sp.remove('$music_play_list$listName');
  }
}
