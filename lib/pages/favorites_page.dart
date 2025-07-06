// pages/favorites_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/word_lookup_service.dart';
import '../services/stats_service.dart';
import '../pages/word_info_page.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'add_word_page.dart';

class FavoritesPage extends StatefulWidget {
  final List<Map<String, dynamic>> favoriteWords;
  final Function()? onFavoriteAdded;

  const FavoritesPage({
    super.key,
    required this.favoriteWords,
    this.onFavoriteAdded,
  });

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late FlutterTts flutterTts;
  TextEditingController searchController = TextEditingController();
  final ValueNotifier<List<String>> _categoryNotifier =
      ValueNotifier<List<String>>(['All']);
  final ValueNotifier<List<int>> _masteryNotifier = ValueNotifier<List<int>>([
    -1,
  ]);
  final ValueNotifier<List<Map<String, dynamic>>> _filteredFavoritesNotifier =
      ValueNotifier<List<Map<String, dynamic>>>([]);
  late List<Map<String, dynamic>> _localFavorites;

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
    _updateFilteredList();
    searchController.addListener(_updateFilteredList);
    _categoryNotifier.addListener(_updateFilteredList);
    _masteryNotifier.addListener(_updateFilteredList);
  }

  void _loadData() {
    _localFavorites = StatsService.getFavorites()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  void _updateFilteredList() {
    final searchQuery = searchController.text.trim().toLowerCase();
    final selectedCategories = _categoryNotifier.value;
    final selectedMasteries = _masteryNotifier.value;
    final filtered = _localFavorites.where((fav) {
      final word = (fav['word'] ?? '').toLowerCase();
      final meaning = (fav['meaning'] ?? '').toLowerCase();

      List<String> itemCategories;
      final rawCategory = fav['category'];
      if (rawCategory is List) {
        itemCategories = rawCategory.map((c) => c.toString()).toList();
      } else if (rawCategory is String) {
        itemCategories = [rawCategory];
      } else {
        itemCategories = ['Uncategorized'];
      }

      final mastery = fav['mastery'] ?? 0;
      final matchesSearch =
          searchQuery.isEmpty ||
          word.contains(searchQuery) ||
          meaning.contains(searchQuery);
      final matchesCategory =
          selectedCategories.contains('All') ||
          itemCategories.any((itemCat) => selectedCategories.contains(itemCat));
      final matchesMastery =
          selectedMasteries.contains(-1) ||
          selectedMasteries.any((sm) {
            if (sm == 0) return mastery == 0 || mastery == -1;
            return mastery == sm;
          });
      return matchesSearch && matchesCategory && matchesMastery;
    }).toList();
    _filteredFavoritesNotifier.value = filtered;
  }

  @override
  void dispose() {
    searchController.removeListener(_updateFilteredList);
    _categoryNotifier.removeListener(_updateFilteredList);
    _masteryNotifier.removeListener(_updateFilteredList);
    searchController.dispose();
    _categoryNotifier.dispose();
    _masteryNotifier.dispose();
    _filteredFavoritesNotifier.dispose();
    super.dispose();
  }

  void speak(String word) async {
    await flutterTts.stop();
    await flutterTts.speak(word);
  }

  Future<bool?> _showAddWordDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddWordPage()),
    );
    if (result == true) {
      _loadData();
      _updateFilteredList();
      if (widget.onFavoriteAdded != null) widget.onFavoriteAdded!();
    }
    return result;
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
          themeColor: const Color(0xFFF94F8E),
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
          themeColor: const Color(0xFFF94F8E),
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
            backgroundColor: const Color(0xFFF94F8E),
            foregroundColor: Colors.white,
            centerTitle: true,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Color(0xFFF94F8E),
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.light,
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Favorites',
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
                    colors: [Color(0xFFF94F8E), Color(0xFFF87B92)],
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
                          hintText: 'Search favorites...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFFF94F8E),
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
            valueListenable: _filteredFavoritesNotifier,
            builder: (context, filteredFavorites, _) {
              if (filteredFavorites.isEmpty) {
                return SliverToBoxAdapter(
                  child: Container(
                    height: 300,
                    child: const Center(
                      child: Text(
                        'No favorites found.',
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
                    final fav = filteredFavorites[index];
                    final word = fav['word'] ?? '';
                    final meaning = fav['meaning'] ?? '';

                    List<String> itemCategories;
                    final rawCategory = fav['category'];
                    if (rawCategory is List) {
                      itemCategories = rawCategory
                          .map((c) => c.toString())
                          .toList();
                    } else if (rawCategory is String) {
                      itemCategories = [rawCategory];
                    } else {
                      itemCategories = ['Uncategorized'];
                    }

                    final selectedFilterCategories = _categoryNotifier.value;

                    String displayCategory;
                    if (selectedFilterCategories.contains('All') ||
                        selectedFilterCategories.isEmpty) {
                      displayCategory = itemCategories.join(', ');
                    } else {
                      displayCategory = itemCategories
                          .where((c) => selectedFilterCategories.contains(c))
                          .join(', ');
                      if (displayCategory.isEmpty) {
                        displayCategory = itemCategories.join(', ');
                      }
                    }

                    final definedOrder = [
                      'Daily',
                      'Travel',
                      'Work & Study',
                      'Special Topics',
                    ];
                    itemCategories.sort((a, b) {
                      final aIndex = definedOrder.indexOf(a);
                      final bIndex = definedOrder.indexOf(b);
                      if (aIndex == -1 && bIndex == -1) return a.compareTo(b);
                      if (aIndex == -1) return 1;
                      if (bIndex == -1) return -1;
                      return aIndex.compareTo(bIndex);
                    });
                    displayCategory = itemCategories.join(', ');

                    final mastery = fav['mastery'] ?? 0;
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
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WordInfoPage(
                                word: word,
                                meaning: meaning,
                                onDelete: () {
                                  // Remove from favorites when deleted in info page
                                  final manualList =
                                      StatsService.getManualFavorites();
                                  final quizList =
                                      StatsService.getQuizFavorites();
                                  manualList.removeWhere(
                                    (f) =>
                                        f['word'] == word &&
                                        f['meaning'] == meaning,
                                  );
                                  quizList.removeWhere(
                                    (f) =>
                                        f['word'] == word &&
                                        f['meaning'] == meaning,
                                  );
                                  StatsService.saveManualFavorites(manualList);
                                  StatsService.saveFavorites(quizList);
                                  _loadData();
                                  _updateFilteredList();
                                },
                              ),
                            ),
                          );
                          if (result == 'deleted') {
                            // Already handled in onDelete
                          } else if (result == true) {
                            // If any change was made, reload favorites
                            _loadData();
                            _updateFilteredList();
                          }
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        leading: const Icon(
                          Icons.favorite,
                          color: Color(0xFFF94F8E),
                          size: 28,
                        ),
                        title: Text(
                          word,
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
                              Text(
                                'Category: $displayCategory',
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
                                    i < mastery
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 16,
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
                              tooltip: 'Speak',
                              onPressed: () => speak(word),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              tooltip: 'Remove from Favorites',
                              onPressed: () {
                                final wordMap = filteredFavorites[index];
                                final wordVal = wordMap['word'] ?? '';
                                final meaningVal = wordMap['meaning'] ?? '';
                                // Remove from manualFavorites if exists, else from quiz favorites
                                final manualList =
                                    StatsService.getManualFavorites();
                                final quizList =
                                    StatsService.getQuizFavorites();
                                bool removed = false;
                                manualList.removeWhere((f) {
                                  if (f['word'] == wordVal &&
                                      f['meaning'] == meaningVal) {
                                    removed = true;
                                    return true;
                                  }
                                  return false;
                                });
                                if (removed) {
                                  // Update manualFavorites
                                  StatsService.saveManualFavorites(manualList);
                                } else {
                                  quizList.removeWhere(
                                    (f) =>
                                        f['word'] == wordVal &&
                                        f['meaning'] == meaningVal,
                                  );
                                  StatsService.saveFavorites(quizList);
                                }
                                _loadData();
                                _updateFilteredList();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '"$wordVal" removed from favorites.',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: filteredFavorites.length),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF94F8E),
        foregroundColor: Colors.white,
        mini: true,
        onPressed: () async {
          final added = await _showAddWordDialog();
          if (added == true) {
            _loadData();
            _updateFilteredList();
            if (widget.onFavoriteAdded != null) widget.onFavoriteAdded!();
          }
        },
        child: const Icon(Icons.add, size: 20),
        tooltip: 'Add New Word',
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Filter by Category',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
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
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
            ),
          ],
        ),
      ),
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
