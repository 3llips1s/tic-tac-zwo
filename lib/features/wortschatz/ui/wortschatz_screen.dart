import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/navigation/routes/route_names.dart';
import 'package:tic_tac_zwo/features/wortschatz/data/models/saved_noun_hive.dart';
import 'package:tic_tac_zwo/features/wortschatz/logic/saved_nouns_notifier.dart';

class WortschatzScreen extends ConsumerStatefulWidget {
  const WortschatzScreen({super.key});

  @override
  ConsumerState<WortschatzScreen> createState() => _WortschatzScreenState();
}

class _WortschatzScreenState extends ConsumerState<WortschatzScreen> {
  late TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.text = ref.read(searchQueryProvider);

    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () {
        ref.read(searchQueryProvider.notifier).state = _searchController.text;
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final savedNouns = ref.watch(savedNounsProvider);
    final savedNounsNotifier = ref.read(savedNounsProvider.notifier);
    final searchQuery = ref.watch(searchQueryProvider);

    // filtering
    final filteredNouns = savedNouns.where((noun) {
      if (searchQuery.isEmpty) return true;
      final queryInLower = searchQuery.toLowerCase();
      return noun.noun.toLowerCase().contains(queryInLower) ||
          noun.english.toLowerCase().contains(queryInLower);
    }).toList();

    return Scaffold(
      backgroundColor: colorGrey300,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            // title
            SizedBox(
              height: kToolbarHeight * 2.5,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'wortschatz',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorBlack,
                      ),
                ),
              ),
            ),

            // search bar
            Positioned(
              left: 16,
              right: 16,
              top: kToolbarHeight * 2,
              child: Container(
                padding:
                    const EdgeInsets.only(left: 16.0, top: 2.0, bottom: 2.0),
                decoration: BoxDecoration(
                  color: colorWhite.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: TextField(
                  controller: _searchController,
                  cursorColor: colorGrey600,
                  decoration: InputDecoration(
                    hintText: 'Suche...',
                    hintStyle: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: colorGrey500),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16.0),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: colorGrey600,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchQueryProvider.notifier).state = '';
                            },
                          )
                        : Icon(
                            Icons.search_rounded,
                            color: colorGrey400,
                          ),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorBlack,
                      ),
                ),
              ),
            ).animate(delay: 300.ms).slideX(
                  begin: 0.3,
                  duration: 900.ms,
                  curve: Curves.easeInOut,
                ),

            Positioned.fill(
              top: kToolbarHeight * 3.5,
              child: filteredNouns.isEmpty && searchQuery.isNotEmpty
                  ? Padding(
                      padding:
                          const EdgeInsets.only(bottom: kToolbarHeight * 4),
                      child: Center(
                        child: Text(
                          'Keine Wörter gefunden.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 18,
                                    color: colorGrey600,
                                  ),
                        ),
                      ),
                    )
                  : filteredNouns.isEmpty && searchQuery.isEmpty
                      ? Padding(
                          padding:
                              const EdgeInsets.only(bottom: kToolbarHeight * 4),
                          child: Center(
                            child: Text(
                              'Dein Wortschatz ist leer.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: 18,
                                    color: colorGrey600,
                                  ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          itemCount: filteredNouns.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final noun = filteredNouns[index];
                            return SavedNounTile(
                              noun: noun,
                              onDelete: () {
                                savedNounsNotifier.deleteNoun(noun.id);
                              },
                            )
                                .animate(delay: (1200 + (index * 100)).ms)
                                .slideX(
                                    begin: -0.3,
                                    curve: Curves.easeInOut,
                                    duration: 600.ms)
                                .fadeIn(
                                  duration: 600.ms,
                                  curve: Curves.easeInOut,
                                );
                          },
                        ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 16),
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      RouteNames.home,
                      (route) => false,
                    );
                  },
                  backgroundColor: colorBlack.withOpacity(0.75),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    color: colorWhite,
                    size: 30,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SavedNounTile extends StatelessWidget {
  final SavedNounHive noun;
  final VoidCallback onDelete;

  const SavedNounTile({
    super.key,
    required this.noun,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(noun.id),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (context) => onDelete(),
            backgroundColor: colorGrey400,
            foregroundColor: colorBlack,
            icon: Icons.delete_rounded,
            borderRadius: BorderRadius.circular(6),
          )
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: colorWhite,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: colorBlack.withOpacity(0.2),
              blurRadius: 3,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              noun.article,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
            ),
            const SizedBox(width: 8),
            Text(
              noun.noun,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorBlack,
                  ),
            ),
            const SizedBox(width: 4),
            Text(
              ' | ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorGrey400,
                  ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                noun.plural,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              ' — ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorGrey400,
                  ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                noun.english,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
