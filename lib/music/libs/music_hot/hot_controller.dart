import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../music_http/music_http_rquest.dart';
import '../../music_utils/MusicSPManage.dart';
import 'hot_model/hot_Model.dart';

class HotController extends GetxController
    with GetSingleTickerProviderStateMixin {
  ///热门首页
  late TabController tabController;
  var data = <TopListGroup>[].obs;
  var tabs = <TopListItem>[].obs;
  var isLoading = false.obs;

  Future<void> getHotBannerList({String? query}) async {
    isLoading.value = true;
    try {
      var currentSite = MusicSPManage.getCurrentSite();
      final response = await NetworkManager().get('/getTopLists',
          queryParameters: {
            'id': 'new',
            'plugin': currentSite?.platform ?? ""
          });

      final dataResponse = response.data;
      data.value =
          (dataResponse as List).map((e) => TopListGroup.fromJson(e)).toList();
      final items = data.expand((e) => e.data).toList();
      tabs.value = items;

      tabController = TabController(length: tabs.length, vsync: this);
    } catch (e) {
      print('搜索失败：$e');
    } finally {
      isLoading.value = false;
    }
  }

  ///热门分页
  Rx<HotSubModel> subModel = HotSubModel().obs;

  Future<void> getHotList({String? id}) async {
    isLoading.value = true;
    try {
      final response = await NetworkManager().get('/getTopListDetail',
          queryParameters: {
            'id': id,
            'plugin': MusicSPManage.getCurrentSite()?.platform ?? ""
          });
      final dataResponse = response.data;
      subModel.value = HotSubModel.fromJson(dataResponse);
      isLoading.value = false;

    } catch (e) {
      print("搜索失败：$e");
    } finally {
      isLoading.value = false;
    }
  }
}
