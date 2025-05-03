import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../../util/SubscriptionsUtil.dart';
import '../data/PlayRecordList.dart';
import '../data/PluginBean.dart';
import '../music_hot/hot_model/hot_Model.dart';
import '../music_http/music_http_rquest.dart';
import '../music_utils/MusicSPManage.dart';

class MusicHomeController extends GetxController
    with GetSingleTickerProviderStateMixin {
  var tabs = <TopListItem>[].obs;
  var isLoading = false.obs;
  final SubscriptionsUtil subscriptionsUtil = SubscriptionsUtil();
  Rx<PluginInfo> currentSite =
      PluginInfo(platform: "", name: "", plugin: "").obs;
  var errorType = (-1).obs; //0:作为成功；1：订阅为空；2:站点不可用；
  var selecteSitedIndex = (0).obs;

  var isColled = false.obs;
  List<PlayRecordList> recordList = <PlayRecordList>[].obs;

  Future<void> loadSite() async {
    isLoading.value = true;

    var currentStorehouse = MusicSPManage.getCurrentSubscription();
    if (currentStorehouse == null) {
      errorType.value = 1;
      isLoading.value = false;
      return;
    }

    PluginInfo? siteResponse;
    try {
      siteResponse =
          await subscriptionsUtil.requestMusicCurrentSites(currentStorehouse);
    } on DioException catch (e) {
      print('网络异常：$e');
    } catch (e) {
      print('其他异常：$e');
    } finally {
      isLoading.value = false;
    }
    if (siteResponse == null) {
      errorType.value = 2;
      return;
    }
    errorType.value = 0;
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
      var data =
          (dataResponse as List).map((e) => TopListGroup.fromJson(e)).toList();
      final items = data.expand((e) => e.data).toList();
      tabs.value = items;
    } on DioException catch (e) {
      print('请求失败：$e');
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

  void checkIsColled(TopListItem? topListItem) {
    isColled.value = recordList.any((e) => e.key == topListItem?.id);
  }

  void getRordList() {
    recordList = MusicSPManage.getRecordList();
  }
}
