import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lemon_tv/music/data/MusicBean.dart';
import 'package:lemon_tv/music/data/PlayRecordList.dart';
import 'package:lemon_tv/util/CommonUtil.dart';

import '../../util/MusicCacheUtil.dart';
import '../data/LyricLine.dart';
import '../data/SongBean.dart';
import '../music_home/music_home_controller.dart';
import '../music_http/music_http_rquest.dart';
import '../music_utils/MusicSPManage.dart';

// 主要处理 当前播放的歌曲、列表等信息
class MusicPlayerController extends GetxController {
  final AudioPlayer player = AudioPlayer();
  late final MyAudioHandler audioHandler;
  final MusicHomeController homeController = Get.find();
  var isPlaying = false.obs;
  var currentPosition = Duration.zero.obs;
  var totalDuration = Duration.zero.obs;
  var playIndex = 0.obs;
  Rx<LoopMode> playMode = (MusicSPManage.getCurrentPlayMode()).obs;
  RxBool isCurrentSongFavorite = false.obs;
  var currentVolume = 1.0.obs;

  // 当前播放的歌曲信息
  var songBean = SongBean(
          id: '',
          platform: '',
          artist: '',
          title: '',
          pic: '',
          duration: '0',
          artwork: '')
      .obs;
  var lyrics = <LyricLine>[].obs;
  var isLoading = true.obs;
  var playList = <MusicBean>[].obs;

  String getTitle() {
    // var songBean = songBean.value;
    var title = songBean.value.title;
    var artist = songBean.value.artist;
    if (artist.isEmpty && title.isEmpty) {
      return '未知歌曲';
    }
    return '$title $artist';
  }

  String getCover() {
    // var songBean = this.songBean.value;
    var artwork = songBean.value.artwork;
    var id = songBean.value.id;
    if (artwork.isEmpty || !artwork.startsWith('http')) {
      return CommonUtil.getCoverImg(id);
    }
    return artwork;
  }

  void checkSongIsCollected() {
    isCurrentSongFavorite.value = MusicSPManage.isCollected(songBean.value.id);
  }

  void toggleFavorite() {
    var collect = MusicSPManage.getPlayList(MusicSPManage.collect);
    if (isCurrentSongFavorite.value) {
      MusicSPManage.deleteSingleSong(songBean.value.id, MusicSPManage.collect);
    } else {
      collect.add(MusicBean(songBean: songBean.value, rawLrc: lyrics, url: ''));
      MusicSPManage.savePlayList(collect, MusicSPManage.collect);
    }
    isCurrentSongFavorite.value = !isCurrentSongFavorite.value;
    homeController.getRordList();
  }

  /// 新增的初始化方法
  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(player),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.app.channel.audio',
        androidNotificationChannelName: 'Audio Playback',
        androidNotificationOngoing: true,
      ),
    );
    // 初始化的时候，获取上次播放的类型
    var currentPlayType = MusicSPManage.getCurrentPlayType();
    playList.value = MusicSPManage.getPlayList(currentPlayType.key);
    playIndex.value = MusicSPManage.getCurrentPlayIndex(currentPlayType.key);

    currentVolume.value = MusicSPManage.getCurrentVolume();
    if (playIndex.value > playList.length - 1) {
      playIndex.value = 0;
    }
    if (playList.isNotEmpty) {
      songBean.value = playList[playIndex.value].songBean;
    }

    // 监听播放状态
    player.playerStateStream.listen((state) {
      isPlaying.value = state.playing;

      if (state.processingState == ProcessingState.completed &&
          player.loopMode != LoopMode.one) {
        onNext();
      }
    });
    playMode.value = MusicSPManage.getCurrentPlayMode();
    player.setVolume(currentVolume.value);
    player.setLoopMode(playMode.value);
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
  Future<void> initPlayer(String url, bool hasCache) async {
    if (hasCache) {
      await player.setFilePath(url);
    } else {
      await player.setUrl(url);
    }

    final bean = songBean.value;
    player.play();
    updateMediaItem(bean);
    checkSongIsCollected();

    // 更新历史记录
    var listHistory = MusicSPManage.getPlayList(MusicSPManage.history);
    if (!listHistory.any((song) => song.songBean.id == songBean.value.id)) {
      listHistory.insert(
        0,
        MusicBean(songBean: songBean.value, rawLrc: lyrics, url: url),
      );
      MusicSPManage.savePlayList(listHistory, MusicSPManage.history);
      // 如果当前是在播放历史记录，更新当前播放列表
      if (MusicSPManage.history == MusicSPManage.getCurrentPlayType().key) {
        playList.value = listHistory;
      }
      playList.refresh();
    }
    isLoading.value = false;
  }

  void adjustVolume(double dy) async {
    currentVolume.value = (currentVolume.value + dy * 0.01).clamp(0.0, 1.0);
    await player.setVolume(currentVolume.value);
    MusicSPManage.saveCurrentVolume(currentVolume.value);
  }

  Future<void> upDataSong(SongBean song) async {
    isLoading.value = true;
    await player.stop();
    songBean.value = song;
    await getMediaInfo();
  }

  Future<void> updataMedia(MusicBean musicBean) async {
    isLoading.value = true;
    await player.stop();
    songBean.value = musicBean.songBean;
    await getMediaInfo();
  }

  void updateMediaItem(SongBean song) {
    String artwork = song.artwork;
    String songId = song.id;
    Uri artUri;

    if (artwork.isEmpty || !artwork.startsWith('http')) {
      // 使用默认占位图（可以上传一张放到服务器上的默认图片）
      artUri = Uri.parse(CommonUtil.getCoverImg(songId));
    } else {
      artUri = Uri.parse(artwork);
    }

    audioHandler.mediaItem.add(
      MediaItem(
        id: song.id,
        album: song.artist,
        title: song.title,
        artist: song.artist,
        artUri: artUri,
        duration: player.duration,
      ),
    );
  }

  // 更新当前播放列表，默认是历史记录，如果播放我喜欢的  或者某个自己建的歌单 要调这个方法更新
  void upDataPlayList(PlayRecordList? recordType) {
    if (recordType == null) {
      return;
    }
    MusicSPManage.saveCurrentPlayType(recordType);
    playList.value = MusicSPManage.getPlayList(recordType.key);
  }

  Future<void> getMediaInfo() async {
    isLoading.value = true;
    final song = songBean.value;
    final platform = song.platform ?? '';
    try {
      // ===== 尝试加载音频缓存 =====
      final hasAudioCache =
          await MusicCacheUtil.hasAudioCache(song.id, platform);
      String playUrl;

      if (hasAudioCache) {
        final file = await MusicCacheUtil.getCachedFile(song.id, platform);
        playUrl = file.path;
      } else {
        final audioResp = await NetworkManager().get('/getMediaSource',
            queryParameters: {'id': song.id, 'plugin': platform});
        playUrl = audioResp.data['url'];
        await MusicCacheUtil.downloadAndCache(playUrl, song.id, platform);
      }

      // ===== 歌词缓存处理 =====
      final hasLyricCache =
          await MusicCacheUtil.hasLyricCache(song.id, platform);
      String rawLrc;

      if (hasLyricCache) {
        rawLrc = await MusicCacheUtil.getCachedLyric(song.id, platform);
      } else {
        final rawLrcResp = await NetworkManager().get('/lyric',
            queryParameters: {'id': song.id, 'plugin': platform});
        rawLrc = rawLrcResp.data['rawLrc'] ?? '';
        await MusicCacheUtil.saveLyric(rawLrc, song.id, platform);
      }

      // ===== 设置播放器并开始播放 =====
      lyrics.value = _parseLrc(rawLrc);
      print(
          '********* platform = $platform   hasAudioCache = $hasAudioCache  playUrl = $playUrl');
      await initPlayer(playUrl, hasAudioCache);
    } on DioException catch (e) {
      print('请求失败：$e');
      onNext();
    } catch (e) {
      print(e);
      onNext();
    }
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

  void togglePlayMode() async {
    if (playMode.value == LoopMode.off) {
      playMode.value = LoopMode.one;
    } else {
      playMode.value = LoopMode.off;
    }
    MusicSPManage.saveCurrentPlayMode(playMode.value);
    await player.setLoopMode(playMode.value);
  }

  @override
  void onClose() {
    player.dispose();
    super.onClose();
  }

  void onPrev() async {
    var listName = MusicSPManage.getCurrentPlayType();
    var currentIndex = MusicSPManage.getCurrentPlayIndex(listName.key);
    if (currentIndex == 0) {
      CommonUtil.showToast('已经是第一首了');
      return;
    }
    currentIndex--;
    updatePlayIndex(listName.key, currentIndex);
  }

  void onNext() async {
    var listName = MusicSPManage.getCurrentPlayType();
    var currentIndex = MusicSPManage.getCurrentPlayIndex(listName.key);
    currentIndex++;
    if (currentIndex > playList.length - 1) {
      currentIndex = 0;
    }
    updatePlayIndex(listName.key, currentIndex);
  }

  void updatePlayIndex(String listName, int currentIndex) async {
    var musicBean = playList[currentIndex];
    await upDataSong(musicBean.songBean);
    playIndex.value = currentIndex;
    MusicSPManage.saveCurrentPlayIndex(listName, currentIndex);
  }

  void removeSongInList(MusicBean musicBean) {
    var listName = MusicSPManage.getCurrentPlayType();
    var playListNow = playList.value;
    playListNow
        .removeWhere((item) => item.songBean.id == musicBean.songBean.id);
    MusicSPManage.savePlayList(playListNow, listName.key);
    var id = musicBean.songBean.id;
    var platform = musicBean.songBean.platform;
    MusicCacheUtil.deleteAllCacheForSong(id, platform);
    playList.value = playListNow;
    playList.refresh();
  }
}

class MyAudioHandler extends BaseAudioHandler {
  final MusicPlayerController playerController = Get.find();

  MyAudioHandler(AudioPlayer player) {
    player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        playerController.player.playing
            ? MediaControl.pause
            : MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      androidCompactActionIndices: const [0, 1, 3],
      playing: playerController.player.playing,
      processingState: AudioProcessingState.ready,
      updatePosition: playerController.player.position,
    );
  }

  @override
  Future<void> play() => playerController.playPause();

  @override
  Future<void> pause() => playerController.playPause();

  @override
  Future<void> stop() => playerController.player.stop();

  @override
  Future<void> skipToNext() async {
    playerController.onNext();
  }

  @override
  Future<void> skipToPrevious() async {
    playerController.onPrev();
  }
}
