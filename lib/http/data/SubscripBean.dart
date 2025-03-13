class SubscripBean {
  final List<StorehouseBean> urls;

  SubscripBean({
    required this.urls,
  });

  factory SubscripBean.fromJson(Map<String, dynamic> json) {
    return SubscripBean(
      urls: (json['urls'] as List<dynamic>)
          .map((e) => StorehouseBean.fromJson(e))
          .toList(),
    );
  }
}

class StorehouseBean {
  final String url;
  final String name;

  StorehouseBean({required this.url, required this.name});

  // JSON 序列化
  Map<String, dynamic> toJson() {
    return {
      "url": url,
      "name": name,
    };
  }

  // JSON 反序列化
  factory StorehouseBean.fromJson(Map<String, dynamic> json) {
    return StorehouseBean(
        url: json['url'] as String, name: json['name'] as String);
  }
}
