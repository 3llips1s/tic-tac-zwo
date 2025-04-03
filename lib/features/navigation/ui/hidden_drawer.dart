import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
          bottom: 35,
          left: 20,
          top: 25,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // user profile
            Padding(
              padding: EdgeInsets.only(top: kToolbarHeight / 1.5),
              child: Row(
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
                        children: [
                          Icon(
                            drawerItem['icon'],
                            color: colorYellowAccent,
                            size: 30,
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                          Text(
                            drawerItem['title'],
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: colorWhite, fontSize: 16),
                          )
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),

            Row(
              children: [
                // about
                Icon(
                  Icons.info_outline_rounded,
                  color: colorYellowAccent,
                ),
                const SizedBox(width: 10),
                Text(
                  'info',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colorWhite, fontSize: 16),
                ),

                // spacer
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: Container(
                    height: 17,
                    width: 1,
                    color: colorGrey600,
                  ),
                ),

                // logout
                Icon(
                  Icons.logout_rounded,
                  color: colorRed,
                ),
                const SizedBox(width: 10),
                Text(
                  'ausloggen',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colorWhite, fontSize: 16),
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
    'icon': Icons.grid_4x4_rounded,
    'title': 'w ö r d l e',
  }
];
