import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

import '../../../util/SubscriptionsUtil.dart';
import '../../data/PluginBean.dart';
import '../../music_http/music_http_rquest.dart';
import '../../music_utils/MusicSPManage.dart';

class SearchControll extends GetxController {
  var isLoading = false.obs;

  final SubscriptionsUtil subscriptionsUtil = SubscriptionsUtil();

  var songs = <dynamic>[].obs;
  RxList<String> searchHistory = <String>[].obs;
  var showHistory = false.obs;
  var searchType = 'music'.obs;

  Future<void> searchMusic(String? query) async {
    if (query == null || query.isEmpty == true) return;
    isLoading.value = true;
    songs.value = [];
    showHistory.value = false;
    try {
      var currentSite = MusicSPManage.getCurrentSite();
      final response = await NetworkManager().get('/search', queryParameters: {
        'query': query,
        'plugin': currentSite?.platform ?? "",
        'type': searchType.value
      });

      final data = response.data;
      songs.value = data['data'] ?? [];
      // 添加到搜索历史，不重复
      if (!searchHistory.contains(query)) {
        searchHistory.insert(0, query);
        saveSearchHistory(searchHistory); // 更新历史记录
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
