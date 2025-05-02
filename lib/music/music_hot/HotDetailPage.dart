import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'hot_model/hot_Model.dart';

class HotDetailPage extends StatefulWidget {
  const HotDetailPage({super.key});

  @override
  State<HotDetailPage> createState() => _HotDetailPageState();
}

class _HotDetailPageState extends State<HotDetailPage> {
  TopListItem? topListItem;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    topListItem = args['topListItem'];
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
