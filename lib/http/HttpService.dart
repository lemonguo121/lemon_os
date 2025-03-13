import 'dart:convert'; // 用于 json 编码和解码
import 'package:http/http.dart' as http;
import 'package:lemon_tv/util/SubscriptionsUtil.dart';
import 'package:xml/xml.dart';
import '../util/SPManager.dart'; // 导入 SPManager 用于获取当前站点

class HttpService {
  static final HttpService _instance = HttpService._internal();

  factory HttpService() => _instance;

  // final String baseUrl = "https://json.heimuer.xyz/api.php/provide/vod/";
  // final String baseUrl = "https://json02.heimuer.xyz/api.php/provide/vod/";
  // // final String baseUrl = "https://ikunzyapi.com/api.php/provide/vod/from/ikm3u8/";
  // // final String baseUrl = "https://lbapi9.com/api.php/provide/vod/";

  static String baseUrl = ""; // 将 baseUrl 设置为静态变量
  static int paresType = 1; //解析类型

  HttpService._internal();

  // 更新 baseUrl
  static Future<void> updateBaseUrl(String newBaseUrl) async {
    baseUrl = newBaseUrl;
  }

  // GET 请求
  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    try {
      var currentSite = await SPManager.getCurrentSite();
      // 设置选中状态，如果有当前选中的站点
      if (currentSite != null) {
        baseUrl = currentSite.api;
        paresType = currentSite.type;
      }
      final uri = Uri.parse(baseUrl + path)
          .replace(queryParameters: params); // 使用 replace 添加查询参数
      print("uri = $uri");
      final response = await http.get(uri, headers: _getHeaders());
      return _handleResponse(response, paresType);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> getBySubscription(
      String storehouse, int paresType, String path,
      {Map<String, dynamic>? params}) async {
    try {
      final uri = Uri.parse(storehouse ?? baseUrl + path)
          .replace(queryParameters: params); // 使用 replace 添加查询参数
      final response = await http.get(uri, headers: _getHeaders());
      return _handleResponse(response, paresType);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // POST 请求
  Future<dynamic> post(int subscription, String path,
      {Map<String, dynamic>? data}) async {
    try {
      final uri = Uri.parse(baseUrl + path);
      final response = await http.post(
        uri,
        headers: _getHeaders(),
        body: json.encode(data), // 将数据编码为 JSON 字符串
      );
      return _handleResponse(response, subscription);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // PUT 请求
  Future<dynamic> put(int paresType, String path,
      {Map<String, dynamic>? data}) async {
    try {
      final uri = Uri.parse(baseUrl + path);
      final response = await http.put(
        uri,
        headers: _getHeaders(),
        body: json.encode(data), // 将数据编码为 JSON 字符串
      );
      return _handleResponse(response, paresType);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE 请求
  Future<dynamic> delete(int paresType, String path,
      {Map<String, dynamic>? data}) async {
    try {
      final uri = Uri.parse(baseUrl + path);
      final response = await http.delete(
        uri,
        headers: _getHeaders(),
        body: json.encode(data), // 将数据编码为 JSON 字符串
      );
      return _handleResponse(response, paresType);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 获取请求头
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    };
  }

  dynamic _handleResponse(http.Response response, int paresType) {
    if (response.statusCode == 200) {
      // 使用 UTF-8 解码，避免中文乱码
      String decodedBody = utf8.decode(response.bodyBytes);
      // **方法 1：根据 Content-Type 头部判断**
      if (paresType == 1) {
        return json.decode(decodedBody);
      } else if (paresType == 0) {
        return XmlDocument.parse(decodedBody);
      } else {
        throw Exception("Unknown response format");
      }
    } else {
      throw Exception("Server Error: ${response.statusCode}");
    }
  }

  // 错误处理
  Exception _handleError(dynamic error) {
    return Exception("Unexpected Error: ${error.toString()}");
  }

  Future<dynamic> getUrl(String subscriptionUrl) async {
    try {
      final uri = Uri.parse(subscriptionUrl); // 使用 replace 添加查询参数

      final response = await http.get(uri, headers: _getHeaders());
      return _handleUrlResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  dynamic _handleUrlResponse(http.Response response) {
    if (response.statusCode == 200) {
      // 使用 UTF-8 解码，避免中文乱码
      String decodedBody = utf8.decode(response.bodyBytes);
      // **方法 1：根据 Content-Type 头部判断**
      return json.decode(decodedBody);
    } else {
      throw Exception("Server Error: ${response.statusCode}");
    }
  }
}
