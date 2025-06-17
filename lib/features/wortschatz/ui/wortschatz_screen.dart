import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/navigation/routes/route_names.dart';
import 'package:tic_tac_zwo/features/wortschatz/data/models/saved_noun_hive.dart';
import 'package:tic_tac_zwo/features/wortschatz/logic/saved_nouns_notifier.dart';

class WortschatzScreen extends ConsumerWidget {
  const WortschatzScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedNouns = ref.watch(savedNounsProvider);
    final savedNounsNotifier = ref.read(savedNounsProvider.notifier);

    return Scaffold(
      backgroundColor: colorGrey300,
      body: Stack(
        children: [
          // title
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: SizedBox(
              height: kToolbarHeight * 2,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'wortschatz',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colorBlack,
                      ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            top: kToolbarHeight * 3,
            child: savedNouns.isEmpty
                ? Center(
                    child: Text(
                      'Dein Wortschatz ist leer.\nSpeichere ein paar Wörter aus dem Spiel!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 18,
                            color: colorGrey600,
                          ),
                    ).animate().fadeIn(duration: 600.ms),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    itemCount: savedNouns.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final noun = savedNouns[index];
                      return SavedNounTile(
                        noun: noun,
                        onDelete: () {
                          savedNounsNotifier.deleteNoun(noun.id);
                        },
                      )
                          .animate(delay: (index * 100).ms)
                          .slideX(
                              begin: -0.3,
                              curve: Curves.easeInOut,
                              duration: 600.ms)
                          .fadeIn(duration: 600.ms);
                    },
                  ),
          ),
          Positioned(
            bottom: 24,
            right: 16,
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
                size: 24,
              ),
            ),
          )
        ],
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
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (context) => onDelete(),
            backgroundColor: colorRed,
            foregroundColor: colorWhite,
            icon: Icons.delete_rounded,
            borderRadius: BorderRadius.circular(9),
          )
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        decoration: BoxDecoration(
            color: colorWhite,
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: colorBlack.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ]),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              noun.article,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorBlack,
                  ),
            ),
            const SizedBox(width: 4),
            Text(
              noun.noun,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorBlack,
                  ),
            ),
            const SizedBox(width: 8),
            Text(
              ' | ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorGrey500,
                  ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                noun.plural.isNotEmpty ? noun.plural : 'ohne Plural',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorGrey600,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              ' — ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorGrey500,
                  ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                noun.english,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorBlack,
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
