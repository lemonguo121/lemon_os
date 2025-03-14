import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';

class AESUtil {
  /// 右填充字符串
  static String rightPadding(String key, String replace, int length) {
    key = key.trim();
    if (key.length > length) {
      return key.substring(0, length);
    } else if (key.length == length) {
      return key;
    } else {
      return key + replace * (length - key.length);
    }
  }

  /// AES ECB 解密
  static String? decryptECB(String data, String key) {
    try {
      key = rightPadding(key, "0", 16);
      final keyBytes = Key.fromUtf8(key);
      final encryptedBytes = Encrypted(fromHex(data)); // 直接传入 List<int>

      final encrypter = Encrypter(AES(keyBytes, mode: AESMode.ecb, padding: "PKCS7"));
      return encrypter.decrypt(encryptedBytes);
    } catch (e) {
      print("AES ECB 解密错误: $e");
      return null;
    }
  }
  /// 16进制字符串转字节数组（Uint8List）
  static Uint8List fromHex(String hex) {
    List<int> bytes = [];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes); // 直接返回 Uint8List
  }
  /// AES CBC 解密
  static String? decryptCBC(String data, String key, String iv) {
    try {
      key = rightPadding(key, "0", 16);
      iv = rightPadding(iv, "0", 16);

      final keyBytes = Key.fromUtf8(key);
      final ivBytes = IV.fromUtf8(iv);
      final encryptedBytes = Encrypted(fromHex(data));

      final encrypter = Encrypter(AES(keyBytes, mode: AESMode.cbc, padding: "PKCS7"));
      return encrypter.decrypt(encryptedBytes, iv: ivBytes);
    } catch (e) {
      print("AES CBC 解密错误: $e");
      return null;
    }
  }

  /// 判断字符串是否为 JSON
  static bool isJson(String content) {
    try {
      json.decode(content);
      return true;
    } catch (e) {
      return false;
    }
  }
}