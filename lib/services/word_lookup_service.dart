// services/word_lookup_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';

class WordInfo {
  final String meaning;
  final String pronunciation;

  WordInfo({required this.meaning, required this.pronunciation});
}

class WordLookupService {
  static Map<String, dynamic> _data = {};

  static Future<void> init() async {
    final content = await rootBundle.loadString('assets/word_choices_tr.json');
    _data = jsonDecode(content);
  }

  static WordInfo getInfo(String word) {
    final entry = _data[word];
    if (entry != null) {
      final translation = entry['translation'] ?? '-';
      final pronunciation = _generatePronunciation(word);
      return WordInfo(meaning: translation, pronunciation: pronunciation);
    } else {
      return WordInfo(meaning: '-', pronunciation: '-');
    }
  }

  static String _generatePronunciation(String word) {
    // Basit bir simülasyon. Daha gelişmiş sistemlerde gerçek fonetik çekilebilir.
    return word.split('').join('-'); // Örn: "apple" → a-p-p-l-e
  }
}
