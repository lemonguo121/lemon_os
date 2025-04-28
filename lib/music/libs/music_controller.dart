import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

class MusicPlayerController extends GetxController {
  final AudioPlayer player = AudioPlayer();
  var isPlaying = false.obs;
  var currentPosition = Duration.zero.obs;
  var totalDuration = Duration.zero.obs;
  var songName = ''.obs;

  void initPlayer(String url, String name) async {
    await player.setUrl(url);
    songName.value = name;
    player.play();

    player.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
    });

    player.positionStream.listen((position) {
      currentPosition.value = position;
    });

    player.durationStream.listen((duration) {
      totalDuration.value = duration ?? Duration.zero;
    });
  }

  void playPause() {
    if (player.playing) {
      player.pause();
    } else {
      player.play();
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
}