import 'package:get/get.dart';
import 'package:lemon_tv/music/music_utils/MusicSPManage.dart';

import '../../util/MusicCacheUtil.dart';
import '../data/MusicBean.dart';
import '../data/PlayRecordList.dart';

class PlayListController extends GetxController {
  PlayRecordList? recordBean;
  var playList = <MusicBean>[].obs;

  void getPlayList() {
    var listKey = recordBean?.key ?? '';
    playList.value = MusicSPManage.getPlayList(listKey);
  }

  void removeSongInList(MusicBean musicBean) {
    playList
        .removeWhere((item) => item.songBean.id == musicBean.songBean.id);
    MusicSPManage.savePlayList(playList, recordBean?.key??'');
    var id = musicBean.songBean.id;
    var platform = musicBean.songBean.platform;
    MusicCacheUtil.deleteAllCacheForSong(id, platform);
  }
}
