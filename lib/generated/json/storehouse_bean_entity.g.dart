import 'package:lemon_tv/generated/json/base/json_convert_content.dart';
import 'package:lemon_tv/http/data/storehouse_bean_entity.dart';

StorehouseBeanEntity $StorehouseBeanEntityFromJson(Map<String, dynamic> json) {
  final StorehouseBeanEntity storehouseBeanEntity = StorehouseBeanEntity();
  final String? spider = jsonConvert.convert<String>(json['spider']);
  if (spider != null) {
    storehouseBeanEntity.spider = spider;
  }
  final String? wallpaper = jsonConvert.convert<String>(json['wallpaper']);
  if (wallpaper != null) {
    storehouseBeanEntity.wallpaper = wallpaper;
  }
  final List<StorehouseBeanLives>? lives = (json['lives'] as List<dynamic>?)
      ?.map(
          (e) =>
      jsonConvert.convert<StorehouseBeanLives>(e) as StorehouseBeanLives)
      .toList();
  if (lives != null) {
    storehouseBeanEntity.lives = lives;
  }
  final List<StorehouseBeanSites>? sites = (json['sites'] as List<dynamic>?)
      ?.map(
          (e) =>
      jsonConvert.convert<StorehouseBeanSites>(e) as StorehouseBeanSites)
      .whereType<StorehouseBeanSites>() // 过滤掉 null 值
      .where((site) => site.type == 0 || site.type == 1) // 只保留 type 为 0 和 1 的数据
      .toList();
  if (sites != null) {
    storehouseBeanEntity.sites = sites;
  }
  final List<StorehouseBeanDoh>? doh = (json['doh'] as List<dynamic>?)
      ?.map(
          (e) => jsonConvert.convert<StorehouseBeanDoh>(e) as StorehouseBeanDoh)
      .toList();
  if (doh != null) {
    storehouseBeanEntity.doh = doh;
  }
  final List<StorehouseBeanRules>? rules = (json['rules'] as List<dynamic>?)
      ?.map(
          (e) =>
      jsonConvert.convert<StorehouseBeanRules>(e) as StorehouseBeanRules)
      .toList();
  if (rules != null) {
    storehouseBeanEntity.rules = rules;
  }
  final List<dynamic>? parses = (json['parses'] as List<dynamic>?)?.map(
          (e) => e).toList();
  if (parses != null) {
    storehouseBeanEntity.parses = parses;
  }
  final List<String>? flags = (json['flags'] as List<dynamic>?)?.map(
          (e) => jsonConvert.convert<String>(e) as String).toList();
  if (flags != null) {
    storehouseBeanEntity.flags = flags;
  }
  final List<StorehouseBeanIjk>? ijk = (json['ijk'] as List<dynamic>?)
      ?.map(
          (e) => jsonConvert.convert<StorehouseBeanIjk>(e) as StorehouseBeanIjk)
      .toList();
  if (ijk != null) {
    storehouseBeanEntity.ijk = ijk;
  }
  final List<String>? ads = (json['ads'] as List<dynamic>?)?.map(
          (e) => jsonConvert.convert<String>(e) as String).toList();
  if (ads != null) {
    storehouseBeanEntity.ads = ads;
  }
  return storehouseBeanEntity;
}

Map<String, dynamic> $StorehouseBeanEntityToJson(StorehouseBeanEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['spider'] = entity.spider;
  data['wallpaper'] = entity.wallpaper;
  data['lives'] = entity.lives.map((v) => v.toJson()).toList();
  data['sites'] = entity.sites.map((v) => v.toJson()).toList();
  data['doh'] = entity.doh.map((v) => v.toJson()).toList();
  data['rules'] = entity.rules.map((v) => v.toJson()).toList();
  data['parses'] = entity.parses;
  data['flags'] = entity.flags;
  data['ijk'] = entity.ijk.map((v) => v.toJson()).toList();
  data['ads'] = entity.ads;
  return data;
}

extension StorehouseBeanEntityExtension on StorehouseBeanEntity {
  StorehouseBeanEntity copyWith({
    String? spider,
    String? wallpaper,
    List<StorehouseBeanLives>? lives,
    List<StorehouseBeanSites>? sites,
    List<StorehouseBeanDoh>? doh,
    List<StorehouseBeanRules>? rules,
    List<dynamic>? parses,
    List<String>? flags,
    List<StorehouseBeanIjk>? ijk,
    List<String>? ads,
  }) {
    return StorehouseBeanEntity()
      ..spider = spider ?? this.spider
      ..wallpaper = wallpaper ?? this.wallpaper
      ..lives = lives ?? this.lives
      ..sites = sites ?? this.sites
      ..doh = doh ?? this.doh
      ..rules = rules ?? this.rules
      ..parses = parses ?? this.parses
      ..flags = flags ?? this.flags
      ..ijk = ijk ?? this.ijk
      ..ads = ads ?? this.ads;
  }
}

StorehouseBeanLives $StorehouseBeanLivesFromJson(Map<String, dynamic> json) {
  final StorehouseBeanLives storehouseBeanLives = StorehouseBeanLives();
  final String? group = jsonConvert.convert<String>(json['group']);
  if (group != null) {
    storehouseBeanLives.group = group;
  }
  final List<StorehouseBeanLivesChannels>? channels = (json['channels'] as List<
      dynamic>?)?.map(
          (e) =>
      jsonConvert.convert<StorehouseBeanLivesChannels>(
          e) as StorehouseBeanLivesChannels).toList();
  if (channels != null) {
    storehouseBeanLives.channels = channels;
  }
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) {
    storehouseBeanLives.name = name;
  }
  final int? type = jsonConvert.convert<int>(json['type']);
  if (type != null) {
    storehouseBeanLives.type = type;
  }
  final String? url = jsonConvert.convert<String>(json['url']);
  if (url != null) {
    storehouseBeanLives.url = url;
  }
  final int? playerType = jsonConvert.convert<int>(json['playerType']);
  if (playerType != null) {
    storehouseBeanLives.playerType = playerType;
  }
  final String? epg = jsonConvert.convert<String>(json['epg']);
  if (epg != null) {
    storehouseBeanLives.epg = epg;
  }
  final String? logo = jsonConvert.convert<String>(json['logo']);
  if (logo != null) {
    storehouseBeanLives.logo = logo;
  }
  return storehouseBeanLives;
}

Map<String, dynamic> $StorehouseBeanLivesToJson(StorehouseBeanLives entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['group'] = entity.group;
  data['channels'] = entity.channels.map((v) => v.toJson()).toList();
  data['name'] = entity.name;
  data['type'] = entity.type;
  data['url'] = entity.url;
  data['playerType'] = entity.playerType;
  data['epg'] = entity.epg;
  data['logo'] = entity.logo;
  return data;
}

extension StorehouseBeanLivesExtension on StorehouseBeanLives {
  StorehouseBeanLives copyWith({
    String? group,
    List<StorehouseBeanLivesChannels>? channels,
    String? name,
    int? type,
    String? url,
    int? playerType,
    String? epg,
    String? logo,
  }) {
    return StorehouseBeanLives()
      ..group = group ?? this.group
      ..channels = channels ?? this.channels
      ..name = name ?? this.name
      ..type = type ?? this.type
      ..url = url ?? this.url
      ..playerType = playerType ?? this.playerType
      ..epg = epg ?? this.epg
      ..logo = logo ?? this.logo;
  }
}

StorehouseBeanLivesChannels $StorehouseBeanLivesChannelsFromJson(
    Map<String, dynamic> json) {
  final StorehouseBeanLivesChannels storehouseBeanLivesChannels = StorehouseBeanLivesChannels();
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) {
    storehouseBeanLivesChannels.name = name;
  }
  final List<String>? urls = (json['urls'] as List<dynamic>?)?.map(
          (e) => jsonConvert.convert<String>(e) as String).toList();
  if (urls != null) {
    storehouseBeanLivesChannels.urls = urls;
  }
  return storehouseBeanLivesChannels;
}

Map<String, dynamic> $StorehouseBeanLivesChannelsToJson(
    StorehouseBeanLivesChannels entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['name'] = entity.name;
  data['urls'] = entity.urls;
  return data;
}

extension StorehouseBeanLivesChannelsExtension on StorehouseBeanLivesChannels {
  StorehouseBeanLivesChannels copyWith({
    String? name,
    List<String>? urls,
  }) {
    return StorehouseBeanLivesChannels()
      ..name = name ?? this.name
      ..urls = urls ?? this.urls;
  }
}

StorehouseBeanSites $StorehouseBeanSitesFromJson(Map<String, dynamic> json) {
  final StorehouseBeanSites storehouseBeanSites = StorehouseBeanSites();
  final String? key = jsonConvert.convert<String>(json['key']);
  if (key != null) {
    storehouseBeanSites.key = key;
  }
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) {
    storehouseBeanSites.name = name;
  }
  final int? type = jsonConvert.convert<int>(json['type']);
  if (type != null) {
    storehouseBeanSites.type = type;
  }
  final String? api = jsonConvert.convert<String>(json['api']);
  if (api != null) {
    storehouseBeanSites.api = api;
  }
  final String? jar = jsonConvert.convert<String>(json['jar']);
  if (jar != null) {
    storehouseBeanSites.jar = jar;
  }
  final int? searchable = jsonConvert.convert<int>(json['searchable']);
  if (searchable != null) {
    storehouseBeanSites.searchable = searchable;
  }
  final int? quickSearch = jsonConvert.convert<int>(json['quickSearch']);
  if (quickSearch != null) {
    storehouseBeanSites.quickSearch = quickSearch;
  }
  final int? filterable = jsonConvert.convert<int>(json['filterable']);
  if (filterable != null) {
    storehouseBeanSites.filterable = filterable;
  }
  final int? changeable = jsonConvert.convert<int>(json['changeable']);
  if (changeable != null) {
    storehouseBeanSites.changeable = changeable;
  }
  final String? playUrl = jsonConvert.convert<String>(json['playUrl']);
  if (playUrl != null) {
    storehouseBeanSites.playUrl = playUrl;
  }
  final List<String>? categories = (json['categories'] as List<dynamic>?)?.map(
          (e) => jsonConvert.convert<String>(e) as String).toList();
  if (categories != null) {
    storehouseBeanSites.categories = categories;
  }
  final String? ext = jsonConvert.convert<String>(json['ext']);
  if (ext != null) {
    storehouseBeanSites.ext = ext;
  }
  final int? timeout = jsonConvert.convert<int>(json['timeout']);
  if (timeout != null) {
    storehouseBeanSites.timeout = timeout;
  }
  final StorehouseBeanSitesStyle? style = jsonConvert.convert<
      StorehouseBeanSitesStyle>(json['style']);
  if (style != null) {
    storehouseBeanSites.style = style;
  }
  return storehouseBeanSites;
}

Map<String, dynamic> $StorehouseBeanSitesToJson(StorehouseBeanSites entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['key'] = entity.key;
  data['name'] = entity.name;
  data['type'] = entity.type;
  data['api'] = entity.api;
  data['jar'] = entity.jar;
  data['searchable'] = entity.searchable;
  data['quickSearch'] = entity.quickSearch;
  data['filterable'] = entity.filterable;
  data['changeable'] = entity.changeable;
  data['playUrl'] = entity.playUrl;
  data['categories'] = entity.categories;
  data['ext'] = entity.ext;
  data['timeout'] = entity.timeout;
  data['style'] = entity.style.toJson();
  return data;
}

extension StorehouseBeanSitesExtension on StorehouseBeanSites {
  StorehouseBeanSites copyWith({
    String? key,
    String? name,
    int? type,
    String? api,
    String? jar,
    int? searchable,
    int? quickSearch,
    int? filterable,
    int? changeable,
    String? playUrl,
    List<String>? categories,
    String? ext,
    int? timeout,
    StorehouseBeanSitesStyle? style,
  }) {
    return StorehouseBeanSites()
      ..key = key ?? this.key
      ..name = name ?? this.name
      ..type = type ?? this.type
      ..api = api ?? this.api
      ..jar = jar ?? this.jar
      ..searchable = searchable ?? this.searchable
      ..quickSearch = quickSearch ?? this.quickSearch
      ..filterable = filterable ?? this.filterable
      ..changeable = changeable ?? this.changeable
      ..playUrl = playUrl ?? this.playUrl
      ..categories = categories ?? this.categories
      ..ext = ext ?? this.ext
      ..timeout = timeout ?? this.timeout
      ..style = style ?? this.style;
  }
}

StorehouseBeanSitesStyle $StorehouseBeanSitesStyleFromJson(
    Map<String, dynamic> json) {
  final StorehouseBeanSitesStyle storehouseBeanSitesStyle = StorehouseBeanSitesStyle();
  final String? type = jsonConvert.convert<String>(json['type']);
  if (type != null) {
    storehouseBeanSitesStyle.type = type;
  }
  final double? ratio = jsonConvert.convert<double>(json['ratio']);
  if (ratio != null) {
    storehouseBeanSitesStyle.ratio = ratio;
  }
  return storehouseBeanSitesStyle;
}

Map<String, dynamic> $StorehouseBeanSitesStyleToJson(
    StorehouseBeanSitesStyle entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['type'] = entity.type;
  data['ratio'] = entity.ratio;
  return data;
}

extension StorehouseBeanSitesStyleExtension on StorehouseBeanSitesStyle {
  StorehouseBeanSitesStyle copyWith({
    String? type,
    double? ratio,
  }) {
    return StorehouseBeanSitesStyle()
      ..type = type ?? this.type
      ..ratio = ratio ?? this.ratio;
  }
}

StorehouseBeanDoh $StorehouseBeanDohFromJson(Map<String, dynamic> json) {
  final StorehouseBeanDoh storehouseBeanDoh = StorehouseBeanDoh();
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) {
    storehouseBeanDoh.name = name;
  }
  final String? url = jsonConvert.convert<String>(json['url']);
  if (url != null) {
    storehouseBeanDoh.url = url;
  }
  final List<String>? ips = (json['ips'] as List<dynamic>?)?.map(
          (e) => jsonConvert.convert<String>(e) as String).toList();
  if (ips != null) {
    storehouseBeanDoh.ips = ips;
  }
  return storehouseBeanDoh;
}

Map<String, dynamic> $StorehouseBeanDohToJson(StorehouseBeanDoh entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['name'] = entity.name;
  data['url'] = entity.url;
  data['ips'] = entity.ips;
  return data;
}

extension StorehouseBeanDohExtension on StorehouseBeanDoh {
  StorehouseBeanDoh copyWith({
    String? name,
    String? url,
    List<String>? ips,
  }) {
    return StorehouseBeanDoh()
      ..name = name ?? this.name
      ..url = url ?? this.url
      ..ips = ips ?? this.ips;
  }
}

StorehouseBeanRules $StorehouseBeanRulesFromJson(Map<String, dynamic> json) {
  final StorehouseBeanRules storehouseBeanRules = StorehouseBeanRules();
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) {
    storehouseBeanRules.name = name;
  }
  final List<String>? hosts = (json['hosts'] as List<dynamic>?)?.map(
          (e) => jsonConvert.convert<String>(e) as String).toList();
  if (hosts != null) {
    storehouseBeanRules.hosts = hosts;
  }
  final List<String>? regex = (json['regex'] as List<dynamic>?)?.map(
          (e) => jsonConvert.convert<String>(e) as String).toList();
  if (regex != null) {
    storehouseBeanRules.regex = regex;
  }
  final List<String>? script = (json['script'] as List<dynamic>?)?.map(
          (e) => jsonConvert.convert<String>(e) as String).toList();
  if (script != null) {
    storehouseBeanRules.script = script;
  }
  return storehouseBeanRules;
}

Map<String, dynamic> $StorehouseBeanRulesToJson(StorehouseBeanRules entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['name'] = entity.name;
  data['hosts'] = entity.hosts;
  data['regex'] = entity.regex;
  data['script'] = entity.script;
  return data;
}

extension StorehouseBeanRulesExtension on StorehouseBeanRules {
  StorehouseBeanRules copyWith({
    String? name,
    List<String>? hosts,
    List<String>? regex,
    List<String>? script,
  }) {
    return StorehouseBeanRules()
      ..name = name ?? this.name
      ..hosts = hosts ?? this.hosts
      ..regex = regex ?? this.regex
      ..script = script ?? this.script;
  }
}

StorehouseBeanIjk $StorehouseBeanIjkFromJson(Map<String, dynamic> json) {
  final StorehouseBeanIjk storehouseBeanIjk = StorehouseBeanIjk();
  final String? group = jsonConvert.convert<String>(json['group']);
  if (group != null) {
    storehouseBeanIjk.group = group;
  }
  final List<StorehouseBeanIjkOptions>? options = (json['options'] as List<
      dynamic>?)?.map(
          (e) =>
      jsonConvert.convert<StorehouseBeanIjkOptions>(
          e) as StorehouseBeanIjkOptions).toList();
  if (options != null) {
    storehouseBeanIjk.options = options;
  }
  return storehouseBeanIjk;
}

Map<String, dynamic> $StorehouseBeanIjkToJson(StorehouseBeanIjk entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['group'] = entity.group;
  data['options'] = entity.options.map((v) => v.toJson()).toList();
  return data;
}

extension StorehouseBeanIjkExtension on StorehouseBeanIjk {
  StorehouseBeanIjk copyWith({
    String? group,
    List<StorehouseBeanIjkOptions>? options,
  }) {
    return StorehouseBeanIjk()
      ..group = group ?? this.group
      ..options = options ?? this.options;
  }
}

StorehouseBeanIjkOptions $StorehouseBeanIjkOptionsFromJson(
    Map<String, dynamic> json) {
  final StorehouseBeanIjkOptions storehouseBeanIjkOptions = StorehouseBeanIjkOptions();
  final int? category = jsonConvert.convert<int>(json['category']);
  if (category != null) {
    storehouseBeanIjkOptions.category = category;
  }
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) {
    storehouseBeanIjkOptions.name = name;
  }
  final String? value = jsonConvert.convert<String>(json['value']);
  if (value != null) {
    storehouseBeanIjkOptions.value = value;
  }
  return storehouseBeanIjkOptions;
}

Map<String, dynamic> $StorehouseBeanIjkOptionsToJson(
    StorehouseBeanIjkOptions entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['category'] = entity.category;
  data['name'] = entity.name;
  data['value'] = entity.value;
  return data;
}

extension StorehouseBeanIjkOptionsExtension on StorehouseBeanIjkOptions {
  StorehouseBeanIjkOptions copyWith({
    int? category,
    String? name,
    String? value,
  }) {
    return StorehouseBeanIjkOptions()
      ..category = category ?? this.category
      ..name = name ?? this.name
      ..value = value ?? this.value;
  }
}