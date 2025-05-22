import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as dom; // ✅ 使用别名 dom
import 'package:html_unescape/html_unescape.dart';

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

  @override
  void initState() {
    super.initState();
    // loadHomeData();
    loadHeTuShu();
  }

  void loadHeTuShu() async {
    // https://www.hetushu.com/book/5763/index.html
    final url = '$indexUrl/book/5763/index.html';
    final res = await http.get(Uri.parse(url), headers: {
      'User-Agent':
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36',
      'Referer':
      'https://www.hetushu.com/book/5763/index.html?__cf_chl_tk=GF6mFPJ3cfbherhtgDXXpIuzkDp5te9.KLjWjz.z8Bc-1747928033-1.0.1.1-jIBlT8VZdgdt1QIXbGcRIBOetoUtTv5TliE0T.oOIhw',
      'Accept':
      'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
      'Accept-Encoding': 'gzip',
      'Accept-Language': 'en,zh-CN;q=0.9,zh;q=0.8',
      'Cookie': '_ga=GA1.1.1297985070.1747926175; '
          'bh=%7B%22path%22%3A%22book%22%2C%22bid%22%3A%225763%22%2C%22bname%22%3A%22%E5%A4%A7%E5%A5%89%E6%89%93%E6%9B%B4%E4%BA%BA%22%2C%22sid%22%3A%224327466%22%2C%22sname%22%3A%22%E7%AC%AC%E4%B8%80%E5%8D%B7%20%E4%BA%AC%E5%AF%9F%E9%A3%8E%E4%BA%91%20%E7%AC%AC%E4%B8%80%E7%AB%A0%20%E7%89%A2%E7%8B%B1%E4%B9%8B%E7%81%BE%22%7D; '
          '_ga_333KCL0K1B=GS2.1.s1747930370\$o2\$g0\$t1747930370\$j0\$l0\$h0; '
          'cf_clearance=cjZ4RyHZq9CtFQ8VfiC6rBKRmupqGKxcw.jWWyPSm_I-1747930374-1.2.1.1-OXfAUEcB3t1.j6RdEN9eqqwPMEvzvK_Gu.VpAUpLXp3nH2gkDS00OCsQvgHZOWIdC87a4ipK5Zp8rkYiXpjxHE4TISWGRU.cksJFTEM9oBBcwxNs5dgdPLWUBWTaBiKFqDyCBDMV30SSGDjlqlwscLzbGhD20FMM15P_MduEyWcj8RJPi0j0ebX75cKpA68_V2XoH_bkEU9qd6AVYBLSBdPRQNw07amuPCS6NE82oerTVUtzbqAGwEGTE1MrpnulW3mc4edoCSAQ_.MMpgzfjfI7KhP0I01pP.391l.WyeT.6h5GZXK9cqCud0UCJv7mJSS44v_aivuoaC67BUzR1j81gx.Ks0hqL0bUFPf2XjWw28qvCwkEpsVm3Ik1FBAJ',
    });
    if (res.statusCode != 200) {
      print('详情页请求失败');
      return;
    }

    String decodedBody = utf8.decode(res.bodyBytes);
    final doc = parse(decodedBody);

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

    // 获取图片地址
    final imgElement = doc.querySelector('.book_info img');
    String imgSrc = imgElement?.attributes['src'] ?? '';

    if (imgSrc.isNotEmpty) {
      if (imgSrc.startsWith('./')) {
        // ./ 开头，去掉 ./ 拼接
        imgSrc = '$indexUrl${imgSrc.substring(2)}';
      } else if (imgSrc.startsWith('/')) {
        // 根路径，拼接域名
        final uri = Uri.parse(indexUrl);
        imgSrc = '${uri.scheme}://${uri.host}$imgSrc';
      } else if (!imgSrc.startsWith('http')) {
        // 其它相对路径，如 "images/pic.jpg"
        final uri = Uri.parse(indexUrl);
        final basePath = indexUrl.substring(0, indexUrl.lastIndexOf('/') + 1);
        imgSrc = '$basePath$imgSrc';
      }
    }
    print('图片地址：$imgSrc');
    // 获取简介内容
    final introParagraphs = doc.querySelectorAll('.book_info .intro p');
    final intro = introParagraphs.map((p) => p.text.trim()).join('\n');
    print('简介：\n$intro');

    final volumes = parseVolumes(doc);
    for (var vol in volumes) {
      print('卷名：${vol.title}');
      for (var chapter in vol.chapters) {
        print('章节：${chapter.title}，链接：${chapter.url}');

        // 这里示例，假设你有获取章节页面 html 的方法 fetchHtml(url)
        // String chapterHtml = await fetchHtml(chapter.url);
        // String content = await parseChapterContent(chapterHtml);
        // print('内容：$content');
      }
    }
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
