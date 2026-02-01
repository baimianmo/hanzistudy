
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class DataRepository {
  Future<List<String>> _loadTextOrder() async {
    try {
      final String content =
          await rootBundle.loadString('assets/data/textorder.txt');
      // Split by newline and trim each line to remove potential \r on Windows
      return content.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    } catch (e) {
      print("Error loading textorder.txt: $e");
      return [];
    }
  }

  Future<List<LessonItem>> getLessonList(LessonType type) async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/file_mapping.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final mappingResponse = FileMappingResponse.fromJson(jsonMap);

      final Map<String, String> map = type == LessonType.literacy
          ? mappingResponse.mapping.literacyTable
          : mappingResponse.mapping.writingTable;

      List<LessonItem> lessonList = [];
      map.forEach((title, filename) {
        lessonList.add(LessonItem(
          id: filename,
          title: title,
          type: type,
        ));
      });

      // Load the correct order list
      final List<String> textOrder = await _loadTextOrder();

      if (textOrder.isNotEmpty) {
        // Create a map for O(1) lookup of index
        final Map<String, int> orderMap = {
          for (int i = 0; i < textOrder.length; i++) textOrder[i]: i
        };

        lessonList.sort((a, b) {
          final int indexA = orderMap[a.title] ?? 999;
          final int indexB = orderMap[b.title] ?? 999;
          
          if (indexA != indexB) {
            return indexA.compareTo(indexB);
          }
          
          // Fallback to filename sort if titles not found in order list
          try {
            final RegExp regExp = RegExp(r'-(\d+)\.json');
            final Match? matchA = regExp.firstMatch(a.id);
            final Match? matchB = regExp.firstMatch(b.id);

            if (matchA != null && matchB != null) {
              int numA = int.parse(matchA.group(1)!);
              int numB = int.parse(matchB.group(1)!);
              return numA.compareTo(numB);
            }
          } catch (e) {
            // ignore
          }
          return a.id.compareTo(b.id);
        });
      } else {
        // Fallback to original filename sorting if textorder.txt fails to load
        lessonList.sort((a, b) {
          try {
            final RegExp regExp = RegExp(r'-(\d+)\.json');
            final Match? matchA = regExp.firstMatch(a.id);
            final Match? matchB = regExp.firstMatch(b.id);

            if (matchA != null && matchB != null) {
              int numA = int.parse(matchA.group(1)!);
              int numB = int.parse(matchB.group(1)!);
              return numA.compareTo(numB);
            }
          } catch (e) {
            // ignore
          }
          return a.id.compareTo(b.id);
        });
      }
      
      return lessonList;
    } catch (e) {
      print("Error loading lesson list: $e");
      return [];
    }
  }

  Future<List<HanziChar>> getCharacters(String filename) async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/$filename');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final lessonData = LessonData.fromJson(jsonMap);
      return lessonData.characters;
    } catch (e) {
      print("Error loading characters: $e");
      return [];
    }
  }

  Future<void> saveStudyRecords(List<StudyRecord> newRecords) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> recordsJson = prefs.getStringList('study_records') ?? [];

      for (var record in newRecords) {
        recordsJson.add(json.encode(record.toJson()));
      }

      await prefs.setStringList('study_records', recordsJson);
    } catch (e) {
      print("Error saving study records: $e");
    }
  }

  Future<List<StudyRecord>> getStudyRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> recordsJson = prefs.getStringList('study_records') ?? [];

      return recordsJson
          .map((str) => StudyRecord.fromJson(json.decode(str)))
          .toList();
    } catch (e) {
      print("Error loading study records: $e");
      return [];
    }
  }

  Future<void> saveGameScope(List<String> lessonIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('game_scope_lessons', lessonIds);
    } catch (e) {
      print("Error saving game scope: $e");
    }
  }

  Future<List<String>> getGameScope() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('game_scope_lessons') ?? [];
    } catch (e) {
      print("Error loading game scope: $e");
      return [];
    }
  }
}
