import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lemon_tv/http/data/ParesVideo.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class VideoParser {
  static Future<ParesVideo?> parseVideo(String url) async {
    if (url.contains("youtube.com") || url.contains("youtu.be")) {
      return _parseYouTube(url);
    } else if (url.contains("tiktok.com") || url.contains("douyin.com")) {
      return _parseTikTok(url);
    }
    return null;
  }

  /// 解析 YouTube 视频
  static Future<ParesVideo> _parseYouTube(String url) async {
    var yt = YoutubeExplode();
    var video = await yt.videos.get(url);
    var manifest = await yt.videos.streamsClient.getManifest(video.id, ytClients: [
      YoutubeApiClient.ios,
      YoutubeApiClient.androidVr,
    ]);
    final lowQualityStream = manifest.muxed.withHighestBitrate();
    var vodPlayUrl = lowQualityStream.url.toString();
    var paresVideo = ParesVideo(
        vodId: video.id.value,
        vodName: video.title,
        vodPlayUrl: vodPlayUrl,
        vodPic: video.thumbnails.highResUrl,
        vodFrom: "YouTube",
        vodRemarks: url);
    print("youtube play url =${vodPlayUrl}");
    yt.close();
    return paresVideo;
  }

  /// 解析 TikTok / 抖音 视频
  static Future<ParesVideo?> _parseTikTok(String url) async {
    var from = "";
    if (url.contains("tiktok.com")) {
      from = "TikTok";
    } else {
      from = "抖音";
    }
    var apiUrl = "https://www.tikwm.com/api/?url=$url";
    var response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return ParesVideo.fromJson(data, from, url);
    }
    return null;
  }
}
