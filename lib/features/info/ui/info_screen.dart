import 'package:flutter/material.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/dual_progress_indicator.dart';

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
                  child: SizedBox(
                    height: 200,
                    width: 200,
                    child: DualProgressIndicator(
                      size: 150,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
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
                  title: 'Über dieses Spiel',
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
            // home button
            Positioned(
              bottom: 16,
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
                  size: 30,
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
