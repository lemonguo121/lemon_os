import 'SongBean.dart';

class MusicBean {
  final SongBean songBean;
  final String rawLrc;
  final String url;

  MusicBean({
    required this.songBean,
    required this.rawLrc,
    required this.url,
  });

  factory MusicBean.fromJson(Map<String, dynamic> json) {
    return MusicBean(
      songBean: SongBean.fromJson(json['songBean'] ?? {}),
      rawLrc: json['rawLrc'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'songBean': songBean.toJson(),
      'rawLrc': rawLrc,
      'url': url,
    };
  }
}