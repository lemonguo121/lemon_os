import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../util/SubscriptionsUtil.dart';
import '../../data/PluginBean.dart';
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
  final SubscriptionsUtil subscriptionsUtil = SubscriptionsUtil();
  Rx<PluginInfo> currentSite =
      PluginInfo(platform: "", name: "", plugin: "").obs;
  var errorType = (-1).obs; //0:作为成功；1：订阅为空；2:站点不可用；
  var selecteSitedIndex = (0).obs;
  var tabIndex = 0.obs;

  Future<void> loadSite() async {
    // 第一步先检查当前是否有选择的仓库
    isLoading.value = true;
    var currentStorehouse = MusicSPManage.getCurrentSubscription();
    if (currentStorehouse == null) {
      errorType.value = 1;
      return;
    }
    var siteResponse = null;
    // 第二步，根据当前的仓库去请求仓库下的站点
    try {
      siteResponse =
          await subscriptionsUtil.requestMusicCurrentSites(currentStorehouse);
    } catch (e) {
      siteResponse = null;
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
    getHotBannerList();
  }

  Future<void> getHotBannerList() async {
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
    } on DioException catch (e) {
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
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
      final response = await NetworkManager().get(
        '/getTopListDetail',
        queryParameters: {
          'id': id,
          'plugin': MusicSPManage.getCurrentSite()?.platform ?? ""
        },
      );
      final dataResponse = response.data;
      subModel.value = HotSubModel.fromJson(dataResponse);
    } on DioException catch (e) {
      isLoading.value = false;
    } catch (e) {
      print("未知错误: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
