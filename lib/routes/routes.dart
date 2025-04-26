import 'package:get/get.dart';
import 'package:lemon_tv/detail/DetailScreen.dart';
import 'package:lemon_tv/search/SearchScreen.dart';
import 'package:lemon_tv/subscrip/SubscriptionPage.dart';

import '../http/data/storehouse_bean_entity.dart';
import '../mine/SettingPage.dart';
import '../music/libs/music_play.dart';

abstract class Routes {
  /// 详情页
  static const String detailPage = '/detail';

//   搜索页
  static const String searchPage = '/search';

//   订阅管理页
  static const String subscripPage = '/subscrip';

//   设置页
  static const String settingPage = '/setting';

  static goDetailPage(String vodId, StorehouseBeanSites site) {
    Get.toNamed(detailPage, arguments: {'vodId': vodId, 'site': site});
  }

  static goSearchPage(String query) {
    Get.toNamed(searchPage, arguments: {'query': query});
  }

  static goSubscripPage(){
    Get.toNamed(subscripPage);
  }

  static goSettingPage(){
    Get.toNamed(settingPage);
  }
  static final routePage = [
    GetPage(name: detailPage, page: () => DetailScreen()),
    GetPage(name: searchPage, page: () => SearchScreen()),
    GetPage(name: subscripPage, page: () => SubscriptionPage()),
    GetPage(name: settingPage, page: () => SettingPage()),
  ];
}
