import 'dart:convert';  // 用于 json 编码和解码
import 'package:http/http.dart' as http;

class HttpService {
  static final HttpService _instance = HttpService._internal();
  factory HttpService() => _instance;

  final String baseUrl = "https://json02.heimuer.xyz/api.php/provide/vod/";
  // final String baseUrl = "https://api.apilyzy.com/api.php/provide/vod/";
  // final String baseUrl = "https://lbapi9.com/api.php/provide/vod/";

  HttpService._internal();

  // GET 请求
  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    try {
      final uri = Uri.parse(baseUrl + path).replace(queryParameters: params);  // 使用 replace 添加查询参数
      final response = await http.get(uri, headers: _getHeaders());
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // POST 请求
  Future<dynamic> post(String path, {Map<String, dynamic>? data}) async {
    try {
      final uri = Uri.parse(baseUrl + path);
      final response = await http.post(
        uri,
        headers: _getHeaders(),
        body: json.encode(data),  // 将数据编码为 JSON 字符串
      );
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // PUT 请求
  Future<dynamic> put(String path, {Map<String, dynamic>? data}) async {
    try {
      final uri = Uri.parse(baseUrl + path);
      final response = await http.put(
        uri,
        headers: _getHeaders(),
        body: json.encode(data),  // 将数据编码为 JSON 字符串
      );
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE 请求
  Future<dynamic> delete(String path, {Map<String, dynamic>? data}) async {
    try {
      final uri = Uri.parse(baseUrl + path);
      final response = await http.delete(
        uri,
        headers: _getHeaders(),
        body: json.encode(data),  // 将数据编码为 JSON 字符串
      );
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 获取请求头
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    };
  }

  // 处理响应
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return json.decode(response.body);  // 解码 JSON 响应体
    } else {
      throw Exception("Server Error: ${response.statusCode}");
    }
  }

  // 错误处理
  Exception _handleError(dynamic error) {
    return Exception("Unexpected Error: ${error.toString()}");
  }
}