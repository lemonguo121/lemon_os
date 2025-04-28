import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

import '../../../util/SubscriptionsUtil.dart';
import '../../music_http/data/PluginBean.dart';
import '../../music_http/music_http_rquest.dart';
import '../../music_utils/MusicSPManage.dart';

class SearchControll extends GetxController {
  var isLoading = true.obs;
  var errorType = (-1).obs; //0:作为成功；1：订阅为空；2:站点不可用；
  final SubscriptionsUtil subscriptionsUtil = SubscriptionsUtil();
  Rx<PluginInfo> currentSite =
      PluginInfo(platform: "", name: "", plugin: "").obs;

  var songs = <dynamic>[].obs;
  RxList<String> searchHistory = <String>[].obs;
  var showHistory = false.obs;

  void loadSite() async {
    // 第一步先检查当前是否有选择的仓库
    isLoading.value = true;
    var currentStorehouse = MusicSPManage.getCurrentSubscription();
    if (currentStorehouse == null) {
      errorType.value = 1;
      return;
    }
    var siteResponse =null;
    // 第二步，根据当前的仓库去请求仓库下的站点
    try {
       siteResponse =
              await subscriptionsUtil.requestMusicCurrentSites(currentStorehouse);
    } catch (e) {
      siteResponse=null;
      print(e);
    } finally {
      isLoading.value = false;
    }
    if (siteResponse == null) {
      errorType.value = 2;
      isLoading.value = false;
      return;
    }
    currentSite.value = siteResponse;
    isLoading.value = false;
  }

  Future<void> searchSongs({String? query}) async {
    if (query == null || query.isEmpty == true) return;
    isLoading.value = true;
    songs.value = [];
    showHistory.value = false;

    try {
      var currentSite = MusicSPManage.getCurrentSite();
      final response = await NetworkManager().get('/search', queryParameters: {
        'query': query,
        'plugin': currentSite?.platform ?? ""
      });

      final data = response.data;
      songs.value = data['data'] ?? [];
      // 添加到搜索历史，不重复
      if (!searchHistory.contains(query)) {
        searchHistory.insert(0, query);
        saveSearchHistory(searchHistory.value); // 更新历史记录
      }
    } catch (e) {
      print('搜索失败：$e');
    } finally {
      isLoading.value = false;
    }
  }

  void saveSearchHistory(List<String> searchHistory) {
    MusicSPManage.saveSearchHistory(searchHistory);
  }

  void loadSearchHistory() async {
    searchHistory.value = MusicSPManage.getSearchHistory();
  }
}
