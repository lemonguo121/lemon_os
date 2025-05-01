import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'MyLoadingBuilder.dart';

class LoadingImage extends StatelessWidget {
  final String pic;

  const LoadingImage({super.key, required this.pic});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: pic,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      placeholder: MyLoadingBuilder.placeholderBuilder,
      errorWidget: MyLoadingBuilder.errorBuilder,
    );
  }
}