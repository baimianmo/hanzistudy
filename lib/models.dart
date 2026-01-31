
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
    var list = json['characters'] as List;
    List<HanziChar> charactersList =
        list.map((i) => HanziChar.fromJson(i)).toList();

    return LessonData(
      grade: json['grade'],
      publisher: json['publisher'],
      lesson: json['lesson'],
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

  HanziChar({
    required this.character,
    required this.pinyin,
    required this.strokeOrder,
    required this.words,
  });

  factory HanziChar.fromJson(Map<String, dynamic> json) {
    return HanziChar(
      character: json['character'],
      pinyin: json['pinyin'],
      strokeOrder: json['stroke_order'],
      words: List<String>.from(json['words']),
    );
  }
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
