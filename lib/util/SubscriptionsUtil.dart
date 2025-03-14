import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lemon_tv/http/HttpService.dart';
import 'package:lemon_tv/util/CommonUtil.dart';

import '../http/data/SubscripBean.dart';
import '../http/data/storehouse_bean_entity.dart';
import 'SPManager.dart';
import 'AESUtil.dart';
import 'package:punycode_converter/punycode_converter.dart';

class SubscriptionsUtil {
  static final SubscriptionsUtil _instance = SubscriptionsUtil._internal();
  late final HttpService _httpService = HttpService();

  factory SubscriptionsUtil() => _instance;

  SubscriptionsUtil._internal();

  Map<String, List<StorehouseBeanSites>> siteMap = {};

  List<StorehouseBeanSites> selectStorehouse = [];

  Future<Map<String, List<StorehouseBeanSites>>> requestSubscription(
      String subscripName, String url) async {
    var subscripUrl = url;
    if (containsChinese(subscripUrl)) {
      subscripUrl = _toPunycode(subscripUrl);
    }
    List<StorehouseBean> urls = [];
    Map<String, dynamic> jsonMap = await _httpService.getUrl(subscripUrl);
    if (jsonMap['urls'] != null) {
      var subscripBean = SubscripBean.fromJson(jsonMap);

      urls.addAll(subscripBean.urls);
      await SPManager.saveSubscription(urls);
      // for (var value in urls) {
      //   var url = value.url;
      //   var name = value.name;
      //   try {
      //     if (containsChinese(url)) {
      //       url = _toPunycode(url);
      //       print("_toPunycode  url = $url");
      //     }
      //     Map<String, dynamic> jsonMap = await _httpService.getUrl(url);
      //     await getSingleSubscription(jsonMap, name);
      //   } catch (e) {
      //     print("Lemon Error processing URL ${value.url}: $e");
      //   }
      // }
    } else {
      var storehouseBean = StorehouseBean(url: subscripUrl, name: subscripName);
      urls.add(storehouseBean);
      await SPManager.saveSubscription(urls);
      // await getSingleSubscription(jsonMap, subscripName);
    }
    var currentSite = await SPManager.getCurrentSite();
    if (siteMap.isNotEmpty) {
      // 从 siteMap 中获取第一个 name 对应的站点列表
      var firstSiteList = siteMap.values.first;
      if (firstSiteList.isNotEmpty) {
        selectStorehouse = firstSiteList;
        // 取第一个站点
        if (currentSite == null) {
          SPManager.saveCurrentSubscription(urls[0]);
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
    if (currentSite == null && selectStorehouse.isNotEmpty) {
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
    var uri = Uri.parse(input);
    return uri.punyEncoded.toString();
  }

  /// 解析加密内容
  String findResult(String json, String? configKey) {
    String content = json;
    try {
      if (AESUtil.isJson(content)) return content;

      RegExp pattern = RegExp(r'[A-Za-z0]{8}\*\*');
      Match? match = pattern.firstMatch(content);
      if (match != null) {
        content = content.substring(content.indexOf(match.group(0)!) + 10);
        content = utf8.decode(base64.decode(content));
      }

      if (content.startsWith("2423")) {
        String data =
            content.substring(content.indexOf("2324") + 4, content.length - 26);
        content = utf8
            .decode(Uint8List.fromList(AESUtil.fromHex(content)))
            .toLowerCase();

        String key = AESUtil.rightPadding(
            content.substring(
                content.indexOf("\$#") + 2, content.indexOf("#\$")),
            "0",
            16);
        String iv = AESUtil.rightPadding(
            content.substring(content.length - 13), "0", 16);

        json = AESUtil.decryptCBC(data, key, iv) ?? json;
      } else if (configKey != null && !AESUtil.isJson(content)) {
        json = AESUtil.decryptECB(content, configKey) ?? json;
      } else {
        json = content;
      }
    } catch (e) {
      print("Error: $e");
    }
    return json;
  }
}
