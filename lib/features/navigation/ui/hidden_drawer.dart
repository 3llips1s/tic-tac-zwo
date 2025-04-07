import 'package:flutter/material.dart';

import '../../../config/game_config/constants.dart';

class HiddenDrawer extends StatefulWidget {
  const HiddenDrawer({super.key});

  @override
  State<HiddenDrawer> createState() => _HiddenDrawerState();
}

class _HiddenDrawerState extends State<HiddenDrawer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.only(
          top: 25,
          bottom: 30,
          right: 40,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // user profile
            Padding(
              padding: EdgeInsets.only(top: kToolbarHeight / 1.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                      padding: EdgeInsets.all(9),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: colorYellowAccent),
                      child: Icon(
                        Icons.face_5_rounded,
                        size: 25,
                      )),
                  const SizedBox(width: 15),
                  Text(
                    'Patient 0',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: colorYellowAccent, fontSize: 16.0),
                  ),
                ],
              ),
            ),

            // menu
            Column(
              children: drawerItems
                  .map(
                    (drawerItem) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            drawerItem['title'],
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: colorWhite, fontSize: 16),
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                          Icon(
                            drawerItem['icon'],
                            color: colorYellowAccent,
                            size: 30,
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // logout
                Icon(
                  Icons.logout_rounded,
                  color: colorRed,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Text(
                  'ausloggen',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colorWhite, fontSize: 18),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

final drawerItems = <Map<String, dynamic>>[
  {
    'icon': Icons.leaderboard_rounded,
    'title': 'l e a d e r b o a r d',
  },
  {
    'icon': Icons.favorite_rounded,
    'title': 'w o r t s c h a t z',
  },
  {
    'icon': Icons.info_outline_rounded,
    'title': 'i n f o',
  }
];
