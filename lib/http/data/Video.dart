import 'dart:ffi';

import 'package:xml/xml.dart';

import 'CategoryBean.dart';
import 'CategoryChildBean.dart';

// 视频数据模型
class Video {
  final int vodId;
  final String vodName;
  final int typeId;
  final String typeName;
  final String vodTime;
  final String vodRemarks;
  final String vodPlayFrom;

  Video({
    required this.vodId,
    required this.vodName,
    required this.typeId,
    required this.typeName,
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
      vodTime: json['vod_time'],
      vodRemarks: json['vod_remarks'],
      vodPlayFrom: json['vod_play_from'],
    );
  }

  factory Video.fromXml(XmlElement element) {
    return Video(
      vodId: int.parse(element.findElements('id').single.text),
      vodName: element.findElements('name').single.text,
      typeId: int.parse(element.findElements('tid').single.text),
      typeName: element.findElements('type').single.text,
      vodTime: element.findElements('last').single.text,
      vodRemarks: element.findElements('note').single.text,
      vodPlayFrom: element.findElements('dt').single.text,
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

  factory ResponseData.fromXml(XmlDocument document) {
    // 解析视频列表
    final videoList = document.findAllElements('video').map((element) {
      return Video.fromXml(element);
    }).toList();

    // 解析分类列表
    final classList = document.findAllElements('class');
    List<CategoryBean> allClass = [];
    Map<int, CategoryBean> categoryMap = {};

    // 先解析所有分类

    for (var element in classList) {
      final classList = element.findAllElements('ty');
      for (var element in classList) {
        int id = int.parse(element.getAttribute('id')!); // 获取 id 属性
        String name = element.text.trim();
        int typePid = 0; // 默认值
        try {
          // 尝试从 XML 元素中获取 pid 值并解析为整数
          typePid = int.parse(element.findElements('pid').single.text);
        } catch (e) {
          // 如果找不到 pid 或无法解析为整数，则使用默认值 0
          print("can't find typePid");
          typePid = 0;
        }
        CategoryBean category = CategoryBean(
          typeId: id,
          typeName: name,
          typePid: typePid,
          categoryChildList: [],
        );
        categoryMap[category.typeId] = category;
        if (category.typePid == 0) {
          allClass.add(category); // 父类直接添加到 alClass
        }
      }
    }
    // 处理子分类
    for (var element in classList) {
      int typeId = 0;
      try {
        typeId = int.parse(element.getAttribute('id')!);
      } catch (e) {
        typeId = 0;
        print("take child category:can't find typeId");
      }

      int typePid = 0;
      try {
        typePid = int.parse(element.findElements('pid').single.text) ?? 0;
      } catch (e) {
        print("take child category:can't find typePid");
        typePid = 0;
      }
      String typeName = "";
      try {
        typeName = element.text.trim();
      } catch (e) {
        print("take child category:can't find typeName");
        typePid = 0;
      }

      if (typePid != 0) {
        CategoryBean? parent = categoryMap[typePid];
        if (parent != null) {
          parent.categoryChildList.add(CategoryChildBean(
            typeId: typeId,
            typeName: typeName,
            typePid: typePid,
          ));
        }
      }
    }
    int code = 0;
    try {
      code = int.parse(document.findAllElements('code').single.text);
    } catch (e) {
      print("take response:can't find code");
      code = 0;
    }
    final listParent = document.findAllElements('list');

    String page = "1";
    String pageCount = "1";
    String pageSize = "20";
    String recordcount = "20";
    for (var element in listParent) {
      try {
        page = element.getAttribute('page')!;
      } catch (e) {
        print("take response:can't find page");
        page = "1";
      }

      try {
        pageCount = element.getAttribute('pagecount')!;
      } catch (e) {
        print("take response:can't find pagecount");
        pageCount = "1";
      }

      try {
        pageSize = element.getAttribute('pagesize')!;
      } catch (e) {
        print("take response:can't find pagesize");
        pageSize = "20";
      }

      try {
        recordcount = element.getAttribute('recordcount')!;
      } catch (e) {
        print("take response:can't find recordcount");
        recordcount = "20";
      }
    }

    return ResponseData(
      code: code,
      msg: "",
      page: int.parse(page),
      pageCount: int.parse(pageCount),
      limit: pageSize,
      total: int.parse(recordcount),
      videos: videoList,
      alClass: allClass,
    );
  }
}
