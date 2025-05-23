import 'dart:convert';
import 'dart:core';

import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lemon_tv/music/data/MusicBean.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../http/data/SubscripBean.dart';
import '../data/PlayRecordList.dart';
import '../data/PluginBean.dart';

class MusicSPManage {
  static const String music_plugins = "music_plugins";
  static const String music_current_plugins = "music_current_plugins";
  static const String music_currentSitetinKey = "music_currentSitetinKey";
  static const String music_search_history = "music_search_history";
  static const String music_play_list = "music_play_list"; //所有记录相关前缀
  static const String history = "_history"; //播放记录名字
  static const String collect = "_collect"; //收藏列表
  static const String music_play_index = "music_play_index"; //播放索引
  static const String music_play_type =
      "music_play_type"; //播放类型  是收藏还是历史 或者自己建的播放列表
  static const String music_play_record = "music_play_record"; //播放列表
  static const String music_customize = "customize"; //自定义文件名前缀
  static const String music_play_mode_key = 'music_play_mode'; // 播放模式key
  static const String music_volume = 'music_volume'; // 音量key

  // 获取当前的音乐媒体音量
  static double getCurrentVolume() {
    SharedPreferences sp = Get.find<SharedPreferences>();
    return sp.getDouble(music_volume) ?? 1.0;
  }

  // 保存当前音量
  static saveCurrentVolume(double volume) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    return sp.setDouble(music_volume, volume);
  }

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
  static List<MusicBean> getPlayList(String listKey) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    String? jsonString = sp.getString('$music_play_list$listKey');
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

  //记录某个类型列表下的播放索引
  static void saveCurrentPlayIndex(String listName, int playIndex) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    sp.setInt('$music_play_index$listName', playIndex);
  }

  // 获取某个类型下的播放索引
  static int getCurrentPlayIndex(String listName) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    return sp.getInt('$music_play_index$listName') ?? 0;
  }

  // 获取当前的播放类型
  static PlayRecordList getCurrentPlayType() {
    SharedPreferences sp = Get.find<SharedPreferences>();
    String? typeJson = sp.getString(music_play_type);
    if (typeJson != null) {
      Map<String, dynamic> typeMap = jsonDecode(typeJson);
      return PlayRecordList.fromJson(typeMap);
    }
    return PlayRecordList(name: '播放记录', key: history, canDelete: false);
  }

  //保存当前的播放类型
  static void saveCurrentPlayType(PlayRecordList playRecordList) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    String typeJson = jsonEncode(playRecordList);
    sp.setString(music_play_type, typeJson);
  }

  // 获取当前的播放模式
  static LoopMode getCurrentPlayMode() {
    SharedPreferences sp = Get.find<SharedPreferences>();
    int index = sp.getInt(music_play_mode_key) ?? 0; //
    return LoopMode.values[index];
  }

  // 保存当前的播放模式
  static void saveCurrentPlayMode(LoopMode mode) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    sp.setInt(music_play_mode_key, mode.index);
  }

// 获取当前音乐是否被收藏
  static bool isCollected(String songId) {
    List<MusicBean> collectList = getPlayList(collect);
    return collectList.any((model) => model.songBean.id == songId);
    // for (var model in collectList){
    //   if (model.songBean.id == songId){
    //     return true;
    //   }
    // }
    // return false;
  }

//   获取所有的播放列表
  static List<PlayRecordList> getRecordList() {
    SharedPreferences sp = Get.find<SharedPreferences>();
    String? jsonString = sp.getString(music_play_record);
    if (jsonString == null) {
      // 如果为空，创建默认两个播放列表 记录和收藏
      List<PlayRecordList> list = [];
      list.add(PlayRecordList(name: '播放记录', key: history, canDelete: false));
      list.add(PlayRecordList(name: '我的收藏', key: collect, canDelete: false));
      saveRecordList(list);
      return list;
    }
    List<dynamic> jsonList = jsonDecode(jsonString);
    List<PlayRecordList> list =
        jsonList.map((e) => PlayRecordList.fromJson(e)).toList();
    return list;
  }

  // 更新播放列表
  static void saveRecordList(List<PlayRecordList> list) {
    SharedPreferences sp = Get.find<SharedPreferences>();
    // 使用 Set 过滤掉重复 URL
    final uniqueList = list.toSet().toList();
    // 序列化 JSON 并存储
    String jsonString = jsonEncode(uniqueList.map((e) => e.toJson()).toList());
    sp.setString(music_play_record, jsonString);
  }

//   添加自定义播放列表
  static void addRecordList(String listName) {
    var list = getRecordList();
    int timestampMillis = DateTime.now().millisecondsSinceEpoch;
    var record = PlayRecordList(
        name: listName,
        key: '${music_customize}_$timestampMillis',
        canDelete: true);
    list.add(record);
    saveRecordList(list);
  }

  // 删除指定播放列表
  static void removeRecordList(String key) {
    var list = getRecordList();
    list.removeWhere((item) => item.key == key);
    clearAllSongs(key);
    saveRecordList(list);
  }
}
