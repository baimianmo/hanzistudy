
class FileMappingResponse {
  final MappingTypes mapping;
  final String grade;
  final String publisher;

  FileMappingResponse({
    required this.mapping,
    required this.grade,
    required this.publisher,
  });

  factory FileMappingResponse.fromJson(Map<String, dynamic> json) {
    return FileMappingResponse(
      mapping: MappingTypes.fromJson(json['file_mapping']),
      grade: json['grade'],
      publisher: json['publisher'],
    );
  }
}

class MappingTypes {
  final Map<String, String> literacyTable;
  final Map<String, String> writingTable;

  MappingTypes({
    required this.literacyTable,
    required this.writingTable,
  });

  factory MappingTypes.fromJson(Map<String, dynamic> json) {
    return MappingTypes(
      literacyTable: Map<String, String>.from(json['识字表']),
      writingTable: Map<String, String>.from(json['写字表']),
    );
  }
}

class LessonData {
  final String grade;
  final String publisher;
  final String lesson;
  final String category;
  final List<HanziChar> characters;

  LessonData({
    required this.grade,
    required this.publisher,
    required this.lesson,
    required this.category,
    required this.characters,
  });

  factory LessonData.fromJson(Map<String, dynamic> json) {
    String lessonName = json['lesson'];
    var list = json['characters'] as List;
    List<HanziChar> charactersList =
        list.map((i) => HanziChar.fromJson(i, lessonName)).toList();

    return LessonData(
      grade: json['grade'],
      publisher: json['publisher'],
      lesson: lessonName,
      category: json['category'],
      characters: charactersList,
    );
  }
}

class HanziChar {
  final String character;
  final String pinyin;
  final String strokeOrder;
  final List<String> words;
  final String? lessonName;

  HanziChar({
    required this.character,
    required this.pinyin,
    required this.strokeOrder,
    required this.words,
    this.lessonName,
  });

  factory HanziChar.fromJson(Map<String, dynamic> json, [String? lessonName]) {
    return HanziChar(
      character: json['character'],
      pinyin: json['pinyin'],
      strokeOrder: json['stroke_order'],
      words: List<String>.from(json['words']),
      lessonName: lessonName,
    );
  }
}

class StudyRecord {
  final DateTime date;
  final String lessonTitle;
  final int characterCount;
  final int correctCount;
  final int wrongCount;
  final int practiceCount;

  StudyRecord({
    required this.date,
    required this.lessonTitle,
    required this.characterCount,
    required this.correctCount,
    required this.wrongCount,
    this.practiceCount = 1,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'lessonTitle': lessonTitle,
        'characterCount': characterCount,
        'correctCount': correctCount,
        'wrongCount': wrongCount,
        'practiceCount': practiceCount,
      };

  factory StudyRecord.fromJson(Map<String, dynamic> json) => StudyRecord(
        date: DateTime.parse(json['date']),
        lessonTitle: json['lessonTitle'],
        characterCount: json['characterCount'],
        correctCount: json['correctCount'],
        wrongCount: json['wrongCount'],
        practiceCount: json['practiceCount'] ?? 1,
      );
}

enum LessonType {
  literacy, // 识字表
  writing // 写字表
}

class LessonItem {
  final String id; // filename
  final String title;
  final LessonType type;

  LessonItem({
    required this.id,
    required this.title,
    required this.type,
  });
}
