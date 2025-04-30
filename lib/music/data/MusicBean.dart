import 'LyricLine.dart';
import 'SongBean.dart';

class MusicBean {
  final SongBean songBean;
  final List<LyricLine> rawLrc;
  final String url;

  MusicBean({
    required this.songBean,
    required this.rawLrc,
    required this.url,
  });

  factory MusicBean.fromJson(Map<String, dynamic> json) {
    return MusicBean(
      songBean: SongBean.fromJson(json['songBean'] ?? {}),
      rawLrc: (json['rawLrc'] as List<dynamic>? ?? [])
          .map((e) => LyricLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'songBean': songBean.toJson(),
      'rawLrc': rawLrc.map((e) => e.toJson()).toList(),
      'url': url,
    };
  }
}