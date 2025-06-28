import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tic_tac_zwo/features/game/core/ui/widgets/dual_progress_indicator.dart';

import '../../../config/game_config/constants.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  Future<PackageInfo> _getPackageInfo() => PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final int currentYear = DateTime.now().year;

    return Scaffold(
      backgroundColor: colorGrey300,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // title
                      SizedBox(
                        height: kToolbarHeight * 2.5,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            'Über Uns',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: colorBlack,
                                ),
                          ),
                        ),
                      ),

                      // app description
                      Text(
                        'Willkommen bei Tic Tac Zwö – dem klassischen Spiel mit einem deutschen Twist :)\n'
                        '\nZeige, was du kannst: In jeder Runde musst du den richtigen Artikel (der, die oder das) für ein deutsches Nomen finden, um dein Feld zu markieren.\n'
                        '\nSpiele offline, fordere einen Freund neben dir heraus oder beweise dich im Online-Modus. Im Online-Spiel sammelst du Punkte und kletterst im Leaderboard nach oben.\n'
                        '\nNeue Wörter, die dir begegnen, kannst du jederzeit in deinem persönlichen Wortschatz speichern.\n'
                        '\nUnd ein bisschen Wördle rumspielen.\n'
                        '\nViel Spaß beim Spielen und Lernen!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.black54,
                              fontSize: 16,
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(height: 64),

                      // version and copyright info
                      _buildVersionInfo(context, currentYear),
                    ],
                  ),
                ),
              ),
            ),

            // navigate back to drawer
            Positioned(
              bottom: 16,
              left: 16,
              child: FloatingActionButton(
                onPressed: () => Navigator.pop(context),
                backgroundColor: colorBlack.withOpacity(0.75),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
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

  Widget _buildVersionInfo(BuildContext context, int year) {
    return FutureBuilder<PackageInfo>(
      future: _getPackageInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 20,
            width: 20,
            child: DualProgressIndicator(),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Text(
            'Version konnte nicht geladen werden.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorGrey600,
                  fontSize: 12,
                ),
          );
        }

        final packageInfo = snapshot.data!;
        final version = packageInfo.version;
        final buildNumber = packageInfo.buildNumber;

        const companyName = '[tic tac zwö]';

        return Column(
          children: [
            Text(
              'Version $version ($buildNumber)',
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '© $year $companyName',
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 12,
              ),
            )
          ],
        );
      },
    );
  }
}
