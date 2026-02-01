import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'data_repository.dart';
import 'models.dart';
import 'package:intl/intl.dart';
import 'game_scope_screen.dart';

class StudyPlanScreen extends StatefulWidget {
  const StudyPlanScreen({super.key});

  @override
  State<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends State<StudyPlanScreen> {
  final DataRepository _repository = DataRepository();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<StudyRecord> _allRecords = [];
  Map<DateTime, List<StudyRecord>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await _repository.getStudyRecords();
    setState(() {
      _allRecords = records;
      _groupRecords();
    });
  }

  void _groupRecords() {
    _events = {};
    for (var record in _allRecords) {
      // Normalize date to UTC or local midnight for comparison
      final date = DateTime(record.date.year, record.date.month, record.date.day);
      if (_events[date] == null) _events[date] = [];
      _events[date]!.add(record);
    }
  }

  List<StudyRecord> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _events[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final selectedRecords = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];
    
    // Calculate daily stats
    int totalPracticeCount = selectedRecords.length; // Each record is a session entry per lesson
    // Note: If a single session spans multiple lessons, it creates multiple records. 
    // This is fine, "Practice Count" can mean "Lesson-Sessions".
    
    int totalChars = selectedRecords.fold<int>(0, (sum, r) => (sum + r.characterCount).toInt());
    int totalCorrect = selectedRecords.fold<int>(0, (sum, r) => (sum + r.correctCount).toInt());
    int totalWrong = selectedRecords.fold<int>(0, (sum, r) => (sum + r.wrongCount).toInt());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Plan & History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configure Study Scope',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GameScopeScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getEventsForDay,
            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.orangeAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const Divider(),
          // Daily Summary
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text("Daily Summary", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem("Lessons", "$totalPracticeCount"),
                    _buildStatItem("Chars", "$totalChars"),
                    _buildStatItem("Correct", "$totalCorrect", Colors.green),
                    _buildStatItem("Errors", "$totalWrong", Colors.red),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: selectedRecords.isEmpty 
                ? const Center(child: Text("No practice records for this day"))
                : ListView.builder(
                    itemCount: selectedRecords.length,
                    itemBuilder: (context, index) {
                      final record = selectedRecords[index];
                      return ListTile(
                        leading: const Icon(Icons.history_edu),
                        title: Text(record.lessonTitle),
                        subtitle: Text(DateFormat('HH:mm').format(record.date)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("Correct: ${record.correctCount}", style: const TextStyle(color: Colors.green, fontSize: 12)),
                            Text("Wrong: ${record.wrongCount}", style: const TextStyle(color: Colors.red, fontSize: 12)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, [Color? color]) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
