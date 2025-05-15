import 'package:get/get.dart';
import 'package:lemon_tv/util/CommonUtil.dart';

import '../util/SPManager.dart';

class SettingController extends GetxController {
  RxBool enableKit = (SPManager.getEnableKit()).obs;

  void toggle(bool value) {
    enableKit.value = value;
    SPManager.setEnableKit(value);
    CommonUtil.showToast('重启应用才能生效');
  }
}