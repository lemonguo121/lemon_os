import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class ReaderHomePage extends StatefulWidget {
  const ReaderHomePage({super.key});

  @override
  State<ReaderHomePage> createState() => _ReaderHomePageState();
}

class _ReaderHomePageState extends State<ReaderHomePage> {
  final indexUrl = 'https://www.biqukan.co';

  @override
  void initState() {
    super.initState();
    loadHomeData();
  }

  void loadHomeData() async {
    final res = await http.get(Uri.parse('https://www.biqukan.co/book/9091/'));
    if (res.statusCode != 200) {
      print('目录页请求失败');
      return;
    }
    // final doc = parse(res.body);
    String decodedBody = utf8.decode(res.bodyBytes);
    final doc = parse(decodedBody);

    final novelTitle = doc
        .querySelector('.active')
        ?.text
        .trim() ?? '未知小说';
    print('小说名称：$novelTitle');

    final items = doc.querySelectorAll('.breadcrumb li');
    String novelType = '未知类型';
    if (items.length >= 2) {
      novelType = items[1].querySelector('a')?.text.trim() ?? '未知类型';
    }
    print('小说类型：$novelType');

    final imgElement = doc.querySelector('img.img-thumbnail');
    String imgSrc = imgElement?.attributes['src'] ?? '';
    if (imgSrc.isNotEmpty && imgSrc.startsWith('./')) {
      imgSrc = 'https://www.biqukan.co/' + imgSrc.substring(2); // 去掉 "./"
    }
    print('图片地址：$imgSrc');

    final chapterElements = doc.querySelectorAll('.panel-chapterlist dd a');

    for (var element in chapterElements) {
      final title = element.text.trim();
      final url = element.attributes['href'] ?? '';
      print('$title => https://www.biqukan.co/$url');
    }
    final contentRes = await http.get(Uri.parse('https://www.biqukan.co//book/9091/8934454.html'));
    if (contentRes.statusCode != 200) {
      print('内容页请求失败');
      return;
    }
    final contentDecodedBody = utf8.decode(res.bodyBytes);
    final contentDoc = parse(contentDecodedBody);

    // 获取章节标题
    final title = contentDoc.querySelector('.readTitle')?.text.trim() ?? '未知标题';

    // 获取正文容器
    final contentElement = contentDoc.querySelector('#htmlContent');

    final buffer = StringBuffer();

    for (var node in contentElement?.nodes ?? []) {
      // 只保留 <br> 之后的明文段落
      if (node.nodeType == Node.ELEMENT_NODE &&
          node.localName == 'br' &&
          node.nextSibling != null &&
          node.nextSibling!.nodeType == Node.TEXT_NODE) {
        final text = node.nextSibling!.text?.trim() ?? '';
        if (text.isNotEmpty) {
          buffer.writeln(text);
        }
      }
    }

    print('\n章节标题：$title\n');
    print('章节正文（纯净明文）：\n${buffer.toString()}');
  }

  Future<String> fetchChapter(String url) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      return '章节内容请求失败';
    }
    final doc = parse(res.body);
    final contentEl = doc.querySelector('#content');

    if (contentEl == null) return '章节内容为空';

    // 小说正文的换行用 <br> 或者 &nbsp;，处理成文本格式
    final rawText = contentEl.innerHtml
        .replaceAll('<br>', '\n')
        .replaceAll('<br/>', '\n')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'<.*?>'), '')
        .trim();

    return rawText;
  }

    @override
    Widget build(BuildContext context) {
      return const Placeholder();
    }
}
