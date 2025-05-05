class PluginInfo {

  final String name;
  final String platform;

  PluginInfo({
    required this.name,
    required this.platform,
  });

  factory PluginInfo.fromJson(Map<String, dynamic> json) {
    return PluginInfo(
      name: json['name'] ?? '',
      platform: json['platform'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'platform': platform,
    };
  }
}