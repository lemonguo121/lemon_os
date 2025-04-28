class PluginInfo {
  final String plugin;
  final String name;
  final String platform;

  PluginInfo({
    required this.plugin,
    required this.name,
    required this.platform,
  });

  factory PluginInfo.fromJson(Map<String, dynamic> json) {
    return PluginInfo(
      plugin: json['plugin'] ?? '',
      name: json['name'] ?? '',
      platform: json['platform'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plugin': plugin,
      'name': name,
      'platform': platform,
    };
  }
}