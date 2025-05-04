class SongBean{
  final String id;
  final String platform;
  final String artist;
  final String title;
  final String pic;
  final String duration;
  final String artwork;

  SongBean({
    required this.id,
    required this.platform,
    required this.artist,
    required this.title,
    required this.pic,
    required this.duration,
    required this.artwork,
  });

  factory SongBean.fromJson(Map<String, dynamic> json) {
    return SongBean(
      id: json['id'] ?? '',
      platform: json['platform'] ?? '',
      artist: json['artist'] ?? '',
      title: json['title'] ?? '',
      pic: json['pic'] ?? '',
      duration: '${json['duration'] ?? '0'}',
      artwork: json['artwork'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platform': platform,
      'artist': artist,
      'title': title,
      'pic': pic,
      'duration': duration,
      'artwork': artwork,
    };
  }
}