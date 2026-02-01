import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'tts_service.dart';

class IflytekOfflineTtsService implements TtsService {
  static const MethodChannel _channel = MethodChannel('com.hanzicard/tts');
  bool _isInitialized = false;
  double _currentRate = 1.0;

  @override
  Future<void> speak(String text) async {
    print("TTS: Using IflytekOfflineTtsService for text: $text");
    // Fluttertoast.showToast(msg: "iFlytek TTS: $text");
    if (!_isInitialized) {
      await _init();
    }
    try {
      await _channel.invokeMethod('speak', {'text': text});
    } catch (e) {
      print("Iflytek Offline TTS Speak Error: $e");
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
    } catch (e) {
      print("Iflytek Offline TTS Stop Error: $e");
    }
  }

  @override
  Future<void> setLanguage(String language) async {
    // Offline TTS language is usually determined by the loaded resource (jet file)
    // So we might not support dynamic language switching unless multiple resources are loaded.
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    _currentRate = rate;
    if (_isInitialized) {
      int speed = (rate * 50).toInt().clamp(0, 100);
      try {
        await _channel.invokeMethod('setSpeed', {'speed': speed});
      } catch (e) {
        print("Iflytek Offline TTS SetSpeed Error: $e");
      }
    }
  }

  @override
  Future<void> cache(String text) async {
    // iFlytek is offline by default, no per-text caching needed.
    // We ensure initialization (resource copying) is done.
    if (!_isInitialized) {
      await _init();
    }
  }

  Future<void> _init() async {
    if (_isInitialized) return;

    try {
      // Request necessary permissions
      await _requestPermissions();

      // Copy assets to local storage for the native SDK to access
      final String commonPath = await _copyAsset('assets/iflytek/common.jet');
      final String voicePath = await _copyAsset('assets/iflytek/xiaoyan.jet'); // Assuming xiaoyan

      await _channel.invokeMethod('init', {
        'commonPath': commonPath,
        'voicePath': voicePath,
      });
      _isInitialized = true;
      
      // Apply current rate
      await setSpeechRate(_currentRate);
    } catch (e) {
      print("Iflytek Offline TTS Init Error: $e");
    }
  }

  Future<void> _requestPermissions() async {
    // Request permissions required by iFlytek SDK
    Map<Permission, PermissionStatus> statuses = await [
      Permission.phone,
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();

    print("Permissions status: $statuses");
  }

  Future<String> _copyAsset(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Directory docDir = await getApplicationDocumentsDirectory();
      final String fileName = assetPath.split('/').last;
      final File file = File('${docDir.path}/$fileName');

      if (!await file.exists()) {
        await file.writeAsBytes(data.buffer.asUint8List());
        print("Copied asset $assetPath to ${file.path}");
      } else {
        // Always overwrite to ensure latest version is used (fixes 24108 if assets updated)
        await file.writeAsBytes(data.buffer.asUint8List());
        print("Overwrote asset $assetPath to ${file.path}");
      }
      return file.path;
    } catch (e) {
      print("Error copying asset $assetPath: $e");
      return "";
    }
  }
}
