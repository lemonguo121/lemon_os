import 'package:audio_session/audio_session.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lemon_tv/music/libs/player/widget/music_play.dart';

import '../../music_http/music_http_rquest.dart';
import '../../music_utils/MusicSPManage.dart';


class MusicPlayerController extends GetxController {
  final AudioPlayer player = AudioPlayer();
  var isPlaying = false.obs;
  var currentPosition = Duration.zero.obs;
  var totalDuration = Duration.zero.obs;
  var songName = ''.obs;
  var isVisible = false.obs;
  var songId = ''.obs;
  var lyrics = <LyricLine>[].obs;
  var _currentSongPath = ''.obs;
  var isLoading = true.obs;

  /// 新增的初始化方法
  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // 监听播放状态
    player.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
    });

    // 监听播放进度
    player.positionStream.listen((position) {
      currentPosition.value = position;
    });

    // 监听总时长
    player.durationStream.listen((duration) {
      totalDuration.value = duration ?? Duration.zero;
    });
  }

  /// 设置歌曲并播放
  Future<void> initPlayer(String url) async {
    await player.setUrl(url);
    songName.value = songName.value;
    player.play();
    isLoading.value = false;
  }

  void upDateSong(String newSongId, String newSongName) {
    player.stop();
    songId.value = newSongId;
    songName.value = newSongName;
    getMediaInfo();
  }

  Future<void> getMediaInfo() async {
    isLoading.value = true;
    var currentSite = MusicSPManage.getCurrentSite();
    final rawLrcResp = await NetworkManager().get('/lyric', queryParameters: {
      'id': songId.value,
      'plugin': currentSite?.platform ?? ""
    });
    final rawLrc = rawLrcResp.data['rawLrc'] ?? '';
    lyrics.value = _parseLrc(rawLrc);

    final audioResp = await NetworkManager().get('/getMediaSource',
        queryParameters: {
          'id': songId.value,
          'plugin': currentSite?.platform ?? ""
        });
    final audioUrl = audioResp.data['url'];
    initPlayer(audioUrl);
  }

  List<LyricLine> _parseLrc(String rawLrc) {
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2})\](.*)');
    final lines = rawLrc.split('\n');
    final result = <LyricLine>[];

    for (final line in lines) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = int.parse(match.group(2)!);
        final ms = int.parse(match.group(3)!) * 10;
        final text = match.group(4)!.trim();
        result.add(LyricLine(
          Duration(minutes: min, seconds: sec, milliseconds: ms),
          text,
        ));
      }
    }
    return result;
  }

  Future<void> playPause() async {
    if (player.playing) {
      player.pause();
      isPlaying.value = false;
    } else {
      player.play();
      isPlaying.value = true;
    }
  }

  void seekTo(Duration position) {
    player.seek(position);
  }

  @override
  void onClose() {
    player.dispose();
    super.onClose();
  }

  void hideMiniPlayer() {
    isVisible.value = false;
  }

  void onPrev() {}

  void onPlayPauseAction() {}

  void onNext() {}
}
