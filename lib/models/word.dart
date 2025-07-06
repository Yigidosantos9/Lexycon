class Word {
  final String english;
  final String turkish;
  final List<String> options;

  Word({required this.english, required this.turkish, required this.options});

  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      english: map['english'],
      turkish: map['turkish'],
      options: List<String>.from(map['options']),
    );
  }

  Map<String, dynamic> toMap() {
    return {'english': english, 'turkish': turkish, 'options': options};
  }
}
