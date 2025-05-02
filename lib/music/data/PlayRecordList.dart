class PlayRecordList {
  final String name;
  final String key;

  PlayRecordList({
    required this.name,
    required this.key,
  });

  factory PlayRecordList.fromJson(Map<String, dynamic> json) {
    return PlayRecordList(
      name: json['name'] ?? '',
      key: json['key'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'key': key,
    };
  }
}
