import 'package:flutter/material.dart';

class RecommendScreen extends StatelessWidget {
  const RecommendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("推荐"),
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              leading: Icon(Icons.local_offer, color: Colors.red),
              title: Text("优惠活动 ${index + 1}"),
              subtitle: Text("活动详情信息"),
              trailing: Text("优惠${(index + 1) * 5}%"),
            ),
          );
        },
      ),
    );
  }
}