import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';

import '../../navigation/routes/route_names.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const tileSpacer = SizedBox(height: 16);

    return Scaffold(
      backgroundColor: colorGrey300,
      body: Padding(
        padding: const EdgeInsets.all(16.0).copyWith(top: kToolbarHeight),
        child: Stack(
          children: [
            ListView(
              children: [
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: 1,
                            sigmaY: 1,
                          ),
                          child: Image.asset(
                            'assets/images/icon_in_app.png',
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                    .animate(
                      delay: 300.ms,
                    )
                    .scale(
                      duration: 1200.ms,
                      curve: Curves.easeInOut,
                    )
                    .fadeIn(
                      begin: 0.0,
                      duration: 1200.ms,
                      curve: Curves.easeInOut,
                    ),
                const SizedBox(height: 56),
                _buildInfoTile(
                  context,
                  icon: Icons.description_rounded,
                  title: 'Nutzungsbedingungen',
                  routeName: RouteNames.terms,
                ),
                tileSpacer,
                _buildInfoTile(
                  context,
                  icon: Icons.privacy_tip_rounded,
                  title: 'Datenschutzerklärung',
                  routeName: RouteNames.privacy,
                ),
                tileSpacer,
                _buildInfoTile(
                  context,
                  icon: Icons.attribution_rounded,
                  title: 'Danksagungen & Quellenangaben',
                  routeName: RouteNames.credits,
                ),
                tileSpacer,
                _buildInfoTile(
                  context,
                  icon: Icons.mail_rounded,
                  title: 'Kontakt & Feedback',
                  routeName: RouteNames.contact,
                ),
                tileSpacer,
                _buildInfoTile(
                  context,
                  icon: Icons.copyright_rounded,
                  title: 'Über Tic Tac Zwö',
                  routeName: RouteNames.about,
                ),
                tileSpacer,
                ListTile(
                  leading: const Icon(Icons.code_rounded,
                      size: 24, color: colorGrey600),
                  title: Text(
                    'Open-Source-Lizenzen',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorBlack,
                        ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      size: 28, color: colorGrey500),
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'Tic Tac Zwö',
                      applicationVersion: '1.0.0',
                    );
                  },
                ),
              ],
            ),

            // back button
            Positioned(
              bottom: 16,
              left: 16,
              child: SizedBox(
                height: 52,
                width: 52,
                child: FloatingActionButton(
                  onPressed: () => Navigator.pop(context),
                  backgroundColor: colorBlack.withOpacity(0.75),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: colorWhite,
                    size: 26,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context,
      {required IconData icon,
      required String title,
      required String routeName}) {
    return ListTile(
      leading: Icon(icon, size: 24, color: colorGrey600),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorBlack,
            ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded,
          size: 28, color: colorGrey500),
      onTap: () => Navigator.pushNamed(context, routeName),
    );
  }
}
