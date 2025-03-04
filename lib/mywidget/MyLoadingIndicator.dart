import 'package:flutter/material.dart';

class MyLoadingIndicator extends StatefulWidget {
  final bool isLoading;

  const MyLoadingIndicator({super.key, required this.isLoading});

  @override
  State<MyLoadingIndicator> createState() => _MyLoadingIndicatorState();
}

class _MyLoadingIndicatorState extends State<MyLoadingIndicator> {
  @override
  Widget build(BuildContext context) {
    return _buildLoadingIndicator();
  }

  Widget _buildLoadingIndicator() {
    if (!widget.isLoading) return const SizedBox.shrink();
    return const Expanded(
        child: Center(
      child: CircularProgressIndicator(),
    ));
  }
}
