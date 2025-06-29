import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/game_config/constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                  'Datenschutzerklärung',
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

                // Content Sections
                _buildHeading(
                    context, '1. Name und Anschrift des Verantwortlichen'),
                _buildParagraph(context,
                    'Der Verantwortliche im Sinne der Datenschutz-Grundverordnung (DSGVO) ist:'),
                _buildParagraph(
                    context, 'Tic Tac Zwö\nE-Mail: feedback@tictaczwo.app'),

                _buildHeading(context, '2. Allgemeines zur Datenverarbeitung'),
                _buildParagraph(context,
                    'Wir verarbeiten personenbezogene Daten unserer Nutzer grundsätzlich nur, soweit dies zur Bereitstellung einer funktionsfähigen App sowie unserer Inhalte und Leistungen erforderlich ist. Der Schutz Ihrer Daten ist uns sehr wichtig.'),

                _buildHeading(
                    context, '3. Daten, die wir erheben und verarbeiten'),
                _buildSubHeading(
                    context, 'a) Bei der Registrierung für den Online-Modus'),
                _buildParagraph(context,
                    'Für die Nutzung der Online-Funktionen (z.B. Online-Matchmaking, Bestenlisten) ist eine Registrierung erforderlich. Hierbei erheben wir folgende Daten:\n• E-Mail-Adresse\n• Ein von dir gewählter Nutzername\n• Dein Land\n\nDiese Daten sind notwendig, um dein Nutzerkonto zu erstellen, zu verwalten und dich gegenüber anderen Spielern zu identifizieren.'),

                _buildSubHeading(
                    context, 'b) Standortdaten für "In der Nähe"-Spiele'),
                _buildParagraph(context,
                    'Um dir Spiele gegen andere Nutzer in deiner Nähe vorschlagen zu können, fragen wir nach deiner Erlaubnis, auf deinen Standort zuzugreifen. Wir erfassen deine geografischen Koordinaten nur für den Moment der Spielersuche und verwerfen sie anschließend wieder. Dein Standort wird nicht dauerhaft gespeichert oder für andere Zwecke verwendet.'),

                _buildSubHeading(context, 'c) Spieldaten im Online-Modus'),
                _buildParagraph(context,
                    'Wenn du online spielst, speichern wir deine Spielergebnisse (Siege, Niederlagen, Unentschieden) und die daraus resultierenden Punkte, um deine Position in der Bestenliste zu berechnen.'),

                _buildSubHeading(
                    context, 'd) Lokale Speicherung des "Wortschatz"'),
                _buildParagraph(context,
                    'Die Funktion "Wortschatz", mit der du Wörter speichern kannst, speichert diese Daten ausschließlich lokal auf deinem Gerät. Diese Daten werden nicht an uns oder Dritte übertragen.'),

                _buildHeading(
                    context, '4. Feedback, Analyse und Absturzberichte'),
                _buildParagraph(context,
                    'Um die App kontinuierlich zu verbessern, Fehler zu beheben und direktes Nutzerfeedback zu sammeln, verwenden wir das Open-Source-Tool Wiredash. Wiredash hilft uns, Abstürze zu analysieren und zu verstehen, wie die App genutzt wird.\n\nWenn du über Wiredash Feedback sendest oder ein Absturz auftritt, können technische Daten wie Gerätetyp, Betriebssystemversion und anonymisierte Nutzungslogs an Wiredash übermittelt werden. Dies geschieht ausschließlich zur Fehlerbehebung und zur Verbesserung des Nutzererlebnisses. Für weitere Informationen zum Datenschutz von Wiredash, besuche bitte deren offizielle Webseite.'),

                _buildHeading(context, '5. Deine Rechte als Nutzer'),
                _buildParagraph(context,
                    'Du hast das Recht auf Auskunft, Berichtigung, Löschung und Einschränkung der Verarbeitung deiner personenbezogenen Daten. Du kannst dein Nutzerkonto und die damit verbundenen Daten jederzeit über die Funktion "Konto löschen" in den Profileinstellungen der App selbstständig und unwiderruflich löschen.'),

                _buildHeading(context, '6. Datenschutz von Kindern'),
                _buildParagraph(context,
                    'Diese App ist für Nutzer aller Altersgruppen gedacht. Wenn du unter 16 Jahre alt bist, darfst du unsere Online-Funktionen nur nutzen, wenn deine Eltern oder Erziehungsberechtigten dem zugestimmt haben. Wir erheben nicht wissentlich Daten von Kindern ohne diese Zustimmung. Erziehungsberechtigte können uns jederzeit kontaktieren, um die Daten ihres Kindes einsehen oder löschen zu lassen.'),
                const SizedBox(height: 80),
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

            // Navigate back button
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

  Widget _buildSubHeading(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
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
