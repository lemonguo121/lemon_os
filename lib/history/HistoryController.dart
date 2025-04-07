import 'package:get/get.dart';
import 'package:lemon_tv/util/CommonUtil.dart';
import 'package:lemon_tv/util/SPManager.dart';

import '../http/data/RealVideo.dart';

class HistoryController extends GetxController {
  final RxList<RealVideo> _historyList = <RealVideo>[].obs;
  final RxMap<String, String> _videoTitles = <String, String>{}.obs;

  // 提供一个 getter，方便 UI 访问
  List<RealVideo> get historyList => _historyList;

  Map<String, String> get videoTitles => _videoTitles;

  // 初始化历史记录
  Future<void> initList() async {
    List<RealVideo> list = await SPManager.getHistoryList();
    _historyList.assignAll(list);
    await Future.wait(list.map((video) => freshVideoIndex(video)));
  }

  Future<void> freshVideoIndex(RealVideo video) async {
    int playIndex = await SPManager.getIndex("${video.vodId}") ?? 0;
    int fromIndex = await SPManager.getFromIndex("${video.vodId}") ?? 0;
    var playList = CommonUtil.getPlayListAndForm(video).playList;

    _videoTitles["${video.vodId}"] =
        (fromIndex >= 0 && fromIndex < playList.length)
            ? playList[fromIndex][playIndex]['title']!
            : "";
    _videoTitles.refresh();
  }

  // 保存历史记录
  void saveHistory(RealVideo video) {
    _historyList.removeWhere((element) => element.vodId == video.vodId);
    _historyList.insert(0, video);
    // 延迟更新，避免在 build 过程中触发 UI 更新
    _historyList.refresh();
    SPManager.saveHistory(video);
  }

  // 清空历史记录
  void cleanHistory() {
    _historyList.clear();
    _historyList.refresh();
    SPManager.clearHistory();
  }

  // 移除单条记录
  void removeHistoryItem(RealVideo video) {
    _historyList.removeWhere((element) => element.vodId == video.vodId);
    _historyList.refresh();
    SPManager.removeSingleHistory(video);
  }

  Future<void> saveIndex(
      RealVideo video, int position, int selectedPlayFromIndex) async {
    await SPManager.saveFromIndex(video, selectedPlayFromIndex);
    await SPManager.saveIndex(video, position);
    await freshVideoIndex(video);
  }
}
