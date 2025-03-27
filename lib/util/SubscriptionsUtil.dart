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
    print("subscripUrl result $subscripUrl");
    List<StorehouseBean> urls = await SPManager.getSubscriptions();
    Map<String, dynamic> jsonMap = await _httpService.getUrl(subscripUrl);
    if (jsonMap['urls'] != null) {
      var subscripBean = SubscripBean.fromJson(jsonMap);
      urls.addAll(subscripBean.urls);
      urls = urls
          .fold<Map<String, StorehouseBean>>({}, (map, item) {
            map[item.url] = item;
            return map;
          })
          .values
          .toList();
      await SPManager.saveSubscription(urls);
    } else {
      var storehouseBean = StorehouseBean(url: subscripUrl, name: subscripName);
      if (!urls.contains(storehouseBean)) {
        urls.add(storehouseBean);
      }
      await SPManager.saveSubscription(urls);
    }

    return siteMap;
  }

  // 根据仓库，请求仓库下所有站点
  Future<StorehouseBeanSites?> requestCurrentSites(
      StorehouseBean currentStorehouse) async {
    var url = currentStorehouse.url;
    if (containsChinese(currentStorehouse.url)) {
      // CommonUtil.showToast("暂不支持含中文的接口");
      // return null;
      url=  _toPunycode(url);
    }
    Map<String, dynamic> jsonMap =
        await _httpService.getUrl(url);
    var newSite = await getSingleSubscription(jsonMap, currentStorehouse.name);
    return newSite;
  }

  Future<StorehouseBeanSites?> getSingleSubscription(
      Map<String, dynamic> jsonMap, String name) async {
    var storehouseBeanEntity = StorehouseBeanEntity.fromJson(jsonMap);
    var siteList = storehouseBeanEntity.sites;
    selectStorehouse = siteList;
    if (selectStorehouse.isNotEmpty) {
      // 先看有没有缓存的站点，如果没有，是切换活添加仓库；如果不为空，则是切换站点
      var currentSite = await SPManager.getCurrentSite();
      if (currentSite == null) {
        await SPManager.saveCurrentSite(selectStorehouse[0]);
        return selectStorehouse[0];
      } else {
        return currentSite;
      }
    }
    return null;
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
