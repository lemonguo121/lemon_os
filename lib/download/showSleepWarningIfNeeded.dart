import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lemon_tv/util/SPManager.dart';

showSleepWarningIfNeeded(BuildContext context) {
  if (Platform.isAndroid) return;
  var noMoreTip = SPManager.isNeedTips();
  if (noMoreTip) return;
  bool dontShowAgain = false;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('温馨提示'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('下载过程中请勿息屏，否则任务可能会被系统暂停。\n下载完成后跟随系统息屏'),
                Row(
                  children: [
                    Checkbox(
                      value: dontShowAgain,
                      onChanged: (val) {
                        setState(() {
                          dontShowAgain = val ?? false;
                        });
                      },
                    ),
                    const Text('不再提示'),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  if (dontShowAgain) {
                    SPManager.saveNeedTips();
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('知道了'),
              ),
            ],
          );
        },
      );
    },
  );
}
