// services/question_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuestionService {
  static Map<String, dynamic> wordData = {};
  static List<String> wordOrder = [];

  static Future<void> loadWords() async {
    final data = await rootBundle.loadString('assets/word_choices_tr.json');
    wordData = jsonDecode(data);
    wordOrder = wordData.keys.toList();
  }

  static Future<List<Map<String, dynamic>>> getNextQuizQuestions(
    int count,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    int currentIndex = prefs.getInt('quiz_word_index') ?? 0;
    if (currentIndex >= wordOrder.length) {
      currentIndex = 0;
    }
    final endIndex = (currentIndex + count).clamp(0, wordOrder.length);
    final quizWords = wordOrder.sublist(currentIndex, endIndex);
    return quizWords.map((word) {
      final value = wordData[word];
      return {
        'word': word,
        'correct': value['translation'],
        'options': [...value['options'], value['translation']]..shuffle(),
      };
    }).toList();
  }

  static Future<void> resetQuizProgress() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('quiz_word_index', 0);
  }

  static Future<void> advanceQuizIndex(int count) async {
    final prefs = await SharedPreferences.getInstance();
    int currentIndex = prefs.getInt('quiz_word_index') ?? 0;
    int newIndex = (currentIndex + count).clamp(0, wordOrder.length);
    prefs.setInt('quiz_word_index', newIndex);
  }
}
