import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';

import 'iflytek_tts_service.dart';

abstract class TtsService {
  Future<void> speak(String text);
  Future<void> stop();
  Future<void> setLanguage(String language);
  Future<void> setSpeechRate(double rate);
  Future<void> cache(String text);
}

class TtsServiceFactory {
  static Future<TtsService> getService() async {
    final prefs = await SharedPreferences.getInstance();
    final type = prefs.getString('tts_type') ?? 'system';
    final rate = prefs.getDouble('speech_rate') ?? 0.75;
    
    TtsService service;
    if (type == 'aliyun') {
      service = AliyunTtsService();
    } else if (type == 'iflytek_offline') {
      service = IflytekOfflineTtsService();
    } else {
      service = SystemTtsService();
    }
    
    // Apply speech rate
    await service.setSpeechRate(rate);
    
    return service;
  }
}

class SystemTtsService implements TtsService {
  final FlutterTts flutterTts = FlutterTts();

  SystemTtsService() {
    _init();
  }

  void _init() async {
    await flutterTts.setLanguage("zh-CN");
    // Default rate is handled by setSpeechRate called from Factory
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  @override
  Future<void> speak(String text) async {
    print("TTS: Using SystemTtsService for text: $text");
    // Fluttertoast.showToast(msg: "System TTS: $text");
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

  @override
  Future<void> setSpeechRate(double rate) async {
    await flutterTts.setSpeechRate(rate);
  }

  @override
  Future<void> cache(String text) async {
    // System TTS is already offline, no caching needed
  }
}

class AliyunTtsService implements TtsService {
  final AudioPlayer _player = AudioPlayer();
  
  // Cache token
  static String? _accessToken;
  static DateTime? _tokenExpiry;

  Future<File> _getCacheFile(String text) async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/tts_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    // Use md5 of text as filename
    final digest = md5.convert(utf8.encode(text));
    return File('${cacheDir.path}/$digest.mp3');
  }

  @override
  Future<void> speak(String text) async {
    print("TTS: Using AliyunTtsService for text: $text");
    
    // Check cache first
    try {
      final file = await _getCacheFile(text);
      if (await file.exists()) {
        print("Playing from cache: ${file.path}");
        Fluttertoast.showToast(msg: "Aliyun TTS (Offline): $text");
        await _player.play(DeviceFileSource(file.path));
        return;
      }
    } catch (e) {
      print("Cache check failed: $e");
    }

    Fluttertoast.showToast(msg: "Aliyun TTS (Online): $text");
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
  Future<void> cache(String text) async {
    final file = await _getCacheFile(text);
    if (await file.exists()) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final appKey = prefs.getString('aliyun_app_key');
      final accessKeyId = prefs.getString('aliyun_access_key_id');
      final accessKeySecret = prefs.getString('aliyun_access_key_secret');

      if (appKey == null || accessKeyId == null || accessKeySecret == null) {
        throw Exception("Aliyun keys are missing");
      }

      String token = await _getToken(accessKeyId, accessKeySecret);
      final encodedText = Uri.encodeComponent(text);
      final url = "https://nls-gateway-cn-shanghai.aliyuncs.com/stream/v1/tts"
          "?appkey=$appKey"
          "&token=$token"
          "&text=$encodedText"
          "&format=mp3"
          "&sample_rate=16000"
          "&voice=zhiyue";

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
         // Aliyun returns Content-Type: audio/mpeg on success
         if (response.headers['content-type']?.contains('audio') == true) {
            await file.writeAsBytes(response.bodyBytes);
         } else {
            throw Exception("Response is not audio: ${response.body}");
         }
      } else {
         throw Exception("Failed to download audio: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("Error caching Aliyun TTS: $e");
      rethrow;
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

  @override
  Future<void> setSpeechRate(double rate) async {
    // Aliyun supports speech_rate parameter in API
  }

  Future<String> _getToken(String accessKeyId, String accessKeySecret) async {
    if (_accessToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken!;
    }

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
