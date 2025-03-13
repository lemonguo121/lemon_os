import 'package:lemon_tv/generated/json/base/json_field.dart';
import 'package:lemon_tv/generated/json/storehouse_bean_entity.g.dart';
import 'dart:convert';
export 'package:lemon_tv/generated/json/storehouse_bean_entity.g.dart';

@JsonSerializable()
class StorehouseBeanEntity {
	late String spider;
	late String wallpaper;
	late List<StorehouseBeanLives> lives;
	late List<StorehouseBeanSites> sites;
	late List<StorehouseBeanDoh> doh;
	late List<StorehouseBeanRules> rules;
	late List<dynamic> parses;
	late List<String> flags;
	late List<StorehouseBeanIjk> ijk;
	late List<String> ads;

	StorehouseBeanEntity();

	factory StorehouseBeanEntity.fromJson(Map<String, dynamic> json) => $StorehouseBeanEntityFromJson(json);

	Map<String, dynamic> toJson() => $StorehouseBeanEntityToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}

@JsonSerializable()
class StorehouseBeanLives {
	late String group;
	late List<StorehouseBeanLivesChannels> channels;
	late String name;
	late int type;
	late String url;
	late int playerType;
	late String epg;
	late String logo;

	StorehouseBeanLives();

	factory StorehouseBeanLives.fromJson(Map<String, dynamic> json) => $StorehouseBeanLivesFromJson(json);

	Map<String, dynamic> toJson() => $StorehouseBeanLivesToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}

@JsonSerializable()
class StorehouseBeanLivesChannels {
	late String name;
	late List<String> urls;

	StorehouseBeanLivesChannels();

	factory StorehouseBeanLivesChannels.fromJson(Map<String, dynamic> json) => $StorehouseBeanLivesChannelsFromJson(json);

	Map<String, dynamic> toJson() => $StorehouseBeanLivesChannelsToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}

@JsonSerializable()
class StorehouseBeanSites {
	late String key;
	late String name;
	late int type;
	late String api;
	late String playUrl;
	late int searchable;
	late int quickSearch;
	late List<String> categories;

	// ✅ 让缺失的字段有默认值
	String jar = "";
	int filterable = 0;
	int changeable = 0;
	String ext = "";
	int timeout = 0;
	StorehouseBeanSitesStyle? style; // 可以为空，避免报错

	StorehouseBeanSites();

	factory StorehouseBeanSites.fromJson(Map<String, dynamic> json) {
		return $StorehouseBeanSitesFromJson(json);
	}

	Map<String, dynamic> toJson() => $StorehouseBeanSitesToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}

@JsonSerializable()
class StorehouseBeanSitesStyle {
	late String type;
	late double ratio;

	StorehouseBeanSitesStyle();

	factory StorehouseBeanSitesStyle.fromJson(Map<String, dynamic> json) => $StorehouseBeanSitesStyleFromJson(json);

	Map<String, dynamic> toJson() => $StorehouseBeanSitesStyleToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}

@JsonSerializable()
class StorehouseBeanDoh {
	late String name;
	late String url;
	late List<String> ips;

	StorehouseBeanDoh();

	factory StorehouseBeanDoh.fromJson(Map<String, dynamic> json) => $StorehouseBeanDohFromJson(json);

	Map<String, dynamic> toJson() => $StorehouseBeanDohToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}

@JsonSerializable()
class StorehouseBeanRules {
	late String name;
	late List<String> hosts;
	late List<String> regex;
	late List<String> script;

	StorehouseBeanRules();

	factory StorehouseBeanRules.fromJson(Map<String, dynamic> json) => $StorehouseBeanRulesFromJson(json);

	Map<String, dynamic> toJson() => $StorehouseBeanRulesToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}

@JsonSerializable()
class StorehouseBeanIjk {
	late String group;
	late List<StorehouseBeanIjkOptions> options;

	StorehouseBeanIjk();

	factory StorehouseBeanIjk.fromJson(Map<String, dynamic> json) => $StorehouseBeanIjkFromJson(json);

	Map<String, dynamic> toJson() => $StorehouseBeanIjkToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}

@JsonSerializable()
class StorehouseBeanIjkOptions {
	late int category;
	late String name;
	late String value;

	StorehouseBeanIjkOptions();

	factory StorehouseBeanIjkOptions.fromJson(Map<String, dynamic> json) => $StorehouseBeanIjkOptionsFromJson(json);

	Map<String, dynamic> toJson() => $StorehouseBeanIjkOptionsToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}