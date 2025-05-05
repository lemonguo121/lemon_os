import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lemon_tv/music/data/MusicBean.dart';
import 'package:lemon_tv/util/CommonUtil.dart';

import '../../util/MusicCacheUtil.dart';
import '../data/LyricLine.dart';
import '../data/SongBean.dart';
import '../music_http/music_http_rquest.dart';
import '../music_utils/MusicSPManage.dart';


class MusicPlayerController extends GetxController {
  final AudioPlayer player = AudioPlayer();
  late final MyAudioHandler audioHandler;

  var isPlaying = false.obs;
  var currentPosition = Duration.zero.obs;
  var totalDuration = Duration.zero.obs;
  var playIndex = 0.obs;
  Rx<PlayMode> playMode = (MusicSPManage.getCurrentPlayMode()).obs;
  RxBool isCurrentSongFavorite = false.obs;
  Rx<String> currentSongId = "".obs;

  var songBean = SongBean(
          id: '',
          platform: '',
          artist: '',
          title: '',
          pic: '',
          duration:'0',
          artwork: '')
      .obs;
  var lyrics = <LyricLine>[].obs;
  var _currentSongPath = ''.obs;
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
  void checkSongIsCollected(String songId) {
    currentSongId.value = songId;
    isCurrentSongFavorite.value = MusicSPManage.isCollected(songId);
  }
  void toggleFavorite() {
    String songId = currentSongId.value;
    if (isCurrentSongFavorite.value) {
      MusicSPManage.deleteSingleSong(songId,MusicSPManage.collect);
    } else {
      MusicSPManage.savePlayList(playList,MusicSPManage.collect);
    }
    isCurrentSongFavorite.value = !isCurrentSongFavorite.value;
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
    playList.value = MusicSPManage.getPlayList(currentPlayType);
    playIndex.value = MusicSPManage.getCurrentPlayIndex(currentPlayType);
    if(playIndex.value>playList.length-1){
      playIndex.value=0;
    }
    if (playList.isNotEmpty) {
      songBean.value=  playList[playIndex.value].songBean;
    }

    // 监听播放状态
    player.playerStateStream.listen((state) {
      isPlaying.value = state.playing;

      if (state.processingState == ProcessingState.completed &&
          player.loopMode != LoopMode.one) {
        onNext();
      }
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
  Future<void> initPlayer(String url, bool hasCache) async {
    if(hasCache){
      await player.setFilePath(url);
    }else{
      await player.setUrl(url);
    }

    final bean = songBean.value;
    player.play();
    updateMediaItem(bean);
    if (!playList.any((song) => song.songBean.id == songBean.value.id)) {
      playList.insert(
        0,
        MusicBean(songBean: songBean.value, rawLrc: lyrics, url: url),
      );
      MusicSPManage.savePlayList(playList, MusicSPManage.history);
    }
    isLoading.value = false;
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
    // 这里本来想的是既然播放过，就肯定拿到过歌词和播放地址。这里判断如果歌词是空就每次重新请求下媒体数据
    // 但是会存储的播放链接会失效，所以改成每次都请求算了
    // if (musicBean.rawLrc.isEmpty) {
    //   getMediaInfo();
    // }else{
    //   lyrics.value = musicBean.rawLrc;
    // }
    // print('updataSong musicBean.url = ${musicBean.url}');
    // initPlayer(musicBean.url);
  }

  void updateMediaItem(SongBean song) {
    String artwork = song.artwork;
    String songId = song.id;
    Uri artUri;

    if (artwork.isEmpty || !artwork.startsWith('http')) {
      // 使用默认占位图（可以上传一张放到服务器上的默认图片）
      artUri = Uri.parse(
          CommonUtil.getCoverImg(songId));
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
  void upDataPlayList(String listName) {
    MusicSPManage.saveCurrentPlayType(listName);
    playList.value = MusicSPManage.getPlayList(listName);
  }

  // Future<void> getMediaInfo() async {
  //   isLoading.value = true;
  //   var currentSite = MusicSPManage.getCurrentSite();
  //   final rawLrcResp = await NetworkManager().get('/lyric', queryParameters: {
  //     'id': songBean.value.id,
  //     'plugin': currentSite?.platform ?? ""
  //   });
  //   final rawLrc = rawLrcResp.data['rawLrc'] ?? '';
  //   lyrics.value = _parseLrc(rawLrc);
  //
  //   final audioResp = await NetworkManager().get('/getMediaSource',
  //       queryParameters: {
  //         'id': songBean.value.id,
  //         'plugin': currentSite?.platform ?? ""
  //       });
  //   final audioUrl = audioResp.data['url'];
  //   initPlayer(audioUrl);
  // }

  Future<void> getMediaInfo() async {
    isLoading.value = true;
    final song = songBean.value;
    final platform = song.platform ?? '';

    // ===== 尝试加载音频缓存 =====
    final hasAudioCache = await MusicCacheUtil.hasAudioCache(song.id, platform);
    String playUrl;

    if (hasAudioCache) {
      final file = await MusicCacheUtil.getCachedFile(song.id, platform);
      playUrl = file.path;
    } else {
      final audioResp = await NetworkManager().get('/getMediaSource', queryParameters: {
        'id': song.id,
        'plugin': platform
      });
      playUrl = audioResp.data['url'];
      await MusicCacheUtil.downloadAndCache(playUrl, song.id, platform);
    }

    // ===== 歌词缓存处理 =====
    final hasLyricCache = await MusicCacheUtil.hasLyricCache(song.id, platform);
    String rawLrc;

    if (hasLyricCache) {
      rawLrc = await MusicCacheUtil.getCachedLyric(song.id, platform);
    } else {
      final rawLrcResp = await NetworkManager().get('/lyric', queryParameters: {
        'id': song.id,
        'plugin': platform
      });
      rawLrc = rawLrcResp.data['rawLrc'] ?? '';
      await MusicCacheUtil.saveLyric(rawLrc, song.id, platform);
    }

    // ===== 设置播放器并开始播放 =====
    lyrics.value = _parseLrc(rawLrc);
    print('platform = $platform   hasAudioCache = $hasAudioCache  playUrl = $playUrl');
    await initPlayer(playUrl, hasAudioCache);
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
  void togglePlayMode() {
    if (playMode.value == PlayMode.loop) {
      playMode.value = PlayMode.single;
    } else {
      playMode.value = PlayMode.loop;
    }
    MusicSPManage.saveCurrentPlayMode(playMode.value);
    player.setLoopMode(
      playMode.value == PlayMode.loop ? LoopMode.all : LoopMode.one,
    );
    print('当前播放器的模式：${playMode.value}');
  }
  @override
  void onClose() {
    player.dispose();
    super.onClose();
  }

  void onPrev() async {
    var listName = MusicSPManage.getCurrentPlayType();
    var currentIndex = MusicSPManage.getCurrentPlayIndex(listName);
    if (currentIndex == 0) {
      CommonUtil.showToast('已经是第一首了');
      return;
    }
    currentIndex--;
    updatePlayIndex(listName, currentIndex);
  }

  void onNext() async {
    var listName = MusicSPManage.getCurrentPlayType();
    var currentIndex = MusicSPManage.getCurrentPlayIndex(listName);
    if (currentIndex > playList.length - 1) {
      currentIndex = 0;
    }
    currentIndex++;
    updatePlayIndex(listName, currentIndex);
  }
  void updatePlayIndex(String listName,int currentIndex)async{
    var musicBean = playList[currentIndex];
    await upDataSong(musicBean.songBean);
    playIndex.value = currentIndex;
    MusicSPManage.saveCurrentPlayIndex(listName, currentIndex);
  }
  void removeSongInList(MusicBean musicBean) {
    var listName  = MusicSPManage.getCurrentPlayType();
    playList.removeWhere((item)=>item.songBean.id==musicBean.songBean.id);
    MusicSPManage.savePlayList(playList, listName);
    var id = musicBean.songBean.id;
    var platform = musicBean.songBean.platform;
    MusicCacheUtil.deleteAllCacheForSong(id, platform);
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
