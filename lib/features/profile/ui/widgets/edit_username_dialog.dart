import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_zwo/features/profile/data/models/user_profile.dart';
import 'package:tic_tac_zwo/features/profile/logic/user_profile_providers.dart';

import '../../../../config/game_config/constants.dart';
import '../../../game/core/ui/widgets/dual_progress_indicator.dart';
import '../../../game/core/ui/widgets/glassmorphic_dialog.dart';

class EditUsernameDialog extends ConsumerStatefulWidget {
  final UserProfile userProfile;

  const EditUsernameDialog({super.key, required this.userProfile});

  @override
  ConsumerState<EditUsernameDialog> createState() => _EditUsernameDialogState();
}

class _EditUsernameDialogState extends ConsumerState<EditUsernameDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  String? _usernameError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.userProfile.username);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    setState(() {
      _usernameError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final newUsername = _controller.text.trim();
    final navigator = Navigator.of(context);

    try {
      if (newUsername.trim().isEmpty) {
        setState(() {
          _usernameError = 'Name darf nicht leer sein.';
        });
      }

      if (newUsername.trim() == widget.userProfile.username) {
        setState(() {
          _usernameError = 'Bitte wähle einen anderen Namen.';
        });
      }

      final isAvailable = await ref
          .read(userProfileRepoProvider)
          .checkUsernameAvailability(newUsername);

      if (!isAvailable) {
        setState(() {
          _usernameError = 'Name ist schon vergeben';
        });
        return;
      }

      await ref.read(userProfileRepoProvider).updateUserProfile(
            userId: widget.userProfile.id,
            username: newUsername,
          );
      ref.invalidate(userProfileProvider(widget.userProfile.id));

      navigator.pop();
    } catch (e) {
      navigator.pop();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Text(
            'Name ändern:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorBlack,
                ),
          ),
        ),
        const SizedBox(height: kToolbarHeight * 0.55),
        Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: TextField(
              controller: _controller,
              onChanged: (_) {
                // clear error when user types
                if (_usernameError != null) {
                  setState(() {
                    _usernameError = null;
                  });
                }
              },
              autofocus: true,
              showCursor: true,
              cursorColor: Colors.black54,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                  ),
              decoration: InputDecoration(
                errorText: _usernameError,
                errorStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorRed,
                    ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colorYellow, width: 2),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: colorBlack,
                    width: 1,
                  ),
                ),
              ),
              maxLength: 9,
              buildCounter: (context,
                      {required currentLength,
                      required isFocused,
                      required maxLength}) =>
                  Text(
                '0${maxLength! - currentLength}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black38,
                    ),
              ),
              onTapOutside: (event) => FocusScope.of(context).unfocus(),
            ),
          ),
        ),
        const SizedBox(height: kToolbarHeight * 0.45),
      ],
    );
  }
}

void showEditUsernameDialog(
    BuildContext context, WidgetRef ref, UserProfile userProfile) {
  final contentKey = GlobalKey<_EditUsernameDialogState>();

  showCustomDialog(
    context: context,
    height: 300,
    width: 300,
    child: EditUsernameDialog(userProfile: userProfile, key: contentKey),
    actions: [
      // cancel
      GlassMorphicButton(
        onPressed: () => Navigator.pop(context),
        child: Icon(Icons.close_rounded, color: colorRed, size: 35),
      ),

      StatefulBuilder(
        builder: (context, setState) {
          final isLoading = contentKey.currentState?._isLoading ?? false;
          return GlassMorphicButton(
            onPressed: isLoading
                ? () {}
                : () {
                    contentKey.currentState?._saveUsername();
                  },
            child: isLoading
                ? DualProgressIndicator(size: 20)
                : Icon(
                    Icons.done_rounded,
                    color: colorYellowAccent,
                    size: 35,
                  ),
          );
        },
      )
    ],
  );
}
