import 'package:flutter/cupertino.dart';
import '../http/data/RealVideo.dart';

import 'MyLoadingBuilder.dart';

class LoadingImage extends StatefulWidget {
  final String pic;

  const LoadingImage({super.key, required this.pic});

  @override
  State<LoadingImage> createState() => _LoadingImageState();
}

class _LoadingImageState extends State<LoadingImage> {
  @override
  Widget build(BuildContext context) {
    return Image.network(
      widget.pic,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover, // 填充方式
      loadingBuilder: MyLoadingBuilder.build,
      errorBuilder: MyLoadingBuilder.errorBuilder,
    );
  }
}
