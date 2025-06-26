import 'package:flutter/material.dart';

import '../../../config/game_config/constants.dart';

class ContactFeedbackScreen extends StatelessWidget {
  const ContactFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  'Kontakt & Feedback',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorBlack,
                      ),
                ),
              ),
            ),

            // content
            Center(
              child: Text('Content coming soon...'),
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
