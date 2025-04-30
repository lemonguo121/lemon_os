import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lemon_tv/music/data/MusicBean.dart';
import 'package:lemon_tv/util/CommonUtil.dart';

import '../../data/LyricLine.dart';
import '../../data/SongBean.dart';
import '../../music_http/music_http_rquest.dart';
import '../../music_utils/MusicSPManage.dart';

class MusicPlayerController extends GetxController {
  final AudioPlayer player = AudioPlayer();
  late final MyAudioHandler audioHandler;

  var isPlaying = false.obs;
  var currentPosition = Duration.zero.obs;
  var totalDuration = Duration.zero.obs;
  var playIndex = 0.obs;
  var isVisible = false.obs;

  var songBean = SongBean(
          id: '',
          platform: '',
          artist: '',
          title: '',
          pic: '',
          duration: '',
          artwork: '')
      .obs;
  var lyrics = <LyricLine>[].obs;
  var _currentSongPath = ''.obs;
  var isLoading = true.obs;

  var playList = <MusicBean>[].obs;

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
    playList.value =
        MusicSPManage.getPlayList(MusicSPManage.getCurrentPlayType());
    // 监听播放状态
    player.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      if (state == ProcessingState.completed &&
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
  Future<void> initPlayer(String url) async {
    await player.setUrl(url);
    final bean = songBean.value;
    player.play();
    updateMediaItem(bean);
    if (!playList.any((song) => song.songBean.id == songBean.value.id)) {
      print('****** 列表没有这首，所以添加 songBean.value.id = ${songBean.value.id}');
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
    Uri artUri;

    if (artwork.isEmpty || !artwork.startsWith('http')) {
      // 使用默认占位图（可以上传一张放到服务器上的默认图片）
      artUri = Uri.parse(
          'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAkGBwgHBgkIBwgKCgkLDRYPDQwMDRsUFRAWIB0iIiAdHx8kKDQsJCYxJx8fLT0tMTU3Ojo6Iys/RD84QzQ5OjcBCgoKDQwNGg8PGjclHyU3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3N//AABEIAMAAzAMBIgACEQEDEQH/xAAcAAABBAMBAAAAAAAAAAAAAAAAAQIDBwQFBgj/xABBEAABAwIEAwQHBQUIAwEAAAABAAIDBBEFBiExEkFRB2FxgRMUIjJCkcFScqGx0RUjQ2LwCCRTgpKi0vF0suEW/8QAGgEBAQEAAwEAAAAAAAAAAAAAAAECAwQGBf/EACMRAQEAAgICAgIDAQAAAAAAAAABAhEDBCExBRJRYUFxsQb/2gAMAwEAAhEDEQA/ALxQhCAQhCAQhCAQubzdnXBMqQF2KVIMxF2U0XtSP8By8SqNzb2uZhxx0kOHy/suhOgZTn968fzP38m280F8ZgzfgOXgf2riUELxtEHcTz/lGqrvGu3SiiJZguFzVFjpLUO9G0+WpVFOe6R5fI9z3nd7zcnzQroWFiXbFm+rJEFTS0TT/gQAkDxdf8lz9XnjNVY7inzFifhFUGIf7LLnfZS8SqNscz4+Tc47ixP/AJ0v/JKzNWYYzxMx/F2HqK6X/ktQXJhcg7Ki7UM40ZbwY5LM0fBPGx4P4X/FdVhPbni8BDcXw2lqWX1fA4xuA8DcfiFUd0hKaHpvAe1vK+LERz1D8PmOzKoWF/vDRd1BPFURNlglZLG7Vr2OuCO4heK+S3OXsz41l6YSYRiU9MBvHfijd4sOhTRt7AQqnyV2yUGJFlLmONlBVu0E7CTA8/m0+OnerVjkZKxr43texwuHNNwQs6U9CEIBCEIBCEIBCEIBGyEx5bwkkiw1uUA8gAm4Fgqg7R+11tA+bC8rlk1W32Za0+0yM8wz7Tu/Yd60var2nuxJ02CZdqC2iBLKirZoZurWn7PfzVRk7dwsrBLWVM9bVSVNZNJPPISXyyO4nE+Kh80hcmFyqJCU3iUfEkugl4knEo7ougk4k0uSXTUU8OShyjQCqJQVJH7RsoG3WZSRl7xcIjNpKIVAAAXc5KzdjWTntieXVeFE+3A93ufdPwn8FqMEoCeF7fe/BdhTYfHURcL4+GQDVpF7+HULcm2bVwYBjdBj1Cysw6cSRn3gfeYehHIraLz7T1GIZQxH9oYU68X8aB3u2537vyVz5VzHQ5lw5tZQv1GksRPtRu6H+tVx5Y6WXbdoSXCVZaCEIQCEIQI7ZUr22Z+dGZMs4PMQ4i1dMx2oH+GPr8l3PajnFmUsuvkhcP2jVXjpGHrzee4afMLy1PM+aV8szi+V7i57ydXEm5J81YhrnchoFGXJHOTSVQt0hKEiAQkSqbUIQhNgukS20SJsCBuhK0ElUTQxucRZdJg9D6Q+7tvda7B6Z7pPdDu4qwMIoI3saQCHt8iFqRKlwyjNPwlrdD7zTzW9a+MxAtPDbbq0rHsIW8JA226rVV1d6EmSO1zuORXIwzMTqWTR8D7CQXN/tLlcIzDVZRx9mI4eSYi600Hwys5t/Q8iosSxTjbdrrW1Hiudq6oyk8Wvcs2mnrfAcYo8dwqnxPD5RJTzsuOrTzB7wVsV5w7G85HAMb/ZtfMf2dXvDbu2il2Du4HY+S9HDdcVbhUIQooTXuDGOc4gNAuSdgE47Lg+2TMLsByZO2F3DU1rvVorcri7j5AFBRnaXmZ2aM1VVU1x9UhPoKVt9AxpOvmbn5LkXFK51hZRkrSAlJdBSKbUqRCFNgShInhUJZLZPDSToFIIidSDZEQ20TSFlillIu1jnDuaVE+FzDZwsehTca1UIas2hpjJIAdB3rGLHNFwt7l+qpxUMirbM4jZrzsfFajLo8Ewst4XFup1/wCl1bWxMj9k8PDsW7tP9cljQxR0sN2+70/RanFcUawXjdbu6rkZrLxDEhZzHEB4GoHPvC5LEsTLi9nEbjXTmsLEsTMh42u25LU1FQZSDfULNyJEk9S4u306LH4iXXuorpWrLTIabixtY73Xp7slzOcxZViFS/irqK0E5JuX2HsuPeRa563Xl5hVgdjeYDgmcKenkdalrx6u+50DvgPz08wpSPS4SpBzSrKg7Lzl2/Y16/m6PDY3ExYbAGuFv4j7OP8At4PxXow2sb7LxzmvEHYtmTFK97ifWKuV7b/Z4iGjyFgrErTu3TUrk1UCEIWVCAhKECgKRkfEkY25XU5RwMV0vrNQ3+7xnRp/iO6eAWc8pjN1y9fgz5+SceHuo8AyzPiIbNL+4pidHOGr/AfVdpQ4DhtFYspmySWtxyDiK2IsAABYcgEvhuujly5ZV7Hq/GcHBj63f2VkcbG2axrR0AsmzUlNUDhmp4ntO92BO9q2wTm8Q3GixLXcy4sLNWObxXJVDVAmiPqsu9tXMPly8lx+I4VU4TIYquHgd0OrXt6g8x/XUC2BwuGmvesPF6CPFKB9HPv70MnON/UfLULscPPZdV8Tv/E4Z43Ph8X8K9wvME9PH6nM9zorWjc46t7lh4jXOe8gnffXmsLEKaSlqZYJ28Msbi1zeixnPJbYm5XdmW3l7jrxSPkLjcqJK7XdNQOTmpvJOaglbsp4ZJI5GPheWSMIcxw+Fw1B+agapByRHsHK+KsxvL2H4pHoKqnZIRe/CSNR5G48ltFW3YJiHrOSpKNxHFQ1cjAB9l1pB+LnfJWSstNdmKo9VwHEagOsY6WRzSOvCbLxo5xddzjq7Ur1v2kTGnyJjko3bSu/ReSDoAFYlRuTU526arSBCELKhPGyYE/ogyKWN0sgY0auIAHiraw+lZQ0cMDG29G0Dx01Vb5Wi9LjVKzlxh3yurQC6nZy86en+A4Z9cuS/wBHBOskA28Ere9dV6GlUrBdOpqKqq2SOp4HSCMcTuALHhff2h4G6ri++OVsl8xNIGt9pu/xeCL3Hck4lGw6eaLI4vtEoGtkgrmN1kHo3nvGx+S4UixVqZ1jEuXp+rHNePn/APVVr7X02Xe4Mt4vHfL8U4+1dfz5RlIlKRdh8sDZPamBPaglbspW2tqo2bKTkiLn/s6VIEmNUexc2KUeXEPqrsCoP+z04jMmJN5GiF/9YV+qVqOX7TY3TZAxyNurjSuXkv8ARex80U/reWsUp7XL6SQAd/CV431tYix2SJTDumlOO6QqhEIQopQn20CaN7qXhLmHTbVBtcsSehxukLjoX2+atEKnKaYxSskYfbaQQrZw6rjraKGoi1bI258ea6XZx87en/5/mn0y4r79s/ThHSyUt02RA5t/RvPCDs77J6+Clkuw8DxZ2/iuv+33bdXSfDsQnw/jFPKW8YsfosEN4duvzSuHMJuvVLdzSY8eMyuU9066Rn1SFANkcrT50lEeX5m85Htb+N/oqsebuJ712vaBiDXyRULDrH7T7dTyXFPK73XmsHivmOWcnasn8eEZSJSkXO+YAntTAntRKnZspPhUbNlJyVRa39ngXzNiLuQoh/7hX6FSX9nOlBmxqstq1kUQPjxH6K7lK1COAc0tcLgixC8Z5gon4djuJUMg1pqqWL5OK9mHZeae3fB3Ydnh9Y1v7nEYWzAjYPADHD8Af8yRKrc7ppTy1HDcKhgSuFgD1UjWEhTsh9IwAeSggY0kHqFmU8VzY7FR0zCHC/gVuaSiJA4Rt7v6KyDQ1UDoJrFtgdR3hdJlLGvUJTS1JtA83ufgPXw/7WXUYXHW0ln6Ob7rubT0XM1EElFMYpWlrm6tcP62Wc8JlNVz9bsZ9fknJh7W014IBb7QOtwpmylrQ3do2B5KtMDzLUYc5sct5qYnVh3b939F2NBmDDqwAMqGxvPwSeyQvn58WWHp7HrfJdfsz3q/it054PIgphPioWzxOF2SscO5wUc9dSU7S6aoiY0bkvC45LXf+2GM3aybrXY5jEOE0rpCWumIIjZ1PXwWnxXONPA0soGGaTk9ws0d/euIr62atndLUyOke7ck/wBWXNx8Ft3Xxu/8vx8eNw4bvL/DK2pkqZ3yyP45Huu53UrGcUOOuiS6708PJ223dIhCEQoT27pllI1aRKwKQfOyYxSxsfI9rYml73Hha0cydAPmiPQ/YFh5psly1jxrW1b3tP8AK2zPza5WWtTlPCm4HlzDsMZb+7U7GOIFrut7R8ySfNbZZaB2VbdueX3YvlH16BnFUYdJ6YWGpjIs4fXyCslR1EMdRBJDM0OjkaWuadiDug8UtbxXT2M689F0GdsuS5XzNV4a9p9E1/pIHH4one6fzHktSI+IgtWkRxxWcAQsyngDHbHhO/cpY4PSAFu+471sqaAEC9umyqWoGUIMl+HQn2hZbinozFHxbi93NH5p0EHC0fZ2ufqsqOobC3gl0sdHHkqm0MxDGGRlr2sOdx0P9fVc/ihiq4yyQEkbX3athik4aXFul9SAufqZi4cQdfvG4RY1ssEkR34x1CYJOE638FNJISNd+qhLgd9VhT2zuHuucPAlNdMXG/NMJATSVGvtTnyFxumX70iEQIQhAJUiVWBU9qYFIwKolboLruux/AP25nOmfI3ipqA+sS6aXHuD56+S4dmgv0XpjsbywcvZVjmqYyytxC08rXCzmNI9hp6WFr957kpHeNSoQsqEh2SoQV92wZO//S4EKyijviVAC+IN3lZ8TPwuO/xXnvD7P4onCzgbG+69iEC2yortgyQ7Ca12ZMHhtSTPvVsaNInn4rfZJ36HxVjNjiqSm9GRxDQnQ9Ctg2ncy7mjXmB9EuGuiqoQW68nt6FZdhHa7rt+Fx/JbZ2hEgAuDoRv1WFVyta3u/JT1Z4fabz3b1WmqagG45osY1cXOHsk36XWmmlcx1nCx6hZ07yL8JWHLIHCzhfuO6jTFLgUwp72s+E28VGQsqEIQoBCEIBCEIBKhKtRChSsCa1q3uVMu1uZ8YgwzDm+283klt7MLObj4dOZSjquyDJjsyY82trIuLDKBwfIDtJINWs8OZ+S9KBavLeB0WXsHp8Lw9gbBC21yNXnm495W0ssqVCEIBCEIBRVMUU8EkM8bZIpGlr2OFw4HcEKVCCg8+ZKqMnVRxXB2ukwlx9pp19APsu/l6HktJHXx1EPEwjo5jjqF6TnjZNG6OVjXxvFnNcLghUrn/srqaJ8mJ5TBfALufQj3o+vB1b/AC8uXRalZuLhKqbgNgSWj5j9VqKp4fc/ItUMlc8OdHUNLXtNnNIIIPgdQoHyNf7THWvyV2RDM57dXa+CxnOHRTyONzxKByKYdNk0pSEllKEQlskUUIQlTQRKAiycAqABOa1Oa1dbknIWL5vqB6oz1ehabS1krfYb90fEfBEanLmXsQzHikWH4VFxyv1cT7sbftOPIL09kXJ+H5OwoUlIPSVEtnVNS73pXfQDkFkZSythmVMObR4XDa+ss79Xynq4/TZb5ZUIQhAIQhAIQhAIQhAJClQg4zOnZxgma2umlj9Ur7aVUAFz94bOVEZr7OMy5Ye+SakNXRNOlXSguaR/M3dvmLd69VJrhe46q7HiguNze5UZC9X5j7OMs5g4pKrD2w1B/j0/7t3nbdVvjXYPVMu/BMXZLb3YqtvCf9Tf0V2ili1JwrtsS7Ls5YeXcWDPqGAX46Z7ZL+QN/wWgny9jlLf1nBcSht/iUkjfomxqLIseiyHQSsdwyRSNPRzCFkQYXX1FvV8PrJb7ejge78gmxr9eiUBdPQZCzZiBPq2XsQG2s0XogfN9l1mE9iGZKstOITUVBGRr7RleD4Cw/FNirgzuW0wTAsVxypFNhFBUVchO0bPZb4uOg8yr8wDsWy5h3DJiTp8SlGtpTwx3+6OXirDoaClw+nbT0FPFTxN2ZGwNH4KbVUuSuxSGm9HWZqlbPLv6lAT6Mfedu7wGnirepqeGliZBTxMiiYLNYwWAHgphshQCEIQCEIQCEIQf//Z');
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

  Future<void> getMediaInfo() async {
    isLoading.value = true;
    var currentSite = MusicSPManage.getCurrentSite();
    final rawLrcResp = await NetworkManager().get('/lyric', queryParameters: {
      'id': songBean.value.id,
      'plugin': currentSite?.platform ?? ""
    });
    final rawLrc = rawLrcResp.data['rawLrc'] ?? '';
    lyrics.value = _parseLrc(rawLrc);

    final audioResp = await NetworkManager().get('/getMediaSource',
        queryParameters: {
          'id': songBean.value.id,
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

  void hideMiniPlayer() async {
    isVisible.value = false;
  }

  void onPrev() async {
    var listName = MusicSPManage.getCurrentPlayType();
    var currentIndex = MusicSPManage.getCurrentPlayIndex(listName);
    currentIndex--;
    if (currentIndex == 0) {
      CommonUtil.showToast('已经是第一首了');
      return;
    }
    var musicBean = playList[currentIndex];
    await upDataSong(musicBean.songBean);
    playIndex.value = currentIndex;
    MusicSPManage.saveCurrentPlayIndex(listName, currentIndex);
  }

  void onNext() async {
    var listName = MusicSPManage.getCurrentPlayType();
    var currentIndex = MusicSPManage.getCurrentPlayIndex(listName);
    currentIndex++;
    if (currentIndex > playList.length - 1) {
      currentIndex = 0;
    }
    var musicBean = playList[currentIndex];
    await upDataSong(musicBean.songBean);
    playIndex.value = currentIndex;
    MusicSPManage.saveCurrentPlayIndex(listName, currentIndex);
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
