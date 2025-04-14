import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/auth/data/repositories/user_profile_repo.dart';
import 'package:tic_tac_zwo/features/auth/data/services/auth_service.dart';
import 'package:tic_tac_zwo/features/auth/ui/widgets/flag.dart';
import 'package:tic_tac_zwo/features/auth/ui/widgets/otp_input_field.dart';

import '../../../../routes/route_names.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // state variables
  TextEditingController emailController = TextEditingController();
  final OtpInputFieldController _otpInputFieldController =
      OtpInputFieldController();
  String _currentOtpValue = '';

  TextEditingController usernameController = TextEditingController();

  bool _showUsernameOverlay = false;
  bool _otpTabEnabled = false;
  bool _isExistingUser = false;
  bool _otpVerified = false;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  String? _emailError;
  String? _otpError;
  String? _usernameError;

  bool _canResendOTP = false;
  int _resendTimeoutSeconds = 60;
  Timer? _resendTimer;

  String _selectedCountryCode = '';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _checkAuthStatus();
    _isLoading = false;
  }

  Future<void> _checkAuthStatus() async {
    final isAuthenticated = AuthService().isAuthenticated;
    setState(() {
      _isExistingUser = isAuthenticated;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeCountryCode();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    emailController.dispose();

    usernameController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _canResendOTP = false;
      _resendTimeoutSeconds = 60;
    });

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(
      Duration(seconds: 1),
      (timer) {
        setState(() {
          if (_resendTimeoutSeconds > 0) {
            _resendTimeoutSeconds--;
          } else {
            _canResendOTP = true;
            timer.cancel();
          }
        });
      },
    );
  }

  void _initializeControllers() {
    // tab controller with listener to prevent unauthorized tab switching
    _tabController = TabController(
      length: 2,
      animationDuration: Duration(milliseconds: 300),
      vsync: this,
    )..addListener(() {
        // Prevent manual switching to OTP tab if not enabled
        if (_tabController.index == 1 && !_otpTabEnabled) {
          _tabController.animateTo(0);
        }
      });

    // username overlay fade in controller
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
  }

  void _initializeCountryCode() {
    final localeCountryCode =
        View.of(context).platformDispatcher.locale.countryCode;
    if (localeCountryCode != null && countryCodes.contains(localeCountryCode)) {
      setState(() {
        _selectedCountryCode = localeCountryCode;
      });
    } else {
      setState(() {
        _selectedCountryCode = '';
      });
    }
  }

  void _showCountrySelector() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: colorBlack.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: 300,
          height: 450,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorWhite.withAlpha((255 * 0.1).toInt()),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorWhite.withAlpha((255 * 0.1).toInt()),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                'Land wählen:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorGrey400,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
              ),
              SizedBox(height: 30),
              Expanded(
                  child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                ),
                itemCount: countryCodes.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCountryCode = countryCodes[index];
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorGrey600,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 10),
                          Flag(
                            countryCode: countryCodes[index],
                          ),
                          SizedBox(height: 10),
                          Text(
                            countryCodes[index],
                            style: TextStyle(
                              color: colorGrey500,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ))
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
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
              color: colorWhite,
              borderRadius: BorderRadius.all(Radius.circular(9)),
            ),
            child: Center(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorBlack,
                    ),
              ),
            )),
      ),
    );
  }

  bool _validateEmail(String email) {
    // Trim the email to remove leading and trailing whitespace
    email = email.trim();
    if (email.isEmpty) {
      setState(() {
        _emailError = 'Email erforderlich';
      });
      return false;
    }

    // Email validation regex that allows dots in local part
    bool validEmail =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
            .hasMatch(email);

    if (!validEmail) {
      setState(() {
        _emailError = 'Ungültige Email-Adresse';
      });
      return false;
    }

    setState(() {
      _emailError = null;
    });
    return true;
  }

  bool _validateUsername(String username) {
    if (username.isEmpty) {
      setState(() {
        _usernameError = 'Username erforderlich';
      });
      return false;
    }

    if (username.length > 9) {
      setState(() {
        _usernameError = 'Maximal 9 Zeichen';
      });
      return false;
    }

    setState(() {
      _usernameError = null;
    });
    return true;
  }

  String _getOtpCode() {
    return _currentOtpValue;
  }

  bool _validateOtp() {
    String otpCode = _getOtpCode();
    if (otpCode.length != 6) {
      setState(() {
        _otpError = 'Bitte geben Sie alle Ziffern ein';
      });
      return false;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(otpCode)) {
      setState(() {
        _otpError = 'OTP muss aus 6 Ziffern bestehen';
      });
      return false;
    }

    setState(() {
      _otpError = null;
    });
    return true;
  }

  void _submitEmail() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_agreeToTerms) {
      _showSnackBar('Bitte akzeptiere die Nutzungsbedingungen!');
      return;
    }

    if (_validateEmail(emailController.text)) {
      try {
        setState(() {
          // Show loading indicator or disable UI
          _isLoading = true;
        });

        final authService = AuthService();

        // Check if the user already exists
        final userExists =
            await authService.checkUserExists(emailController.text);

        setState(() {
          _isExistingUser = userExists;
        });

        // Send OTP for either sign in or sign up
        bool success;

        if (_isExistingUser) {
          success = await authService.signInWithOTP(emailController.text);
        } else {
          success = await authService.signUpWithOTP(emailController.text);
        }

        if (success) {
          setState(() {
            _otpTabEnabled = true;
            _isLoading = false;
            _startResendTimer();
          });

          // Switch to OTP tab
          _tabController.animateTo(1);

          _showSnackBar(_isExistingUser
              ? 'Bestätigungscode wurde gesendet.'
              : 'Anmeldungscode wurde gesendet.');
        } else {
          _showSnackBar('Fehler beim Senden des Codes.');
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error submitting email: $e');

        String errorMessage =
            'Ein Fehler ist aufgetreten. Bitte erneut versuchen.';
        if (e is SocketException) {
          errorMessage = 'Netzwerkfehler. Überprüfe deine Verbindung.';
        }

        setState(
          () {
            _emailError = errorMessage;
            _isLoading = false;
          },
        );
      }
    }
  }

  void _verifyOtp() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_validateOtp()) {
      try {
        setState(() {
          // Show loading indicator or disable UI
          _isLoading = true;
        });

        final authService = AuthService();
        final otpCode = _getOtpCode();

        // Verify OTP
        final response =
            await authService.verifyOTP(emailController.text, otpCode);

        if (response?.user == null) {
          throw Exception('Verification failed');
        }

        if (!mounted) return;

        setState(() {
          _otpVerified = true;
          _isLoading = false;
        });

        if (_isExistingUser) {
          // Existing user - go directly to home screen
          Navigator.pushReplacementNamed(context, RouteNames.home);
        } else {
          // New user - show username overlay
          setState(() {
            _showUsernameOverlay = true;
          });
          _fadeController.forward();
        }
      } catch (e) {
        setState(() {
          _otpError = 'Ungültiger Code. Bitte erneut versuchen.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _completeRegistration() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_otpVerified) {
      _showSnackBar('Bitte bestätige zuerst den OTP-Code.');
      return;
    }

    final username = usernameController.text.trim();
    if (_validateUsername(username)) {
      try {
        setState(() {
          _isLoading = true;
        });

        final userRepo = UserProfileRepo(Supabase.instance.client);

        final isAvailable = await userRepo.checkUsernameAvailability(username);

        if (!isAvailable) {
          setState(() {
            _usernameError = 'Name schon vergeben';
          });
          return;
        }

        // Get the current user from already verified OTP
        final authService = AuthService();
        final userId = authService.currentUserId;

        if (userId == null) {
          throw Exception('User ID not found');
        }

        await userRepo.createUserProfile(
          userId: userId,
          username: username,
          countryCode: _selectedCountryCode,
        );

        if (mounted) {
          Navigator.pushReplacementNamed(context, RouteNames.deviceScan);
        }
      } catch (e) {
        _showSnackBar('Fehler bei der Registrierung. Bitte erneut versuchen.');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBlack,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('assets/images/background.jpg'),
                  fit: BoxFit.cover),
            ),
          ),
          Container(color: colorBlack.withAlpha((255 * 0.7).toInt())),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: _showUsernameOverlay ? 300 : 450,
                  width: 300,
                  decoration: BoxDecoration(
                    color: colorWhite.withAlpha((255 * 0.1).toInt()),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorWhite.withAlpha((255 * 0.1).toInt()),
                      width: 1,
                    ),
                  ),
                  child: _showUsernameOverlay
                      ? FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildUsernameContent())
                      : Column(
                          children: [
                            TabBar(
                              controller: _tabController,
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicatorWeight: 1,
                              indicator: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [colorGrey100, colorGrey600],
                                ),
                              ),
                              dividerColor: Colors.transparent,
                              tabs: [
                                Tab(text: 'anmelden'),
                                Tab(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Text('einloggen'),
                                      if (!_otpTabEnabled)
                                        Icon(Icons.lock, size: 16),
                                    ],
                                  ),
                                ),
                              ],
                              labelColor: colorBlack,
                              labelStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                              unselectedLabelColor:
                                  _otpTabEnabled ? colorGrey400 : colorGrey600,
                              unselectedLabelStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 16,
                                  ),
                              onTap: (index) {
                                // If trying to go to OTP tab but it's not enabled
                                if (index == 1 && !_otpTabEnabled) {
                                  // Cancel the tab change
                                  _tabController.animateTo(0);
                                }
                              },
                            ),
                            Expanded(
                              child: TabBarView(
                                  controller: _tabController,
                                  physics: _otpTabEnabled
                                      ? null
                                      : NeverScrollableScrollPhysics(),
                                  children: [
                                    _buildEmailTab(),
                                    _buildOtpTab(),
                                  ]),
                            )
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailTab() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(height: 10),

          // email field
          TextField(
            controller: emailController,
            onChanged: (value) {
              if (_emailError != null) {
                _validateEmail(value);
              }
            },
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorWhite,
                  fontSize: 18,
                ),
            decoration: InputDecoration(
              hintText: 'Email:',
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorGrey500,
                    fontSize: 16,
                  ),
              errorText: _emailError,
              errorStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorRed,
                  ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colorGrey400),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colorGrey400),
              ),
            ),
            cursorColor: colorGrey400,
          ),

          if (!_isExistingUser) SizedBox(height: 30),

          // Terms and conditions if new user
          if (!_isExistingUser)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ich akzeptiere die Nutzungsbedingungen und Datenschutzrichtlinien.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _agreeToTerms ? colorGrey200 : colorGrey400,
                          fontSize: 12,
                        ),
                  ),
                ),
                Checkbox(
                  value: _agreeToTerms,
                  onChanged: (value) {
                    setState(() {
                      _agreeToTerms = value ?? false;
                    });
                  },
                  activeColor: colorGrey200,
                  checkColor: colorBlack,
                  side: BorderSide(color: colorGrey400),
                ),
              ],
            ),

          SizedBox(height: 30),

          // submit button
          GestureDetector(
            onTap: _submitEmail,
            child: _buildGradientButton('weiter'),
          ),

          SizedBox(height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Weiter mit:',
                style: TextStyle(
                    color: colorBlack,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              SizedBox(width: 10),
              _buildGoogleLogin(),
              SizedBox(width: 20),
              // if (Platform.isIOS)
              _buildAppleLogin(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtpTab() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(height: 20),

          Text(
            'Ein Code wurde an ${emailController.text} gesendet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorGrey400,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 40),

          OtpInputField(
            length: 6,
            controller: _otpInputFieldController,
            onCompleted: (value) {
              setState(() {
                _currentOtpValue = value;
              });
              _verifyOtp();
            },
          ),

          if (_otpError != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _otpError!,
                style: TextStyle(
                  color: colorRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

          SizedBox(height: 40),

          // verify button
          GestureDetector(
            onTap: _verifyOtp,
            child: _buildGradientButton('bestätigen'),
          ),

          SizedBox(height: 40),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Go back option
              GestureDetector(
                onTap: () {
                  _tabController.animateTo(0);
                },
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: colorGrey400,
                  size: 20,
                ),
              ),

              // resend new code
              GestureDetector(
                onTap: _canResendOTP
                    ? () async {
                        try {
                          final authService = AuthService();
                          await authService.signInWithOTP(emailController.text);
                          _showSnackBar('Code erneut gesendet.');
                          setState(() {
                            _currentOtpValue = '';
                          });
                          _otpInputFieldController.clear();
                        } catch (e) {
                          _showSnackBar('Fehler beim Senden des Codes');
                        }
                      }
                    : null,
                child: Text(
                  _canResendOTP
                      ? 'Code erneut senden'
                      : 'Code erneut senden in ${_resendTimeoutSeconds}S',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _canResendOTP ? colorGrey200 : colorGrey400,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: colorGrey500,
                        decorationThickness: 1.5,
                      ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildUsernameContent() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            'Username eingeben:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorGrey400,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                // username textfield
                Expanded(
                  child: TextField(
                    controller: usernameController,
                    onChanged: (value) {
                      if (_usernameError != null) {
                        _validateUsername(value);
                      }
                    },
                    enableSuggestions: false,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorWhite,
                          fontSize: 18,
                        ),
                    decoration: InputDecoration(
                      hintText: 'Username:',
                      hintStyle:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorGrey500,
                                fontSize: 16,
                              ),
                      errorText: _usernameError,
                      errorStyle:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorRed,
                              ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: colorGrey400),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: colorGrey400),
                      ),
                    ),
                    cursorColor: colorGrey400,
                    maxLength: 9,
                    buildCounter: (context,
                            {required currentLength,
                            required isFocused,
                            required maxLength}) =>
                        Text(
                      '0${9 - currentLength}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorBlack,
                          ),
                    ),
                  ),
                ),

                SizedBox(width: 20),

                // flag
                GestureDetector(
                  onTap: _showCountrySelector,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flag(countryCode: _selectedCountryCode),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 30,
                        color: colorGrey400,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          GestureDetector(
            onTap: _completeRegistration,
            child: _buildGradientButton('fertig'),
          ),
          SizedBox(height: 5)
        ],
      ),
    );
  }

  Widget _buildGoogleLogin() {
    return GestureDetector(
      onTap: () async {
        try {
          final authService = AuthService();
          await authService.signInWithGoogle();
        } catch (e) {
          _showSnackBar('Google-Anmeldung fehlgeschlagen');
        }
      },
      child: Container(
        padding: EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorWhite.withOpacity(0.4),
        ),
        child: SvgPicture.asset(
          'assets/images/google.svg',
          height: 25,
          width: 25,
          colorFilter: ColorFilter.mode(colorBlack, BlendMode.srcIn),
        ),
      ),
    );
  }

  Widget _buildAppleLogin() {
    return GestureDetector(
      onTap: () async {
        try {
          final authService = AuthService();
          await authService.signInWithApple();
        } catch (e) {
          _showSnackBar('Apple-Anmeldung fehlgeschlagen');
        }
      },
      child: Container(
        height: 33,
        width: 33,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorWhite.withOpacity(0.4),
        ),
        child: Center(
          child: Icon(
            Icons.apple_rounded,
            size: 25,
            color: colorBlack,
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton(String buttonText) {
    return Container(
      width: double.infinity,
      height: kToolbarHeight,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(27),
          gradient: LinearGradient(colors: [colorGrey100, colorGrey600])),
      child: Center(
        child: _isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: colorBlack,
                  strokeWidth: 3,
                ),
              )
            : Text(
                buttonText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorBlack,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
              ),
      ),
    );
  }
}
