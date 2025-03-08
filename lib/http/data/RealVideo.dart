import 'package:xml/src/xml/nodes/document.dart';
import 'package:xml/xml.dart';
import 'package:html/parser.dart' as html_parser;

class RealVideo {
  final int vodId;
  final String vodName;
  final String vodSub;
  final String vodPic;
  final String vodActor;
  final String vodBlurb;
  final String vodRemarks;
  final String vodPubdate;
  final String vodArea;
  final String vodYear;
  final String typeName;
  final String vodPlayUrl;
  final int typePid;
  final String subscriptionDomain;

  // 构造函数名称应与类名一致
  RealVideo({
    required this.vodId,
    required this.vodName,
    required this.vodSub,
    required this.vodPic,
    required this.vodActor,
    required this.vodBlurb,
    required this.vodRemarks,
    required this.vodPubdate,
    required this.vodArea,
    required this.typeName,
    required this.vodYear,
    required this.vodPlayUrl,
    required this.typePid,
    required this.subscriptionDomain,
  });

  // <video>
  // <last>2025-03-07 22:21:12</last>
  // <id>99391</id>
  // <tid>13</tid>
  // <name><![CDATA[仁心俱乐部]]></name>
  // <type>国产剧</type>
  // <pic>
  // https://ok.zuidapic.com/upload/vod/20250306-1/4cf71854540daf0caba1b90340ce20a5.jpg
  // </pic>
  // <lang>国语</lang>
  // <area>中国大陆</area>
  // <year>2025</year>
  // <state></state>
  // <note><![CDATA[更新第13集]]></note>
  // <actor>
  // <![CDATA[辛芷蕾,白客,张子贤,姚安娜,师铭泽,王秀竹,李孝谦,刘润南,赵昭仪,乔大韦,曹瑞,姚安濂,鄂靖文,句号,邹德江,田岷,王超,李沐风,艾米,银雪,胡嘉欣,陈冠甯,于小彬,隋咏良,柳明明,刘曔]]></actor>
  // <director><![CDATA[田宇]]></director>
  // <dl>
  // <dd flag="zuidam3u8">
  // <![CDATA[第01集$https://v5.daayee.com/yyv5/202503/02/baL9YYGmHB22/video/index.m3u8#第02集$https://v3.daayee.com/yyv3/202503/02/hzu1jWzzDX23/video/index.m3u8#第03集$https://v2.daayee.com/yyv2/202503/02/a8M21iCCC824/video/index.m3u8#第04集$https://v3.daayee.com/yyv3/202503/02/P9hD5bVmhB21/video/index.m3u8#第05集$https://v2.daayee.com/yyv2/202503/03/FpDrEfZjBH22/video/index.m3u8#第06集$https://v6.daayee.com/yyv6/202503/03/Nsf7jDFwMb19/video/index.m3u8#第07集$https://v6.daayee.com/yyv6/202503/04/mi0NdjdDsZ21/video/index.m3u8#第08集$https://v4.daayee.com/yyv4/202503/04/XDgeLKFMEL19/video/index.m3u8#第09集$https://v5.daayee.com/yyv5/202503/05/TNSJcxzmHC24/video/index.m3u8#第10集$https://v2.daayee.com/yyv2/202503/05/HPEdJME1p922/video/index.m3u8#第11集$https://v2.daayee.com/yyv2/202503/06/Sv0TdJmgQu23/video/index.m3u8#第12集$https://v6.daayee.com/yyv6/202503/06/fbeD667FxB22/video/index.m3u8#第13集$https://v2.daayee.com/yyv2/202503/07/R27Xux26h121/video/index.m3u8]]></dd>
  // </dl>
  // <des>
  // <![CDATA[<p><span style="color: rgb(17, 17, 17); font-family: Helvetica, Arial, sans-serif; font-size: 13px; background-color: rgb(255, 255, 255);">　该剧讲述了飒爽的神外医生刘梓懿（辛芷蕾 饰）在与男友准备结婚之际，发现男友因特殊原因被送到自己工作的医院，备受打击却要体面地结束这段关系；乐观的心外医生秦文彬（白客 饰）看似玩世不恭，实则心里有数，工作上一帆风顺，婚姻却亮起红灯，不知何去何从。</span></p>]]></des>
  // </video>
  factory RealVideo.fromXml(XmlElement element, subscriptionDomain) {
    final ddElements = element.findAllElements('dd');
    final vodPlayUrl = ddElements.isNotEmpty
        ? ddElements.first.text
        : ''; // 处理找不到 `dd` 的情况，防止异常

    final rawDescription = element.findElements('des').single.text;
    final parsedDescription = html_parser.parse(rawDescription).body?.text ?? '';
    return RealVideo(
        vodId: int.parse(element.findElements('id').single.text),
        vodName: element.findElements('name').single.text,
        vodSub: element.findElements('name').single.text,
        vodPic: element.findElements('pic').single.text,
        vodActor: element.findElements('actor').single.text,
        vodBlurb: parsedDescription,
        vodRemarks: element.findElements('note').single.text,
        vodPubdate: element.findElements('last').single.text,
        vodArea: element.findElements('area').single.text,
        typeName: element.findElements('type').single.text,
        vodYear: element.findElements('year').single.text,
        vodPlayUrl: vodPlayUrl,
        typePid: int.parse(element.findElements('tid').single.text),
        subscriptionDomain: subscriptionDomain);
  }

  // 从JSON解析
  factory RealVideo.fromJson(Map<String, dynamic> json, subscriptionDomain) {
    return RealVideo(
      vodId: json['vod_id'] ?? 0,
      vodName: json['vod_name'] ?? '',
      vodSub: json['vod_sub'] ?? '',
      vodPic: json['vod_pic'] ?? '',
      vodActor: json['vod_actor'] ?? '',
      vodBlurb: json['vod_blurb'] ?? '',
      vodRemarks: json['vod_remarks'] ?? '',
      vodPubdate: json['vod_pubdate'] ?? '',
      vodArea: json['vod_area'] ?? '',
      typeName: json['type_name'] ?? '',
      vodYear: json['vod_year'] ?? '未知年份',
      vodPlayUrl: json['vod_play_url'] ?? '',
      typePid: json['type_id_1'] ?? '',
      subscriptionDomain: subscriptionDomain,
    );
  }

  // 将 RealVideo 对象转换为 JSON 字符串
  Map<String, dynamic> toJson() {
    return {
      'vodId': vodId,
      'vodName': vodName,
      'vodSub': vodSub,
      'vodPic': vodPic,
      'vodActor': vodActor,
      'vodBlurb': vodBlurb,
      'vodBlurb': vodBlurb,
      'vodRemarks': vodRemarks,
      'vodPubdate': vodPubdate,
      'vodArea': vodArea,
      'vodYear': vodYear,
      'typeName': typeName,
      'vodPlayUrl': vodPlayUrl,
      'typePid': typePid,
      'subscriptionDomain': subscriptionDomain,
    };
  }

  factory RealVideo.fromJson2(Map<String, dynamic> json) {
    return RealVideo(
      vodId: json['vodId'],
      vodName: json['vodName'],
      vodSub: json['vodSub'],
      vodPic: json['vodPic'],
      vodActor: json['vodActor'],
      vodBlurb: json['vodBlurb'],
      vodRemarks: json['vodRemarks'],
      vodPubdate: json['vodPubdate'],
      vodArea: json['vodArea'],
      vodYear: json['vodYear'],
      typeName: json['typeName'],
      vodPlayUrl: json['vodPlayUrl'],
      typePid: json['typePid'],
      subscriptionDomain: json['subscriptionDomain'],
    );
  }
}

class RealResponseData {
  final int code;
  final String msg;
  List<RealVideo> videos;

  RealResponseData({
    required this.code,
    required this.msg,
    required this.videos,
  });

  static RealResponseData empty() {
    return RealResponseData(
      code: 0,
      msg: '',
      videos: [], // 空的搜索结果列表
    );
  }

  // 从JSON解析
  factory RealResponseData.fromJson(
      Map<String, dynamic> json, subscriptionDomain) {
    var list = json['list'] as List;
    List<RealVideo> videosList =
        list.map((i) => RealVideo.fromJson(i, subscriptionDomain)).toList();

    return RealResponseData(
      code: json['code'],
      msg: json['msg'],
      videos: videosList,
    );
  }

  factory RealResponseData.fromXml(
      XmlDocument document, String subscriptionDomain) {
    final videoList = document.findAllElements('video').map((element) {
      return RealVideo.fromXml(element, subscriptionDomain);
    }).toList();

    return RealResponseData(
      code: 0,
      msg: "",
      videos: videoList,
    );
  }
}
