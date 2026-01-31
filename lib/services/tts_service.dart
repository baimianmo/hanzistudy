import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'iflytek_tts_service.dart';

abstract class TtsService {
  Future<void> speak(String text);
  Future<void> stop();
  Future<void> setLanguage(String language);
}



class TtsServiceFactory {
  static Future<TtsService> getService() async {
    final prefs = await SharedPreferences.getInstance();
    final type = prefs.getString('tts_type') ?? 'system';
    
    if (type == 'aliyun') {
      return AliyunTtsService();
    } else if (type == 'iflytek_offline') {
      return IflytekOfflineTtsService();
    } else {
      return SystemTtsService();
    }
  }
}

class SystemTtsService implements TtsService {
  final FlutterTts flutterTts = FlutterTts();

  SystemTtsService() {
    _init();
  }

  void _init() async {
    await flutterTts.setLanguage("zh-CN");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  @override
  Future<void> speak(String text) async {
    print("TTS: Using SystemTtsService for text: $text");
    Fluttertoast.showToast(msg: "System TTS: $text");
    await flutterTts.speak(text);
  }

  @override
  Future<void> stop() async {
    await flutterTts.stop();
  }
  
  @override
  Future<void> setLanguage(String language) async {
    await flutterTts.setLanguage(language);
  }
}

class AliyunTtsService implements TtsService {
  final AudioPlayer _player = AudioPlayer();
  
  // Cache token
  static String? _accessToken;
  static DateTime? _tokenExpiry;

  @override
  Future<void> speak(String text) async {
    print("TTS: Using AliyunTtsService for text: $text");
    Fluttertoast.showToast(msg: "Aliyun TTS: $text");
    try {
      final prefs = await SharedPreferences.getInstance();
      final appKey = prefs.getString('aliyun_app_key');
      final accessKeyId = prefs.getString('aliyun_access_key_id');
      final accessKeySecret = prefs.getString('aliyun_access_key_secret');

      if (appKey == null || accessKeyId == null || accessKeySecret == null) {
        print("Aliyun keys are missing");
        return; // Or throw exception
      }

      String token = await _getToken(accessKeyId, accessKeySecret);
      
      // URL encode the text
      final encodedText = Uri.encodeComponent(text);
      
      // Construct TTS URL
      // https://nls-gateway-cn-shanghai.aliyuncs.com/stream/v1/tts
      // ?appkey=...&token=...&text=...&format=mp3&sample_rate=16000
      // voice: zhiyue (child voice, good for kids)
      
      final url = "https://nls-gateway-cn-shanghai.aliyuncs.com/stream/v1/tts"
          "?appkey=$appKey"
          "&token=$token"
          "&text=$encodedText"
          "&format=mp3"
          "&sample_rate=16000"
          "&voice=zhiyue"; 

      await _player.play(UrlSource(url));
    } catch (e) {
      print("Error playing Aliyun TTS: $e");
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
  }
  
  @override
  Future<void> setLanguage(String language) async {
    // Aliyun supports mixed, but usually zh-CN is implied by the voice model
  }

  Future<String> _getToken(String accessKeyId, String accessKeySecret) async {
    if (_accessToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken!;
    }

    // Call Aliyun CreateToken API
    // We need to implement the signature logic here.
    // For simplicity, we'll try to implement the POP signature.
    
    // This is complex to implement correctly without extensive testing.
    // Alternative: User inputs the Token directly in settings for now?
    // Or we assume the user has a way to get a token.
    
    // Let's try to implement a basic signature or fallback.
    // Documentation: https://help.aliyun.com/document_detail/454228.html
    
    final params = {
      'AccessKeyId': accessKeyId,
      'Action': 'CreateToken',
      'Format': 'JSON',
      'RegionId': 'cn-shanghai',
      'SignatureMethod': 'HMAC-SHA1',
      'SignatureNonce': DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(10000).toString(),
      'SignatureVersion': '1.0',
      'Timestamp': DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(DateTime.now().toUtc()),
      'Version': '2019-02-28',
    };

    // Sort keys
    final sortedKeys = params.keys.toList()..sort();
    final canonicalizedQueryString = sortedKeys.map((key) {
      return '${Uri.encodeComponent(key)}=${Uri.encodeComponent(params[key]!)}';
    }).join('&');

    final stringToSign = 'GET&%2F&${Uri.encodeComponent(canonicalizedQueryString)}';

    final hmacSha1 = Hmac(sha1, utf8.encode('$accessKeySecret&')); // Note the trailing &
    final signature = base64Encode(hmacSha1.convert(utf8.encode(stringToSign)).bytes);

    final requestUrl = 'http://nls-meta.cn-shanghai.aliyuncs.com/?$canonicalizedQueryString&Signature=${Uri.encodeComponent(signature)}';

    final response = await http.get(Uri.parse(requestUrl));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['Token'] != null && data['Token']['Id'] != null) {
        _accessToken = data['Token']['Id'];
        _tokenExpiry = DateTime.now().add(Duration(seconds: data['Token']['ExpireTime'] - 60)); // Buffer
        return _accessToken!;
      }
    }
    
    throw Exception("Failed to get Aliyun Token: ${response.body}");
  }
}
