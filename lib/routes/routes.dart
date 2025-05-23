import 'dart:io';

import 'package:get/get.dart';
import 'package:lemon_tv/detail/DetailScreen.dart';
import 'package:lemon_tv/download/DownloadPage.dart';
import 'package:lemon_tv/music/playlist/PlayListPage.dart';
import 'package:lemon_tv/search/SearchScreen.dart';
import 'package:lemon_tv/subscrip/PluginsPage.dart';
import 'package:lemon_tv/subscrip/SubscriptionPage.dart';

import '../download/DownloadItem.dart';
import '../download/EpisodeListPage.dart';
import '../home/HomeScreen.dart';
import '../http/data/storehouse_bean_entity.dart';
import '../mine/SettingPage.dart';
import '../music/data/PlayRecordList.dart';
import '../music/music_hot/HotDetailPage.dart';
import '../music/music_hot/hot_model/hot_Model.dart';
import '../music/player/widget/music_play.dart';
import '../music/search/widget/music_search.dart';
import '../player/LocalVideoPlayerPage.dart';

abstract class Routes {
  /// 影视首页
  static const String movieHomePage = '/movieHome';
  static const String localVideoPage = '/localVideoPage';

  /// 详情页
  static const String detailPage = '/detail';

//   搜索页
  static const String searchPage = '/search';

//   订阅管理页
  static const String subscripPage = '/subscrip';

//   设置页
  static const String settingPage = '/setting';

  //插件页
  static const String pluginsPage = '/plugins';

  // 播放器页
  static const String musicPlayer = '/musicPlayer';

  // 音乐搜索
  static const String musicSearchPage = '/musicSearchPage';

  // 榜单详情
  static const String musicHotDetalPage = '/hotDetal';

  // 榜单列表
  static const String musicHotListPage = '/hotListPage';

  // 播放列表
  static const String musicPlayListPage = '/PlayListPage';

  // 下载页
  static const String downloadPage = '/downloadPage';

  static const String episodeList = '/episodeList';

  static goMovieHomelPage() {
    Get.toNamed(movieHomePage);
  }

  static goDetailPage(String vodId, StorehouseBeanSites site, int playIndex) {
    Get.toNamed(detailPage,
        arguments: {'vodId': vodId, 'site': site, 'playIndex': playIndex});
  }

  static goSearchPage(String query) {
    Get.toNamed(searchPage, arguments: {'query': query});
  }

  static goSubscripPage() {
    Get.toNamed(subscripPage);
  }

  static goSettingPage() {
    Get.toNamed(settingPage);
  }

  static goPluginPage() {
    Get.toNamed(pluginsPage);
  }

  static goMusicPage() {
    Get.toNamed(musicPlayer);
  }

  static goMusicSearchPage() {
    Get.toNamed(musicSearchPage);
  }

  static goHotDetaiPage(TopListItem topListItem) {
    Get.toNamed(musicHotDetalPage, arguments: {'topListItem': topListItem});
  }

  static goHotListPage() {
    Get.toNamed(musicHotListPage);
  }

  static goPlayListPage(PlayRecordList record) {
    Get.toNamed(musicPlayListPage, arguments: {'record': record});
  }

  static goDownloadPage() {
    Get.toNamed(downloadPage);
  }

  static Future<bool?> goLocalVideoPage(String vodId, int playIndex) async {
    final result = await Get.toNamed(localVideoPage, arguments: {
      'vodId': vodId,
      'playIndex': playIndex,
    });

    return result as bool?;
  }


  static goEpisodeListPage(String vodName) {
    Get.toNamed(episodeList, arguments: {'vodName': vodName});
  }

  static final routePage = [
    GetPage(name: movieHomePage, page: () => MovieHomeScreen()),
    GetPage(name: localVideoPage, page: () => LocalVideoPlayerPage()),
    GetPage(name: detailPage, page: () => DetailScreen()),
    GetPage(name: searchPage, page: () => SearchScreen()),
    GetPage(name: subscripPage, page: () => SubscriptionPage()),
    GetPage(name: settingPage, page: () => SettingPage()),
    GetPage(name: pluginsPage, page: () => PluginsPage()),
    GetPage(name: musicPlayer, page: () => MusicPlayerPage()),
    GetPage(name: musicSearchPage, page: () => MusicSearchPage()),
    GetPage(name: musicHotDetalPage, page: () => HotDetailPage()),
    GetPage(name: musicPlayListPage, page: () => PlayListPage()),
    GetPage(name: downloadPage, page: () => DownloadPage()),
    GetPage(name: episodeList, page: () => EpisodeListPage()),
  ];
}
