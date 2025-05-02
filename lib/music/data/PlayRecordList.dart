class PlayRecordList {
  final String name;
  final String key;
  final bool canDelete;

  PlayRecordList({
    required this.name,
    required this.key,
    required this.canDelete,
  });

  factory PlayRecordList.fromJson(Map<String, dynamic> json) {
    return PlayRecordList(
      name: json['name'] ?? '',
      key: json['key'] ?? '',
      canDelete: json['canDelete'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'key': key,
      'canDelete': canDelete,
    };
  }
}
