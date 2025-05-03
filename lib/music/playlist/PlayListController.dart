import 'package:get/get.dart';
import 'package:lemon_tv/music/music_utils/MusicSPManage.dart';

import '../data/MusicBean.dart';
import '../data/PlayRecordList.dart';

class PlayListController extends GetxController {
  PlayRecordList? recordBean;
  var playList = <MusicBean>[].obs;

  void getPlayList() {
    var listKey = recordBean?.key ?? '';
    playList.value = MusicSPManage.getPlayList(listKey);
  }
}
