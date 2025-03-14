import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lemon_tv/http/HttpService.dart';
import 'package:lemon_tv/util/CommonUtil.dart';

import '../http/data/SubscripBean.dart';
import '../http/data/storehouse_bean_entity.dart';
import 'SPManager.dart';

class SubscriptionsUtil {
  static final SubscriptionsUtil _instance = SubscriptionsUtil._internal();
  late final HttpService _httpService = HttpService();

  factory SubscriptionsUtil() => _instance;

  SubscriptionsUtil._internal();

  Map<String, List<StorehouseBeanSites>> siteMap = {};

  List<StorehouseBeanSites> selectStorehouse = [];

  Future<Map<String, List<StorehouseBeanSites>>> requestSubscription(
      String subscripName, String subscripUrl) async {
    if (containsChinese(subscripUrl)) {
      CommonUtil.showToast("暂不支持含中文的接口");
      return siteMap;
    }
    Map<String, dynamic> jsonMap = await _httpService.getUrl(subscripUrl);
    if (jsonMap['urls'] != null) {
      var subscripBean = SubscripBean.fromJson(jsonMap);
      var urls = subscripBean.urls;
      await SPManager.saveSubscription(urls);
      for (var value in urls) {
        var url = value.url;
        var name = value.name;
        try {
          if (containsChinese(url)) {
            // 暂不支持含中文的接口
            CommonUtil.showToast("暂不支持含中文的接口");
            // url = _toPunycode("http://www.饭太硬.com/tv");
            print("SubscriptionsUtil trans url = $url");
            continue;
          } else {
            Map<String, dynamic> jsonMap = await _httpService.getUrl(url);
            await getSingleSubscription(jsonMap, name);
          }
        } catch (e) {
          print("Lemon Error processing URL ${value.url}: $e");
        }
      }
    } else {
      List<StorehouseBean> singleUrls = [];
      var storehouseBean = StorehouseBean(url: subscripUrl, name: subscripName);
      singleUrls.add(storehouseBean);
      await SPManager.saveSubscription(singleUrls);
      await getSingleSubscription(jsonMap, subscripName);
    }
    var currentSite = await SPManager.getCurrentSite();
    if (siteMap.isNotEmpty) {
      // 从 siteMap 中获取第一个 name 对应的站点列表
      var firstSiteList = siteMap.values.first;
      if (firstSiteList.isNotEmpty) {
        selectStorehouse = firstSiteList;
        // 取第一个站点
        if (currentSite == null) {
          var currentSite = firstSiteList.first;
          await SPManager.saveCurrentSite(currentSite);
          setCurrentSite(currentSite);
          HttpService.updateBaseUrl(currentSite.api);
        }
      }
    }
    return siteMap;
  }

  Future<Map<String, List<StorehouseBeanSites>>> requestCurrentSubscrip(
      StorehouseBean currentStorehouse) async {
    if (containsChinese(currentStorehouse.url)) {
      CommonUtil.showToast("暂不支持含中文的接口");
      return siteMap;
    }
    Map<String, dynamic> jsonMap =
        await _httpService.getUrl(currentStorehouse.url);
    await getSingleSubscription(jsonMap, currentStorehouse.name);
    return siteMap;
  }

  Future<void> getSingleSubscription(
      Map<String, dynamic> jsonMap, String name) async {
    var storehouseBeanEntity = StorehouseBeanEntity.fromJson(jsonMap);
    var siteList = storehouseBeanEntity.sites;
    selectStorehouse = siteList;
    var currentSite = await SPManager.getCurrentSite();
    if (currentSite == null&&selectStorehouse.isNotEmpty) {
      SPManager.saveCurrentSite(selectStorehouse[0]);
    }
  }

  bool containsChinese(String domain) {
    // 正则表达式检查中文字符
    RegExp regExp = RegExp(r'[\u4e00-\u9fff]');
    return regExp.hasMatch(domain);
  }

  Future<void> setCurrentSite(StorehouseBeanSites site) async {
    await SPManager.saveCurrentSite(site);
  }

  String _toPunycode(String input) {
    // 使用dart:convert包提供的 ascii编码和utf8转换
    List<int> ascii = utf8.encode(input); // 确保在使用前定义了 ascii 变量
    return ascii.map((e) => String.fromCharCode(e)).join();
  }

  static void paresStorehouse(StorehouseBean storehouseBean) {}
}
