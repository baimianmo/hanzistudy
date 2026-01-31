
import 'dart:convert';
import 'package:flutter/services.dart';
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
}
