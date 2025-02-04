import 'CategoryChildBean.dart';

class CategoryBean {
  final int typeId;
  final int typePid;
  final String typeName;
  final List<CategoryChildBean> categoryChildList;

  CategoryBean({
    required this.typeId,
    required this.typePid,
    required this.typeName,
    required this.categoryChildList,
  });



  // factory CategoryBean.fromJson(Map<String, dynamic> json) {
  //   return CategoryBean(
  //     typeId: json['type_id'],
  //     typePid: json['type_pid'],
  //     typeName: json['type_name'],
  //   );
  // }
}
