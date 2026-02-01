import 'package:flutter/material.dart';
import 'data_repository.dart';
import 'models.dart';
import 'services/tts_service.dart';

class OfflineResourcesScreen extends StatefulWidget {
  const OfflineResourcesScreen({super.key});

  @override
  State<OfflineResourcesScreen> createState() => _OfflineResourcesScreenState();
}

class _OfflineResourcesScreenState extends State<OfflineResourcesScreen> {
  final DataRepository _repository = DataRepository();
  bool _isLoading = false;
  double _progress = 0.0;
  String _statusMessage = '';
  int _totalItems = 0;
  int _completedItems = 0;
  List<String> _failedItems = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Resources'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Offline Study Mode',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Download TTS resources for all characters and words to enable offline study with high-quality voice (Aliyun). '
              'If you are using iFlytek Offline TTS, this will ensure the engine is initialized.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            if (_isLoading) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 10),
              Text('Progress: $_completedItems / $_totalItems'),
              Text(_statusMessage),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startDownload,
                  icon: const Icon(Icons.download),
                  label: const Text('Download / Verify Resources'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              if (_statusMessage.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(_statusMessage, style: TextStyle(
                  color: _failedItems.isEmpty ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                )),
              ],
              if (_failedItems.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Failed items:'),
                Expanded(
                  child: ListView.builder(
                    itemCount: _failedItems.length,
                    itemBuilder: (context, index) => Text(_failedItems[index]),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _startDownload() async {
    setState(() {
      _isLoading = true;
      _progress = 0.0;
      _statusMessage = 'Scanning content...';
      _failedItems = [];
      _completedItems = 0;
    });

    try {
      // 1. Get all content
      final literacyLessons = await _repository.getLessonList(LessonType.literacy);
      final writingLessons = await _repository.getLessonList(LessonType.writing);
      
      final Set<String> textsToCache = {};

      for (var lesson in literacyLessons) {
        final chars = await _repository.getCharacters(lesson.id);
        for (var char in chars) {
          textsToCache.add(char.character);
          textsToCache.addAll(char.words);
        }
      }

      // Writing lessons usually overlap, but check anyway
      for (var lesson in writingLessons) {
        final chars = await _repository.getCharacters(lesson.id);
        for (var char in chars) {
          textsToCache.add(char.character);
          textsToCache.addAll(char.words);
        }
      }

      setState(() {
        _totalItems = textsToCache.length;
        _statusMessage = 'Found $_totalItems unique items. Starting download...';
      });

      // 2. Get TTS Service
      final ttsService = await TtsServiceFactory.getService();

      // 3. Iterate and cache
      // We process in chunks to avoid overwhelming the UI or network
      final List<String> allTexts = textsToCache.toList();
      
      // Check if we are using Aliyun, which needs rate limiting
      // But TtsServiceFactory doesn't expose type easily.
      // We'll just be conservative.
      
      for (int i = 0; i < allTexts.length; i++) {
        if (!mounted) return;
        
        final text = allTexts[i];
        try {
          await ttsService.cache(text);
          // Small delay to prevent API rate limiting (especially for Aliyun free tier)
          await Future.delayed(const Duration(milliseconds: 100)); 
        } catch (e) {
          print("Failed to cache '$text': $e");
          _failedItems.add(text);
        }

        setState(() {
          _completedItems = i + 1;
          _progress = _completedItems / _totalItems;
          _statusMessage = 'Downloading: $text';
        });
      }

      setState(() {
        _isLoading = false;
        _statusMessage = _failedItems.isEmpty 
            ? 'Download Completed Successfully!' 
            : 'Completed with ${_failedItems.length} errors.';
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
    }
  }
}
