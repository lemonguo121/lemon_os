import 'dart:convert';

// HotList hotListFromJson(String str) => HotList.fromJson(json.decode(str));
// String hotListToJson(HotList data) => json.encode(data.toJson());

class TopListGroup {
  String title;
  List<TopListItem> data;

  TopListGroup({
    required this.title,
    required this.data,
  });

  factory TopListGroup.fromJson(Map<String, dynamic> json) => TopListGroup(
    title: json["title"] ?? "",
    data: (json["data"] as List<dynamic>?)
        ?.map((e) => TopListItem.fromJson(e))
        .toList() ??
        [],
  );

  Map<String, dynamic> toJson() => {
    "title": title,
    "data": data.map((e) => e.toJson()).toList(),
  };
}

class TopListItem {
  String id;
  String title;
  String description;

  TopListItem({
    required this.id,
    required this.title,
    required this.description,
  });

  factory TopListItem.fromJson(Map<String, dynamic> json) => TopListItem(
    id: json["id"] ?? "",
    title: json["title"] ?? "",
    description: json["description"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "description": description,
  };
}



class HotSubModel {
  String id;
  List<HotSubListModel> musicList;

  HotSubModel({
    this.id = "",
    this.musicList = const [],
  });

  factory HotSubModel.fromJson(Map<String, dynamic> json) => HotSubModel(
    id: json["id"] ?? "",
    musicList: json["musicList"] == null
        ? []
        : List<HotSubListModel>.from(
        json["musicList"].map((x) => HotSubListModel.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "musicList": List<dynamic>.from(musicList.map((x) => x.toJson())),
  };
}

class HotSubListModel {
  String id;
  String title;
  String artist;

  HotSubListModel({
    this.id = "",
    this.title = "",
    this.artist = "",
  });

  factory HotSubListModel.fromJson(Map<String, dynamic> json) => HotSubListModel(
    id: json["id"] ?? "",
    title: json["title"] ?? "",
    artist: json["artist"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "artist": artist,
  };
}