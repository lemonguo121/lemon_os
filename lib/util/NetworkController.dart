import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class NetworkController extends GetxController {
  final Rx<ConnectivityResult> connectionStatus = ConnectivityResult.none.obs;
  late final StreamSubscription<ConnectivityResult> _subscription;

  @override
  void onInit() {
    super.onInit();
    _checkInitialStatus();
    _subscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      connectionStatus.value = result;
    });
  }

  void _checkInitialStatus() async {
    var result = await Connectivity().checkConnectivity();
    connectionStatus.value = result;
  }

  @override
  void onClose() {
    _subscription.cancel();
    super.onClose();
  }
}