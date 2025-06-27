import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/game_config/constants.dart';

class ContactFeedbackScreen extends StatelessWidget {
  const ContactFeedbackScreen({super.key});

  static const String _supportEmail = 'feedback@tictaczwo.app';
  static const String _emailSubject = 'Feedback für Tic Tac Zwö';

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: _supportEmail,
        queryParameters: {'subject': _emailSubject});

    try {
      final bool canLaunch = await canLaunchUrl(emailLaunchUri);
      if (canLaunch) {
        await launchUrl(emailLaunchUri);
      } else {
        _showErrorSnackBar(context, 'Keine E-Mail-App gefunden.');
      }
    } catch (e) {
      _showErrorSnackBar(context, 'E-Mail konnte nicht geöffnet werden.');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: EdgeInsets.only(
          bottom: kToolbarHeight,
          left: 40,
          right: 40,
        ),
        content: Container(
            padding: EdgeInsets.all(12),
            height: kToolbarHeight,
            decoration: BoxDecoration(
              color: colorBlack,
              borderRadius: BorderRadius.all(Radius.circular(9)),
            ),
            child: Center(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorWhite,
                    ),
              ),
            )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        height: kToolbarHeight * 2,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            'Kontakt & Feedback',
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

                      Text(
                        'Hast du eine Frage, einen Fehler gefunden oder einfach nur einen Vorschlag?\n'
                        '\nWir freuen uns, von dir zu hören!\n'
                        '\nSende uns eine E-Mail an:',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorGrey600,
                              fontSize: 16,
                              height: 1.5,
                            ),
                      ),

                      const SizedBox(height: 40),

                      SelectableText(
                        _supportEmail,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorBlack,
                              fontSize: 18,
                            ),
                      ),

                      const SizedBox(height: 44),

                      ElevatedButton.icon(
                        onPressed: () => _launchEmail(context),
                        icon: const Icon(
                          Icons.mail_rounded,
                          color: colorWhite,
                          size: 20,
                        ),
                        label: const Text('E-Mail schreiben'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: colorBlack,
                          foregroundColor: colorWhite,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          textStyle:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorBlack,
                                    fontSize: 18,
                                  ),
                        ),
                      )
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
}
