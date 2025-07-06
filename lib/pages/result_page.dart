import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/word_lookup_service.dart';

class ResultPage extends StatefulWidget {
  final int score;
  final int total;
  final List<Map<String, dynamic>> wrongAnswers;

  const ResultPage({
    super.key,
    required this.score,
    required this.total,
    required this.wrongAnswers,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  late FlutterTts flutterTts;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
  }

  void speak(String word) async {
    await flutterTts.stop();
    await flutterTts.speak(word);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Result')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Score: ${widget.score}/${widget.total}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              "Wrong Answers:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: widget.wrongAnswers.length,
                itemBuilder: (context, index) {
                  final word = widget.wrongAnswers[index]['word'];
                  final meaning = WordLookupService.getInfo(word).meaning;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(
                        word,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text("Meaning: $meaning"),
                      trailing: IconButton(
                        icon: const Icon(Icons.volume_up),
                        onPressed: () => speak(word),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
