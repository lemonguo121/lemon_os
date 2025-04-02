import 'package:flutter/material.dart';
import 'package:lemon_tv/mywidget/MyLoadingIndicator.dart';
import 'package:lemon_tv/player/ParesVideoPlayerPage.dart';
import 'package:lemon_tv/util/CommonUtil.dart';
import 'package:lemon_tv/util/SPManager.dart';

import '../http/data/ParesVideo.dart';
import '../util/AppColors.dart';
import '../util/LoadingImage.dart';

class PareseScreen extends StatefulWidget {
  const PareseScreen({super.key});

  @override
  State<PareseScreen> createState() => _PareseScreenState();
}

class _PareseScreenState extends State<PareseScreen> {
  bool isLoading = false;
  List<ParesVideo> paresHisList = [];

  @override
  void initState() {
    super.initState();
    checkISAgree();
    getParesHisList();
  }

  Future<void> getParesHisList() async {
    var list = await SPManager.getParesVideoHisList();
    setState(() {
      paresHisList = list;
      print("paresHisList  =  ${paresHisList.length}");
    });
  }

  void addPlayUrlDialog() async {
    var isAgreee = await SPManager.isAgree();
    if (!isAgreee) {
      showPrivacyPolicyDialog();
      return;
    }
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _playUrlController = TextEditingController();
    final TextEditingController _picUrlController = TextEditingController();
    // _playUrlController.text =
    //     "https://m3u8.hmrvideo.com/play/7918bb727f134a7d8283d2419fa5ca38.m3u8";
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text("添加播放地址"),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "视频名称"),
              ),
              TextField(
                controller: _playUrlController,
                decoration: InputDecoration(labelText: "视频地址"),
              ),
              TextField(
                controller: _picUrlController,
                decoration: InputDecoration(labelText: "视频封面"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // 取消
              child: Text("取消"),
            ),
            TextButton(
              onPressed: () async {
                String vodName = _nameController.text.trim();
                String vodPlayUrl = _playUrlController.text.trim();
                String vodPic = _picUrlController.text.trim();
                if (vodName == "guodaxiav587" ||
                    vodPlayUrl == "guodaxiav587" ||
                    vodPic == "guodaxiav587") {
                  CommonUtil.showToast("手动重启应用");
                  await SPManager.saveRealFun();
                  Navigator.pop(context);
                  return;
                }

                if (vodPlayUrl.isEmpty) {
                  CommonUtil.showToast("请输入合法的视频地址");
                  return;
                }
                if (vodName.isEmpty) {
                  var list = await SPManager.getParesVideoHisList();
                  vodName = "视频${list.length + 1}";
                }
                var paresVideo = ParesVideo(
                    vodName: vodName, vodPlayUrl: vodPlayUrl, vodPic: vodPic);
                await SPManager.saveParesVideo(paresVideo);
                await getParesHisList();
                Navigator.pop(context);
                // await requestSubscription(name, url);
              },
              child: Text("添加"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(children: [MyLoadingIndicator(isLoading: isLoading)]);
    }
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 45.0),
        child: Column(
          children: [
            SizedBox(
              height: 35,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: InkWell(
                  onTap: () => addPlayUrlDialog(),
                  child: Container(
                    height: 35,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    decoration: BoxDecoration(
                      color: AppColors.themeColor,
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.green),
                        const SizedBox(width: 8.0),
                        Text("输入合法的视频链接",
                            style: TextStyle(
                                fontSize: 16.0, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            _buildHisListUI()
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
        paresUrl(paresVideo);
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> paresUrl(ParesVideo paresVideo) async {
    try {
      await SPManager.saveParesVideo(paresVideo);
      await getParesHisList();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ParesVideoPlayerPage(
                paresVideo: paresVideo,
              ),
        ),
      );
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildHisListUI() {
    if (paresHisList.isEmpty) {
      return Expanded(
          child: Center(
            child: GestureDetector(
              onTap: () => addPlayUrlDialog(),
              child: Align(
                alignment: Alignment.center,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 64, color: AppColors.selectColor),
                    SizedBox(height: 16),
                    Text('暂无数据，点击添加',
                        style:
                        TextStyle(color: AppColors.selectColor, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ));
    } else {
      return Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: CommonUtil.isVertical(context) ? 3 : 6, // 一行三个
              crossAxisSpacing: 8.0, // 水平方向间距
              mainAxisSpacing: 8.0, // 垂直方向间距
              childAspectRatio: 0.75, // 调整宽高比
            ),
            itemCount: paresHisList.length,
            itemBuilder: (context, index) {
              return _buildGridItem(index);
            },
          ));
    }
  }

  void showPrivacyPolicyDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text("免责声明"),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                      '本应用仅为本地及网络视频播放器，不提供任何视频内容、播放资源或流媒体服务。用户需自行添加合法的播放链接，本应用开发者不对用户添加的内容及其播放行为负责，也不承担由此引发的任何法律责任。\n\n使用本应用时，请确保所有播放内容均符合当地法律法规及相关版权要求。若您的合法权益因本应用的使用受到影响，请及时联系我们，我们将配合核实并处理。',
                      style: TextStyle(color: Colors.black, fontSize: 14)))
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // 取消
              child: Text("取消"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                SPManager.saveIsAgree();
              },
              child: Text("同意"),
            ),
          ],
        );
      },
    );
  }

  void checkISAgree() async {
    var isAgree = await SPManager.isAgree();
    if (!isAgree){
      showPrivacyPolicyDialog();
    }
  }
}
