import 'dart:convert';

import 'CategoryChildBean.dart';

class CategoryBean {
  int typeId;
  int typePid;
  String typeName;
  List<CategoryChildBean> categoryChildList;

  CategoryBean({
    required this.typeId,
    required this.typePid,
    required this.typeName,
    required this.categoryChildList,
  });

  factory CategoryBean.fromJson(Map<String, dynamic> json) {
    return CategoryBean(
        typeId: json['type_id'],
        typePid: json['type_pid'],
        typeName: json['type_name'],
        categoryChildList: []);
  }

  // 解析 JSON 方法
  List<CategoryBean> parseCategories(String jsonStr) {
    final List<dynamic> jsonList = jsonDecode(jsonStr)['class'];

    // 创建 Map 存储所有的 CategoryBean
    Map<int, CategoryBean> categoryMap = {};

    // 先创建所有父类
    for (var item in jsonList) {
      int typePid = item['type_pid'];
      if (typePid == 0) {
        CategoryBean category = CategoryBean.fromJson(item);
        categoryMap[category.typeId] = category;
      }
    }

    // 再遍历所有子类，并加入对应父类的 `categoryChildList`
    for (var item in jsonList) {
      int typePid = item['type_pid'];
      if (typePid != 0 && categoryMap.containsKey(typePid)) {
        categoryMap[typePid]!
            .categoryChildList
            .add(CategoryChildBean.fromJson(item));
      }
    }

    return categoryMap.values.toList();
  }
}
