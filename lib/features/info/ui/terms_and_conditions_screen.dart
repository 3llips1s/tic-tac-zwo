import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/game_config/constants.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorGrey300,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                const SizedBox(height: kToolbarHeight),
                // Title
                Text(
                  'Nutzungsbedingungen',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: colorBlack,
                      ),
                ),

                const SizedBox(height: 32),
                _buildParagraph(context, 'Stand: 28. Juni 2025'),
                const SizedBox(height: 12),

                _buildHeading(context, '1. Geltungsbereich und Zustimmung'),
                _buildParagraph(context,
                    'Diese Nutzungsbedingungen regeln die Nutzung der App "Tic Tac Zwö". Durch die Nutzung der App stimmst du diesen Bedingungen zu. Wenn du mit den Bedingungen nicht einverstanden bist, darfst du die App nicht nutzen.'),

                _buildHeading(context, '2. Nutzerkonto'),
                _buildParagraph(context,
                    'Für die Nutzung der Online-Funktionen ist ein Nutzerkonto erforderlich. Du bist dafür verantwortlich, deine Zugangsdaten geheim zu halten. Dein Nutzername darf nicht beleidigend sein, die Rechte Dritter verletzen oder irreführend sein. Wir behalten uns das Recht vor, unzulässige Nutzernamen zu ändern oder Konten zu sperren.'),

                _buildHeading(context, '3. Verhaltensregeln'),
                _buildParagraph(context,
                    'Du verpflichtest dich, die App fair und respektvoll zu nutzen. Insbesondere ist Folgendes verboten:\n• Die Ausnutzung von Fehlern (Bugs) oder Cheats, um sich einen unfairen Vorteil zu verschaffen.\n• Belästigung, Beleidigung oder Bedrohung anderer Nutzer.\n• Jegliche Form von automatisiertem Zugriff oder Manipulation der App.'),

                _buildHeading(context, '4. Geistiges Eigentum'),
                _buildParagraph(context,
                    'Die App, ihr Design, die Texte, Grafiken und der Code sind unser geistiges Eigentum und durch Urheberrechte geschützt. Es ist nicht gestattet, Teile der App ohne unsere ausdrückliche Genehmigung zu kopieren, zu verändern oder zu verbreiten.'),

                _buildHeading(
                    context, '5. Verfügbarkeit und Haftungsausschluss'),
                _buildParagraph(context,
                    'Wir bemühen uns, die App und ihre Online-Dienste rund um die Uhr verfügbar zu halten, können jedoch keine ununterbrochene Verfügbarkeit garantieren. Die App wird "wie besehen" und ohne Gewährleistung jeglicher Art bereitgestellt. Wir haften nicht für Schäden, die aus der Nutzung oder Nichtverfügbarkeit der App entstehen.'),

                _buildHeading(context, '6. Beendigung'),
                _buildParagraph(context,
                    'Du kannst die Nutzung jederzeit beenden, indem du dein Konto löschst und die App deinstallierst. Wir behalten uns das Recht vor, dein Konto bei Verstößen gegen diese Nutzungsbedingungen ohne Vorwarnung zu sperren oder zu löschen.'),

                _buildHeading(context, '7. Änderungen der Bedingungen'),
                _buildParagraph(context,
                    'Wir können diese Nutzungsbedingungen von Zeit zu Zeit aktualisieren. Wesentliche Änderungen werden wir dir innerhalb der App mitteilen. Die fortgesetzte Nutzung der App nach einer Änderung gilt als Zustimmung zu den neuen Bedingungen.'),

                _buildHeading(context, '8. Anwendbares Recht'),
                _buildParagraph(context,
                    'Auf diese Nutzungsbedingungen findet das Recht von Kenia Anwendung.'),

                const SizedBox(height: 80), // Space for FAB
              ],
            )
                .animate(delay: 500.ms)
                .slideY(
                  begin: 0.3,
                  duration: 1500.ms,
                  curve: Curves.easeOut,
                )
                .fadeIn(
                  duration: 1500.ms,
                  curve: Curves.easeOut,
                ),

            // back button
            Positioned(
              bottom: 16,
              right: 16,
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

  Widget _buildHeading(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: colorBlack,
            ),
      ),
    );
  }

  Widget _buildParagraph(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorGrey600,
              height: 1.4,
            ),
      ),
    );
  }
}
