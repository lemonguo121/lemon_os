class AlClass {
  final int typeId;
  final int typePid;
  final String typeName;

  AlClass({
    required this.typeId,
    required this.typePid,
    required this.typeName,
  });

  factory AlClass.fromJson(Map<String, dynamic> json) {
    return AlClass(
      typeId: json['type_id'],
      typePid: json['type_pid'],
      typeName: json['type_name'],
    );
  }
}
