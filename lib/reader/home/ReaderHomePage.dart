import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as dom; // ✅ 使用别名 dom
import 'package:html_unescape/html_unescape.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../data/Chapter.dart';

class ReaderHomePage extends StatefulWidget {
  const ReaderHomePage({super.key});

  @override
  State<ReaderHomePage> createState() => _ReaderHomePageState();
}

class _ReaderHomePageState extends State<ReaderHomePage> {
  // https://www.hetushu.com/search/?keyword=%E6%96%97%E7%A0%B4%E8%8B%8D%E7%A9%B9
  // final indexUrl = 'https://www.biqukan.co';
  final indexUrl = 'https://www.hetushu.com';
  late final WebViewController _controller;
  var funcType = '';

  @override
  void initState() {
    super.initState();
    // loadHomeData();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (String url) async {
          print('页面加载完成：$url');
          // funcType   只是临时区分业务的方法，后续再考虑怎么优化
          switch (funcType) {
            case 'bookdetail':
              await parseBookDetail();
              break;
            case 'chapterdetail':
              await parseChapterDetail();
              break;
          }
        },
      ));
    loadBookDetail();
  }

  parseChapterDetail() async {
    try {
      final jsCode = """
      (function() {
        const content = document.querySelector('#content');
        if (!content) return '';

        function getTextNodes(node) {
          let text = '';
          node.childNodes.forEach(child => {
            if (child.nodeType === Node.TEXT_NODE) {
              const t = child.textContent;
              if (t.trim().length > 0) {
                text += t + '\\n\\n'; // 保留原始缩进
              }
            } else if (child.nodeType === Node.ELEMENT_NODE) {
              const style = window.getComputedStyle(child);
              if (style && style.display !== 'none' && style.visibility !== 'hidden') {
                text += getTextNodes(child);
              }
            }
          });
          return text;
        }

        return getTextNodes(content).trim();
      })();
    """;

      var rawText = await _controller.runJavaScriptReturningResult(jsCode);

      print('********  parseChapterDetail');

// 清理JS返回的字符串
      String cleanedText = rawText
          .toString()
          .replaceAllMapped(RegExp(r'^"|"$'), (m) => '') // 去前后引号
          .replaceAll(r'\"', '"') // 解码引号
          .replaceAll(r'\\n', '\n'); // 恢复换行（注意是两个反斜杠）

// 每段添加两个全角空格作为缩进
      String formattedText = cleanedText
          .split('\n')
          .map((line) => line.trim().isEmpty ? '' : '　　$line')
          .join('\n');

      print('节内容：\n$formattedText');
    } catch (e) {
      print('获取章节内容失败：$e');
    }
  }

  // 通过标签取爬取内容，网页有防爬虫机制，顺序都是错乱且重复
  // parseChapterDetail() async {
  //   try {
  //     var html = await _controller.runJavaScriptReturningResult(
  //         "window.document.documentElement.outerHTML;");
  //
  //     print('********  parseChapterDetail');
  //     // rawHtml 是带引号的字符串，要先转义去掉前后引号和反斜杠
  //     String cleanedHtml = html
  //         .toString()
  //         .replaceAll(r'\u003C', '<') // 替换编码
  //         .replaceAll(r'\n', '\n')
  //         .replaceAll(r'\t', '\t')
  //         .replaceAll(r'\r', '')
  //         .replaceAllMapped(RegExp(r'^"|"$'), (m) => '') // 去掉开头结尾引号
  //         .replaceAll(r'\"', '"'); // 解码内部引号
  //
  //     final doc = parse(cleanedHtml);
  //
  //     // 1. 获取章节标题
  //     final title = doc.querySelector('#ctitle .title')?.text.trim() ?? '未知标题';
  //     print('章节标题：$title');
  //
  //     // 2. 获取正文内容
  //     final contentElement = doc.querySelector('#content');
  //     if (contentElement != null) {
  //       // 获取所有内容块（段落）
  //       final paragraphs = contentElement.querySelectorAll('div, h2');
  //
  //       // 先抽取所有文本段落
  //       List<String> texts = paragraphs
  //           .map((e) => e.text.trim())
  //           .where((text) => text.isNotEmpty)
  //           .toList();
  //
  //       // 去重函数（保留顺序）
  //       List<String> deduplicate(List<String> items) {
  //         final seen = <String>{};
  //         final result = <String>[];
  //         for (var text in items) {
  //           if (!seen.contains(text)) {
  //             seen.add(text);
  //             result.add(text);
  //           }
  //         }
  //         return result;
  //       }
  //
  //       // 去重后文本列表
  //       final uniqueTexts = deduplicate(texts);
  //
  //       // 拼接成字符串
  //       final content = uniqueTexts.join('\n\n');
  //
  //       print('去重后章节内容：\n$content');
  //     } else {
  //       print('未找到章节内容');
  //     }
  //   } catch (e) {
  //     print('获取 HTML 失败：$e');
  //   }
  // }

  Future<void> parseBookDetail() async {
    final html = await _controller.runJavaScriptReturningResult(
      'document.documentElement.outerHTML;',
    );

    final doc = parse(html);

    // 获取标题
    final novelTitle =
        doc.querySelector('.book_info h2')?.text.trim() ?? '未知标题';
    print('小说名称：$novelTitle');

    // 获取作者
    final author =
        doc.querySelector('.book_info div > a')?.text.trim() ?? '未知作者';
    print('作者：$author');

    // 获取类型
    final typeElement = doc.querySelectorAll('.book_info div').firstWhere(
          (e) => e.text.contains('类型：'),
          orElse: () => dom.Element.tag('div'),
        );
    final novelType = typeElement.text.replaceAll('类型：', '').trim();
    print('类型：$novelType');

    // 获取封面图地址
    final imgElement = doc.querySelector('.book_info img');
    String imgSrc = imgElement?.attributes['src'] ?? '';
    if (imgSrc.isNotEmpty) {
      if (imgSrc.startsWith('./')) {
        imgSrc = '$indexUrl${imgSrc.substring(2)}';
      } else if (imgSrc.startsWith('/')) {
        final uri = Uri.parse(indexUrl);
        imgSrc = '${uri.scheme}://${uri.host}$imgSrc';
      } else if (!imgSrc.startsWith('http')) {
        final basePath = indexUrl.substring(0, indexUrl.lastIndexOf('/') + 1);
        imgSrc = '$basePath$imgSrc';
      }
    }
    print('封面图地址：$imgSrc');

    // 获取简介
    final introParagraphs = doc.querySelectorAll('.book_info .intro p');
    final intro = introParagraphs.map((p) => p.text.trim()).join('\n');
    print('简介：\n$intro');

    final volumes = parseVolumes(doc);
    // for (var vol in volumes) {
    //   print('卷名：${vol.title}');
    //   for (var chapter in vol.chapters) {
    //     print('章节：${chapter.title}，链接：${chapter.url}');
    //   }
    // }
    print('******   parseBookDetail');
    loadChapterDetail(volumes[0].chapters[1].url);
  }

  void loadBookDetail() async {
    funcType = 'bookdetail';
    _controller.loadRequest(Uri.parse('$indexUrl/book/5763/'));
  }

  void loadChapterDetail(String url) async {
    funcType = 'chapterdetail';
    _controller.loadRequest(Uri.parse('$indexUrl$url'));
  }

  void loadHomeData() async {
    final res = await http.get(Uri.parse('$indexUrl/book/9091/'));
    if (res.statusCode != 200) {
      print('目录页请求失败');
      return;
    }
    // final doc = parse(res.body);
    String decodedBody = utf8.decode(res.bodyBytes);
    final doc = parse(decodedBody);

    final novelTitle = doc.querySelector('.active')?.text.trim() ?? '未知小说';
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
      imgSrc = '$indexUrl' + imgSrc.substring(2); // 去掉 "./"
    }
    print('图片地址：$imgSrc');

    final chapterElements = doc.querySelectorAll('.panel-chapterlist dd a');

    for (var element in chapterElements) {
      final title = element.text.trim();
      final url = element.attributes['href'] ?? '';
      print('$title =>$indexUrl$url');
    }
    var s = chapterElements[1].attributes['href'] ?? '';
    fetchChapterContent('$indexUrl$s');
  }

  Future<void> fetchChapterContent(String url) async {
    print('chaper content url = $url');
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      print('请求失败');
      return;
    }

    final document = parse(utf8.decode(res.bodyBytes));
    final title = document.querySelector('.readTitle')?.text.trim() ?? '未知标题';
    final contentElement = document.querySelector('#htmlContent');

    final unescape = HtmlUnescape();
    final buffer = StringBuffer();

    for (var node in contentElement?.nodes ?? []) {
      // 处理 script 标签中 base64 文本
      if (node.nodeType == Node.ELEMENT_NODE &&
          node is dom.Element &&
          node.localName == 'script') {
        final scriptText = node.text;
        final match = RegExp(r"qsbs\.bb\('(.+?)'\)").firstMatch(scriptText);
        if (match != null) {
          try {
            final base64Str = match.group(1)!;
            final decoded = utf8.decode(base64.decode(base64Str));
            final unescaped = unescape.convert(decoded);

            // 替换 <br> 为换行，&nbsp; 为空格，保留段首缩进
            final cleaned = unescaped
                .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
                .replaceAll('&nbsp;', ' ');

            buffer.writeln(cleaned);
          } catch (e) {
            print('解码失败: $e');
          }
        }
      }
    }

    print('\r\n章节标题：\r$title\n');
    print('\r\n章节正文：\r${buffer.toString()}');
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
