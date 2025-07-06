import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/stats_service.dart';
import '../pages/phrase_info_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../pages/add_phrases_page.dart';

class PhrasesPage extends StatefulWidget {
  final List<Map<String, String>> phrases;
  final Function()? onPhraseAdded;
  const PhrasesPage({super.key, required this.phrases, this.onPhraseAdded});

  @override
  State<PhrasesPage> createState() => _PhrasesPageState();
}

class _PhrasesPageState extends State<PhrasesPage> {
  late FlutterTts flutterTts;
  late List<Map<String, dynamic>> localPhrases;
  late List<Map<String, String>> moviePhrases;
  TextEditingController searchController = TextEditingController();

  final ValueNotifier<List<String>> _categoryNotifier =
      ValueNotifier<List<String>>(['All']);
  final ValueNotifier<List<int>> _masteryNotifier = ValueNotifier<List<int>>([
    -1,
  ]);
  final ValueNotifier<List<Map<String, dynamic>>> _filteredPhrasesNotifier =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  final List<String> categories = [
    'All',
    'Daily',
    'Travel',
    'Work & Study',
    'Special Topics',
    'Uncategorized',
  ];

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
    _loadData();
    _updateFilteredList(); // Initial filter
    searchController.addListener(_updateFilteredList);
    _categoryNotifier.addListener(_updateFilteredList);
    _masteryNotifier.addListener(_updateFilteredList);
  }

  @override
  void dispose() {
    searchController.removeListener(_updateFilteredList);
    _categoryNotifier.removeListener(_updateFilteredList);
    _masteryNotifier.removeListener(_updateFilteredList);
    searchController.dispose();
    _categoryNotifier.dispose();
    _masteryNotifier.dispose();
    _filteredPhrasesNotifier.dispose();
    super.dispose();
  }

  void _loadData() {
    localPhrases = StatsService.getPhrases()
        .map((p) => Map<String, dynamic>.from(p))
        .toList();
    moviePhrases = StatsService.getMoviePhrases();
  }

  void _updateFilteredList() {
    final searchQuery = searchController.text.trim().toLowerCase();
    final selectedCategories = _categoryNotifier.value;
    final selectedMasteries = _masteryNotifier.value;

    final filtered = localPhrases.where((p) {
      final phrase = (p['phrase'] ?? '').toLowerCase();
      final meaning = (p['meaning'] ?? '').toLowerCase();

      List<String> itemCategories;
      final rawCategory = p['category'];
      if (rawCategory is List) {
        itemCategories = rawCategory.map((c) => c.toString()).toList();
      } else if (rawCategory is String) {
        itemCategories = rawCategory.split(',').map((s) => s.trim()).toList();
      } else {
        itemCategories = ['Uncategorized'];
      }

      itemCategories.sort((a, b) {
        int indexA = categories.indexOf(a);
        int indexB = categories.indexOf(b);
        if (indexA == -1) indexA = categories.length;
        if (indexB == -1) indexB = categories.length;
        return indexA.compareTo(indexB);
      });

      final mastery = int.tryParse(p['mastery']?.toString() ?? '-1') ?? -1;
      final matchesSearch =
          searchQuery.isEmpty ||
          phrase.contains(searchQuery) ||
          meaning.contains(searchQuery);

      final matchesCategory =
          selectedCategories.contains('All') ||
          (itemCategories.isNotEmpty &&
              selectedCategories.every(
                (selectedCat) => itemCategories.contains(selectedCat),
              ));

      final matchesMastery =
          selectedMasteries.contains(-1) ||
          selectedMasteries.any((sm) {
            if (sm == 0) return mastery == 0 || mastery == -1;
            return mastery == sm;
          });
      return matchesSearch && matchesCategory && matchesMastery;
    }).toList();
    _filteredPhrasesNotifier.value = filtered;
  }

  void _speak(String text) async {
    await flutterTts.speak(text);
  }

  void _deletePhrase(int index) {
    final phraseToDelete = _filteredPhrasesNotifier.value[index];
    final allPhrases = StatsService.getPhrases()
        .map((p) => Map<String, dynamic>.from(p))
        .toList();

    allPhrases.removeWhere((p) => p['phrase'] == phraseToDelete['phrase']);

    StatsService.savePhrases(allPhrases);

    _loadData();
    _updateFilteredList();
  }

  Future<bool?> _showAddPhraseDialog() async {
    final phraseController = TextEditingController();
    final meaningController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 8,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Add New Phrase',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: phraseController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.short_text),
                          labelText: 'Phrase',
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Please enter a phrase'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: meaningController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.translate),
                          labelText: 'Meaning',
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submitAddPhrase(
                          formKey,
                          phraseController,
                          meaningController,
                          setState,
                          context,
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Please enter a meaning'
                            : null,
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F8EF9),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => _submitAddPhrase(
                          formKey,
                          phraseController,
                          meaningController,
                          setState,
                          context,
                        ),
                        child: const Text('Add'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _submitAddPhrase(
    GlobalKey<FormState> formKey,
    TextEditingController phraseController,
    TextEditingController meaningController,
    void Function(void Function()) setState,
    BuildContext dialogContext,
  ) {
    if (formKey.currentState?.validate() ?? false) {
      final phrase = phraseController.text.trim();
      final meaning = meaningController.text.trim();
      StatsService.addPhrase(phrase, meaning);
      Navigator.pop(dialogContext, true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Phrase added!')));
    } else {
      setState(() {}); // To show validation errors
    }
  }

  void _showCategoryFilterDialog(BuildContext context) async {
    final List<String>? result = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        return _CategoryFilterDialog(
          categories: categories,
          initialSelection: _categoryNotifier.value,
          onApply: (selection) {
            Navigator.pop(context, selection);
          },
          themeColor: const Color(0xFF8E54E9),
          isMultiSelect: true,
        );
      },
    );

    if (result != null) {
      _categoryNotifier.value = result;
    }
  }

  String _masterySelectionText(List<int> selection) {
    if (selection.contains(-1) || selection.isEmpty) {
      return 'All';
    }
    if (selection.length > 1) {
      return '${selection.length} selected';
    }
    final val = selection.first;
    if (val == 0) return 'Unspecified';
    return _MasteryFilterDialogState.masteryLabels[val] ?? '$val Star(s)';
  }

  void _showMasteryFilterDialog(BuildContext context) async {
    final List<int>? result = await showDialog<List<int>>(
      context: context,
      builder: (context) {
        return _MasteryFilterDialog(
          initialSelection: _masteryNotifier.value,
          onApply: (selection) {
            Navigator.pop(context, selection);
          },
          themeColor: const Color(0xFF8E54E9),
        );
      },
    );
    if (result != null) {
      _masteryNotifier.value = result;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 80.0,
            floating: true,
            pinned: false,
            snap: true,
            backgroundColor: const Color(0xFF8E54E9),
            foregroundColor: Colors.white,
            centerTitle: true,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Color(0xFF8E54E9),
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.light,
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Phrases',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6C2AE5), Color(0xFF9443CD)],
                  ),
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            delegate: _FilterHeaderDelegate(
              height: 140,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  children: [
                    // Category and Mastery filters
                    Row(
                      children: [
                        // Category filter
                        Expanded(
                          child: ValueListenableBuilder<List<String>>(
                            valueListenable: _categoryNotifier,
                            builder: (context, value, child) {
                              return InkWell(
                                onTap: () => _showCategoryFilterDialog(context),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Category',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: Text(
                                    value.join(', '),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Mastery filter (stars)
                        Expanded(
                          child: ValueListenableBuilder<List<int>>(
                            valueListenable: _masteryNotifier,
                            builder: (context, value, child) {
                              return InkWell(
                                onTap: () => _showMasteryFilterDialog(context),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Mastery',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: Text(
                                    _masterySelectionText(value),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search phrases...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF8E54E9),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pinned: true,
          ),
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: _filteredPhrasesNotifier,
            builder: (context, filteredPhrases, _) {
              if (filteredPhrases.isEmpty) {
                return SliverToBoxAdapter(
                  child: Container(
                    height: 300,
                    child: const Center(
                      child: Text(
                        'No phrases found.',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final phraseData = filteredPhrases[index];
                    final phrase = phraseData['phrase']?.toString() ?? '';
                    final meaning = phraseData['meaning']?.toString() ?? '';

                    List<String> itemCategories;
                    final rawCategory = phraseData['category'];
                    if (rawCategory is List) {
                      itemCategories = rawCategory
                          .map((c) => c.toString())
                          .toList();
                    } else if (rawCategory is String) {
                      itemCategories = rawCategory
                          .split(',')
                          .map((s) => s.trim())
                          .toList();
                    } else {
                      itemCategories = ['Uncategorized'];
                    }

                    itemCategories.sort((a, b) {
                      int indexA = categories.indexOf(a);
                      int indexB = categories.indexOf(b);
                      if (indexA == -1) indexA = categories.length;
                      if (indexB == -1) indexB = categories.length;
                      return indexA.compareTo(indexB);
                    });

                    final mastery =
                        int.tryParse(
                          phraseData['mastery']?.toString() ?? '-1',
                        ) ??
                        -1;
                    final selectedFilterCategories = _categoryNotifier.value;

                    String displayCategory;
                    if (selectedFilterCategories.contains('All') ||
                        selectedFilterCategories.isEmpty) {
                      displayCategory = itemCategories.first;
                    } else {
                      displayCategory = itemCategories.firstWhere(
                        (c) => selectedFilterCategories.contains(c),
                        orElse: () => itemCategories.first,
                      );
                    }

                    final movieMatch = moviePhrases.firstWhere(
                      (mp) =>
                          mp['phrase'] == phrase && mp['meaning'] == meaning,
                      orElse: () => {},
                    );
                    final hasMovie =
                        movieMatch.isNotEmpty &&
                        (movieMatch['movie']?.isNotEmpty ?? false);
                    final movieName = hasMovie ? movieMatch['movie']! : null;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        leading: const Icon(
                          Icons.format_quote,
                          color: Color(0xFF8E54E9),
                          size: 28,
                        ),
                        title: Text(
                          phrase,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF2D3A7B),
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meaning,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Category: ${itemCategories.join(', ')}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: List.generate(
                                      5,
                                      (i) => Icon(
                                        i <
                                                (int.tryParse(
                                                      phraseData['mastery']
                                                              ?.toString() ??
                                                          '-1',
                                                    ) ??
                                                    -1)
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (hasMovie && movieName != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Color(
                                        0xFF8E54E9,
                                      ).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      movieName,
                                      style: const TextStyle(
                                        color: Color(0xFF8E54E9),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.volume_up,
                                color: Color(0xFF3B4FE0),
                              ),
                              onPressed: () => _speak(phrase),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              tooltip: 'Remove Phrase',
                              onPressed: () {
                                _deletePhrase(index);
                              },
                            ),
                          ],
                        ),
                        onTap: () async {
                          // final phraseMap = filteredPhrases[index];
                          final phraseVal = phraseData['phrase'] ?? '';
                          final meaningVal = phraseData['meaning'] ?? '';
                          // Try to get movie name from SharedPreferences if exists
                          String? movieName;
                          final prefs = await SharedPreferences.getInstance();
                          final extra = prefs.getStringList(
                            'phraseinfo_${phraseVal}_${meaningVal}',
                          );
                          if (extra != null &&
                              extra.length >= 2 &&
                              extra[1].isNotEmpty) {
                            movieName = extra[1];
                          }
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PhraseInfoPage(
                                phrase: phraseVal,
                                meaning: meaningVal,
                                movie: movieName,
                                onDelete: () {
                                  final currentPhrases =
                                      StatsService.getPhrases();
                                  currentPhrases.removeWhere(
                                    (p) =>
                                        p['phrase'] == phraseVal &&
                                        p['meaning'] == meaningVal,
                                  );
                                  StatsService.savePhrases(currentPhrases);
                                  _loadData();
                                  _updateFilteredList();
                                },
                              ),
                            ),
                          );
                          if (result == 'deleted') {
                            // Already handled in onDelete
                          } else if (result == true) {
                            _loadData();
                            _updateFilteredList();
                          }
                        },
                      ),
                    );
                  }, childCount: filteredPhrases.length),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8E54E9),
        foregroundColor: Colors.white,
        mini: true,
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddPhrasesPage()),
          );
          if (added == true) {
            _loadData();
            _updateFilteredList();
            if (widget.onPhraseAdded != null) widget.onPhraseAdded!();
          }
        },
        child: const Icon(Icons.add, size: 20),
        tooltip: 'Add New Phrase',
      ),
    );
  }
}

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _FilterHeaderDelegate({required this.child, required this.height});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Colors.white,
      child: child,
      elevation: shrinkOffset > 0 ? 4 : 0,
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class _CategoryFilterDialog extends StatefulWidget {
  final List<String> categories;
  final List<String> initialSelection;
  final Function(List<String>) onApply;
  final Color themeColor;
  final bool isMultiSelect;

  const _CategoryFilterDialog({
    required this.categories,
    required this.initialSelection,
    required this.onApply,
    required this.themeColor,
    this.isMultiSelect = true,
  });

  @override
  State<_CategoryFilterDialog> createState() => _CategoryFilterDialogState();
}

class _CategoryFilterDialogState extends State<_CategoryFilterDialog> {
  late List<String> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = List<String>.from(widget.initialSelection);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Filter by Category',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: Wrap(
        spacing: 8.0,
        runSpacing: 6.0,
        children: widget.categories.map((category) {
          final isSelected = _tempSelected.contains(category);
          return FilterChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (bool isNowSelected) {
              setState(() {
                if (widget.isMultiSelect) {
                  if (isNowSelected) {
                    if (category == 'All') {
                      _tempSelected.clear();
                      _tempSelected.add('All');
                    } else {
                      _tempSelected.remove('All');
                      _tempSelected.add(category);
                    }
                  } else {
                    _tempSelected.remove(category);
                    if (_tempSelected.isEmpty) {
                      _tempSelected.add('All');
                    }
                  }
                } else {
                  // Single select logic
                  if (isNowSelected) {
                    _tempSelected.clear();
                    _tempSelected.add(category);
                  }
                }
              });
            },
            selectedColor: widget.themeColor.withOpacity(0.2),
            checkmarkColor: widget.themeColor,
            labelStyle: TextStyle(
              color: isSelected ? widget.themeColor : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.themeColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => widget.onApply(_tempSelected),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _MasteryFilterDialog extends StatefulWidget {
  final List<int> initialSelection;
  final Function(List<int>) onApply;
  final Color themeColor;

  const _MasteryFilterDialog({
    required this.initialSelection,
    required this.onApply,
    required this.themeColor,
  });

  @override
  State<_MasteryFilterDialog> createState() => _MasteryFilterDialogState();
}

class _MasteryFilterDialogState extends State<_MasteryFilterDialog> {
  late List<int> _tempSelected;

  static const Map<int, String> masteryLabels = {
    1: 'Just Getting Started',
    2: 'Recognize Only',
    3: 'Rarely Used',
    4: 'Somewhat Comfortable',
    5: 'Confident User',
  };

  @override
  void initState() {
    super.initState();
    _tempSelected = List<int>.from(widget.initialSelection);
  }

  Widget _buildMasteryOption(int value, String label, {Widget? subtitle}) {
    final isSelected = _tempSelected.contains(value);
    return CheckboxListTile(
      title: Text(label),
      subtitle: subtitle,
      value: isSelected,
      onChanged: (bool? selected) {
        setState(() {
          if (selected ?? false) {
            if (value == -1) {
              _tempSelected.clear();
              _tempSelected.add(-1);
            } else {
              _tempSelected.remove(-1);
              _tempSelected.add(value);
            }
          } else {
            _tempSelected.remove(value);
            if (_tempSelected.isEmpty) {
              _tempSelected.add(-1);
            }
          }
        });
      },
      activeColor: widget.themeColor,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Filter by Mastery',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMasteryOption(-1, 'All'),
              const Divider(),
              _buildMasteryOption(
                0,
                'Unspecified',
                subtitle: Row(
                  children: List.generate(
                    5,
                    (j) => const Icon(
                      Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                ),
              ),
              ...List.generate(5, (i) {
                final starCount = i + 1;
                return _buildMasteryOption(
                  starCount,
                  masteryLabels[starCount] ?? '$starCount Star(s)',
                  subtitle: Row(
                    children: List.generate(
                      5,
                      (j) => Icon(
                        j < starCount ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.themeColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => widget.onApply(_tempSelected),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
