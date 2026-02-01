import 'package:flutter/material.dart';
import 'data_repository.dart';
import 'models.dart';

class GameScopeScreen extends StatefulWidget {
  const GameScopeScreen({super.key});

  @override
  State<GameScopeScreen> createState() => _GameScopeScreenState();
}

class _GameScopeScreenState extends State<GameScopeScreen> {
  final DataRepository _repository = DataRepository();
  List<LessonItem> _allLessons = [];
  Set<String> _selectedLessonIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final lessons = await _repository.getLessonList(LessonType.literacy);
      final savedScope = await _repository.getGameScope();
      
      setState(() {
        _allLessons = lessons;
        _selectedLessonIds = savedScope.toSet();
        
        // If no scope saved, default to first 5 lessons or all if less
        if (_selectedLessonIds.isEmpty && lessons.isNotEmpty) {
          // Default empty or maybe select none?
          // Let's keep it empty, meaning "user hasn't configured yet".
          // The game logic will handle empty by defaulting to first 10.
        }
        
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading config data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAndExit() async {
    await _repository.saveGameScope(_selectedLessonIds.toList());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved study scope successfully')),
      );
      Navigator.pop(context);
    }
  }

  void _toggleAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedLessonIds = _allLessons.map((e) => e.id).toSet();
      } else {
        _selectedLessonIds.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configure Study Scope'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAndExit,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                CheckboxListTile(
                  title: const Text('Select All Lessons'),
                  value: _allLessons.isNotEmpty && _selectedLessonIds.length == _allLessons.length,
                  onChanged: _toggleAll,
                  tristate: true, // Allow partial state if needed, but for "Select All" bool is fine
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: _allLessons.length,
                    itemBuilder: (context, index) {
                      final lesson = _allLessons[index];
                      final isSelected = _selectedLessonIds.contains(lesson.id);
                      return CheckboxListTile(
                        title: Text(lesson.title),
                        subtitle: Text(lesson.id),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedLessonIds.add(lesson.id);
                            } else {
                              _selectedLessonIds.remove(lesson.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
