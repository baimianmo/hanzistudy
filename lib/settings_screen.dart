import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTts = 'system';
  final TextEditingController _appKeyController = TextEditingController();
  final TextEditingController _accessKeyIdController = TextEditingController();
  final TextEditingController _accessKeySecretController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTts = prefs.getString('tts_type') ?? 'system';
      _appKeyController.text = prefs.getString('aliyun_app_key') ?? '';
      _accessKeyIdController.text = prefs.getString('aliyun_access_key_id') ?? '';
      _accessKeySecretController.text = prefs.getString('aliyun_access_key_secret') ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tts_type', _selectedTts);
    await prefs.setString('aliyun_app_key', _appKeyController.text.trim());
    await prefs.setString('aliyun_access_key_id', _accessKeyIdController.text.trim());
    await prefs.setString('aliyun_access_key_secret', _accessKeySecretController.text.trim());
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('设置已保存 / Settings Saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置 / Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            '语音合成设置 / TTS Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          RadioListTile<String>(
            title: const Text('系统内置语音 (System TTS)'),
            subtitle: const Text('免费，不需要网络，但音质可能较差'),
            value: 'system',
            groupValue: _selectedTts,
            onChanged: (value) {
              setState(() {
                _selectedTts = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('阿里云智能语音 (Aliyun TTS)'),
            subtitle: const Text('音质更好，需要网络和API Key'),
            value: 'aliyun',
            groupValue: _selectedTts,
            onChanged: (value) {
              setState(() {
                _selectedTts = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('讯飞离线语音 (iFlytek Offline)'),
            subtitle: const Text('离线，需要下载SDK'),
            value: 'iflytek_offline',
            groupValue: _selectedTts,
            onChanged: (value) {
              setState(() {
                _selectedTts = value!;
              });
            },
          ),
          if (_selectedTts == 'aliyun') ...[
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '阿里云配置 (Aliyun Configuration)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _appKeyController,
                      decoration: const InputDecoration(
                        labelText: 'AppKey',
                        border: OutlineInputBorder(),
                        hintText: 'Your Aliyun AppKey',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _accessKeyIdController,
                      decoration: const InputDecoration(
                        labelText: 'AccessKey ID',
                        border: OutlineInputBorder(),
                        hintText: 'Your AccessKey ID',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _accessKeySecretController,
                      decoration: const InputDecoration(
                        labelText: 'AccessKey Secret',
                        border: OutlineInputBorder(),
                        hintText: 'Your AccessKey Secret',
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '注意：请确保您已开通阿里云智能语音交互服务 (Intelligent Speech Interaction) 并获取了相关密钥。',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('保存 / Save'),
          ),
        ],
      ),
    );
  }
}
