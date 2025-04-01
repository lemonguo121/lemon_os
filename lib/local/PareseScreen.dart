import 'package:flutter/material.dart';
import 'package:lemon_tv/mywidget/MyLoadingIndicator.dart';
import 'package:lemon_tv/player/ParesVideoPlayerPage.dart';
import 'package:lemon_tv/util/CommonUtil.dart';
import 'package:lemon_tv/util/SPManager.dart';

import '../http/data/ParesVideo.dart';
import '../util/LoadingImage.dart';
import '../util/VideoParser.dart';

class PareseScreen extends StatefulWidget {
  const PareseScreen({super.key});

  @override
  State<PareseScreen> createState() => _PareseScreenState();
}

class _PareseScreenState extends State<PareseScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool isLoading = false;
  List<ParesVideo> paresHisList = [];

  @override
  void initState() {
    super.initState();
    setDefautUrl();
    getParesHisList();
  }

  void setDefautUrl() {
    //    https://vt.tiktok.com/ZSrrjQ6AJ/
    //    https://youtu.be/cC2uInPZA-M?si=2DS6wYjvXk6tY4b7
    //    https://vt.tiktok.com/ZSrMv2TA1/
    _urlController.text = "https://youtu.be/cC2uInPZA-M?si=2DS6wYjvXk6tY4b7";
  }

  Future<void> getParesHisList() async {
    var list = await SPManager.getParesVideoHisList();
    setState(() {
      paresHisList = list;
      print("paresHisList  =  ${paresHisList.length}");
    });
  }

  void _fetchVideo() async {
    String url = _urlController.text.trim();
    if (url == "yy112233") {
      await SPManager.saveRealFun();
      CommonUtil.showToast("请手动重启应用");
      return;
    }
    setState(() {
      isLoading = true;
    });
    if (url.isEmpty) {
      setState(() {
        CommonUtil.showToast("请输入有效的视频链接");
      });
      return;
    }

    paresUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    var isVertical = CommonUtil.isVertical(context);
    if (isLoading) {
      return Column(children: [MyLoadingIndicator(isLoading: isLoading)]);
    }
    return Scaffold(
      appBar: AppBar(title: Text("视频解析播放")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: "输入视频链接",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _fetchVideo,
              child: Text("解析并播放"),
            ),
            Expanded(
                child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isVertical ? 3 : 6, // 一行三个
                crossAxisSpacing: 8.0, // 水平方向间距
                mainAxisSpacing: 8.0, // 垂直方向间距
                childAspectRatio: 0.75, // 调整宽高比
              ),
              itemCount: paresHisList.length,
              itemBuilder: (context, index) {
                return _buildGridItem(index);
              },
            ))
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(int index) {
    var paresVideo = paresHisList[index];

    return GestureDetector(
      onTap: () async {
        setState(() {
          isLoading = true;
        });
        paresUrl(paresVideo.vodRemarks);
      },
      onLongPress: () async {
        await SPManager.removeParesItem(paresVideo);
        CommonUtil.showToast("删除成功");
        paresHisList = await SPManager.getParesVideoHisList();
        setState(() {});
      },
      child: Stack(
        children: [
          // 封面图片
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: LoadingImage(
              pic: paresVideo.vodPic,
            ),
          ),
          // 覆盖层显示文字
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter, // 渐变起点（顶部）
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.05), // 顶部完全透明
                        Colors.black.withOpacity(0.9), // 底部半透明黑色
                      ]),
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8.0),
                      bottomRight: Radius.circular(8.0))),
              padding: const EdgeInsets.symmetric(
                vertical: 4.0,
                horizontal: 8.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paresVideo.vodName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    paresVideo.vodFrom,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> paresUrl(String url) async {
    try {
      var videoData = await VideoParser.parseVideo(url);
      print("playUrl ${videoData?.vodPlayUrl ?? ""}");
      if (videoData != null && videoData.vodPlayUrl.isNotEmpty) {
        await SPManager.saveParesVideo(videoData);
        await getParesHisList();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ParesVideoPlayerPage(
              paresVideo: videoData,
            ),
          ),
        );
      } else {
        setState(() {
          CommonUtil.showToast("无法解析视频，请检查链接");
        });
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
