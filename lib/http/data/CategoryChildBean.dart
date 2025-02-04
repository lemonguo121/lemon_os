class CategoryChildBean {
  final int typeId;
  final int typePid;
  final String typeName;

  CategoryChildBean({
    required this.typeId,
    required this.typePid,
    required this.typeName,
  });

  factory CategoryChildBean.fromJson(Map<String, dynamic> json) {
    return CategoryChildBean(
      typeId: json['type_id'],
      typePid: json['type_pid'],
      typeName: json['type_name'],
    );
  }
}
