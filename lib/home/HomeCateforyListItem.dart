import 'package:flutter/material.dart';
import 'package:lemen_os/http/data/RealVideo.dart';

import '../detail/DetailScreen.dart';
import '../util/LoadingImage.dart';

class Homecateforylistitem extends StatefulWidget {
  final RealVideo video;

  const Homecateforylistitem({super.key, required this.video});

  @override
  State<Homecateforylistitem> createState() => _HomecateforylistitemState();
}

class _HomecateforylistitemState extends State<Homecateforylistitem> {
  @override
  Widget build(BuildContext context) {
    return _buildItem(widget.video);
  }

  Widget _buildItem(RealVideo video) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DetailScreen(vodId: video.vodId,subscription: video.subscriptionDomain,), // 动态传递vodId
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160.0, // 图片高度
              width: 110.0, // 图片宽度
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: LoadingImage(
                  pic: video.vodPic,
                ),
              ),
            ),
            const SizedBox(height: 6.0), // 图片和文字的间距
            SizedBox(
                width: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.vodName,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  ],
                )),
          ],
        ),
      ),
    );
  }
}
