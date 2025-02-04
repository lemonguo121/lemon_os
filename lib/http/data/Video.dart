import 'dart:convert';

import 'AlClass.dart';
import 'CategoryBean.dart';
import 'CategoryChildBean.dart';

// 视频数据模型
class Video {
  final int vodId;
  final String vodName;
  final int typeId;
  final String typeName;
  final String vodEn;
  final String vodTime;
  final String vodRemarks;
  final String vodPlayFrom;

  Video({
    required this.vodId,
    required this.vodName,
    required this.typeId,
    required this.typeName,
    required this.vodEn,
    required this.vodTime,
    required this.vodRemarks,
    required this.vodPlayFrom,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      vodId: json['vod_id'],
      vodName: json['vod_name'],
      typeId: json['type_id'],
      typeName: json['type_name'],
      vodEn: json['vod_en'],
      vodTime: json['vod_time'],
      vodRemarks: json['vod_remarks'],
      vodPlayFrom: json['vod_play_from'],
    );
  }
}

class ResponseData {
  final int code;
  final String msg;
  final int page;
  final int pageCount;
  final String limit;
  final int total;
  final List<Video> videos;
  final List<CategoryBean> alClass;

  ResponseData({
    required this.code,
    required this.msg,
    required this.page,
    required this.pageCount,
    required this.limit,
    required this.total,
    required this.videos,
    required this.alClass,
  });

  factory ResponseData.fromJson(Map<String, dynamic> json) {
    var videoList = json['list'] as List;
    var classList = json['class'] as List;
    List<Video> videos = videoList.map((e) => Video.fromJson(e)).toList();

    // List<CategoryBean> allClass = classList.map((e) => CategoryBean.fromJson(e)).toList();
    List<CategoryBean> allClass = [];
    Map<int, CategoryBean> categoryMap = {};

    // 先解析所有分类
    for (var item in classList) {
      CategoryBean category = CategoryBean.fromJson(item);
      categoryMap[category.typeId] = category;

      if (category.typePid == 0) {
        allClass.add(category); // 父类直接添加到 alClass
      }
    }

    // 再遍历一次，将子分类放入对应的父类
    for (var item in classList) {
      CategoryBean category = categoryMap[item['type_id']]!;

      if (category.typePid != 0) {
        CategoryBean? parent = categoryMap[category.typePid];
        if (parent != null) {
          parent.categoryChildList.add(CategoryChildBean(
              typeId: category.typeId,
              typeName: category.typeName,
              typePid: category.typePid));
        }
      }
    }

    return ResponseData(
      code: json['code'],
      msg: json['msg'],
      page: json['page'],
      pageCount: json['pagecount'],
      limit: json['limit'],
      total: json['total'],
      videos: videos,
      alClass: allClass,
    );
  }
}
