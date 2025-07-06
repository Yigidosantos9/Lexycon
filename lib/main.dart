// main.dart
import 'package:flutter/material.dart';
import 'package:language_app/services/question_service.dart';
import 'package:language_app/services/stats_service.dart';
import 'package:language_app/services/word_lookup_service.dart';
import 'package:language_app/services/movie_phrases_service.dart';
import 'pages/home_page.dart';
import 'pages/quiz_page.dart';
import 'pages/result_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await QuestionService.loadWords();
  await WordLookupService.init(); // ✅ Bunu ekle
  await StatsService.init();

  // Import movie phrases from JSON file
  await MoviePhrasesService.importMoviePhrasesFromJson();

  // Burada test amaçlı kelimeleri yazdıralım:
  //print("Loaded words: ${QuestionService.allWords.take(10)}");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily English',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 16),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}
