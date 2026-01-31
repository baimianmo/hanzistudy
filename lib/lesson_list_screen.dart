
import 'package:flutter/material.dart';
import 'models.dart';
import 'data_repository.dart';
import 'flash_card_screen.dart';

class LessonListScreen extends StatefulWidget {
  final String title;
  final LessonType type;

  const LessonListScreen({
    super.key,
    required this.title,
    required this.type,
  });

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  final DataRepository _repository = DataRepository();
  List<LessonItem> _lessons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    final lessons = await _repository.getLessonList(widget.type);
    if (mounted) {
      setState(() {
        _lessons = lessons;
        _isLoading = false;
      });
    }
  }

  Future<void> _openLesson(LessonItem lesson) async {
    final characters = await _repository.getCharacters(lesson.id);
    if (!mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashCardScreen(
          lessonTitle: lesson.title,
          characters: characters,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _lessons.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final lesson = _lessons[index];
                return ListTile(
                  title: Text(lesson.title),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openLesson(lesson),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                );
              },
            ),
    );
  }
}
