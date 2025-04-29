import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/music/libs/music_hot/hot_controller.dart';
import 'package:lemon_tv/music/libs/music_hot/widget/hot_contentView.dart';

class HotPage extends StatefulWidget {
  const HotPage({super.key});

  @override
  State<HotPage> createState() => _HotPageState();
}

class _HotPageState extends State<HotPage> {
  final HotController controller = Get.put(HotController());

  @override
  void initState() {
    super.initState();
    controller.getHotBannerList();
  }
  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Obx(() {
      if (controller.tabs.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      return Column(
        children: [
          SizedBox(height: topPadding),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TabBar(
              isScrollable: true,
              controller: controller.tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.redAccent,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black87,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 14),
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 4),
              tabs: controller.tabs.map((item) => Tab(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(item.title),
                ),
              )).toList(),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: controller.tabController,
              children: controller.tabs.map((item) {
                return TopListContentView(id: item.id);
              }).toList(),
            ),
          ),
        ],
      );
    });
  }
}
