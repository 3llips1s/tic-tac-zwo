import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';
import 'package:tic_tac_zwo/features/auth/data/repositories/user_profile_repo.dart';
import 'package:tic_tac_zwo/features/auth/data/services/auth_service.dart';

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
  TextEditingController loginEmailController = TextEditingController();
  TextEditingController loginPasswordController = TextEditingController();
  TextEditingController signupEmailController = TextEditingController();
  TextEditingController signupPasswordController = TextEditingController();
  TextEditingController usernameController = TextEditingController();

  bool _obscureLoginPassword = true;
  bool _obscureSignupPassword = true;
  bool _showUsernameOverlay = false;

  String? _emailError;
  String? _passwordError;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  bool _validateEmail(String email) {
    if (email.isEmpty) {
      setState(() {
        _emailError = 'Email ist erforderlich';
      });
      return false;
    }

    // validation regex
    bool validEmail = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
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

  bool _validatePassword(String password) {
    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Passwort ist erforderlich';
      });
      return false;
    }

    if (password.length < 6) {
      setState(() {
        _passwordError = 'Passwort muss mindestens 6 Zeichen haben';
      });
      return false;
    }

    setState(() {
      _passwordError = null;
    });
    return true;
  }

  bool _validateUsername(String username) {
    if (username.isEmpty) {
      setState(() {
        _usernameError = 'Username ist erforderlich';
      });
      return false;
    }

    if (username.length > 9) {
      setState(() {
        _usernameError = 'Username darf maximal 9 Zeichen haben';
      });
      return false;
    }

    setState(() {
      _usernameError = null;
    });
    return true;
  }

  void _initializeControllers() {
    // tab controller
    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    // username overlay fade in controller
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    loginEmailController.dispose();
    loginPasswordController.dispose();
    signupEmailController.dispose();
    signupPasswordController.dispose();
    usernameController.dispose();
    super.dispose();
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
                  height: _showUsernameOverlay ? 300 : 400,
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
                                Tab(text: 'einloggen')
                              ],
                              labelColor: colorBlack,
                              labelStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                              unselectedLabelColor: colorGrey600,
                              unselectedLabelStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 16,
                                  ),
                            ),
                            Expanded(
                              child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _buildSignupTab(),
                                    _buildLoginTab()
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

  _buildLoginTab() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(height: 10),

          // username or email
          TextField(
            controller: loginEmailController,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorWhite,
                  fontSize: 18,
                ),
            decoration: InputDecoration(
                hintText: 'Username/Email:',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorGrey500,
                      fontSize: 16,
                    ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colorGrey400),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colorGrey400),
                ),
                errorText: _emailError),
            cursorColor: colorGrey400,
          ),

          SizedBox(height: 20),

          // password
          TextField(
            controller: loginPasswordController,
            obscureText: _obscureLoginPassword,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorWhite,
                  fontSize: 18,
                ),
            decoration: InputDecoration(
              hintText: 'Passwort:',
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorGrey500,
                    fontSize: 16,
                  ),
              errorText: _passwordError,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colorGrey400),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colorGrey400),
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscureLoginPassword = !_obscureLoginPassword;
                  });
                },
                icon: Icon(
                  _obscureLoginPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: _obscureLoginPassword ? colorGrey400 : colorGrey200,
                  size: 20,
                ),
              ),
            ),
            cursorColor: colorGrey400,
          ),

          SizedBox(height: 50),

          // login button
          GestureDetector(
            onTap: _handleLogin,
            child: _buildGradientButton('einloggen'),
          ),

          SizedBox(height: 40),

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

  _buildSignupTab() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // email field
          TextField(
            controller: signupEmailController,
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
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colorGrey400),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colorGrey400),
              ),
            ),
            cursorColor: colorGrey400,
          ),
          SizedBox(height: 20),

          // password field with toggle
          TextField(
            controller: signupPasswordController,
            obscureText: _obscureSignupPassword,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorWhite,
                  fontSize: 18,
                ),
            decoration: InputDecoration(
              hintText: 'Passwort:',
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorGrey500,
                    fontSize: 16,
                  ),
              errorText: _passwordError,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colorGrey400),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colorGrey400),
              ),
              suffixIcon: Icon(
                _obscureSignupPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: _obscureSignupPassword ? colorGrey400 : colorGrey200,
                size: 20,
              ),
            ),
            cursorColor: colorGrey400,
          ),

          SizedBox(height: 15),

          // show password toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Passwort anzeigen?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorGrey400,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Checkbox(
                value: !_obscureSignupPassword,
                onChanged: (value) {
                  setState(() {
                    _obscureSignupPassword = !(value ?? false);
                  });
                },
                activeColor: colorGrey200,
                checkColor: colorBlack,
                side: BorderSide(color: colorGrey400),
              ),
            ],
          ),

          SizedBox(height: 15),

          // register button
          GestureDetector(
            onTap: _startRegistration,
            child: _buildGradientButton('anmelden'),
          ),

          SizedBox(height: 20),

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

  _buildGoogleLogin() {
    return Container(
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
    );
  }

  _buildAppleLogin() {
    return GestureDetector(
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

  _buildGradientButton(String buttonText) {
    return Container(
      width: double.infinity,
      height: kToolbarHeight,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(27),
          gradient: LinearGradient(colors: [colorGrey100, colorGrey600])),
      child: Center(
        child: Text(
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

  _buildUsernameContent() {
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
          SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: usernameController,
              enableSuggestions: false,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorWhite,
                    fontSize: 18,
                  ),
              decoration: InputDecoration(
                hintText: 'Username:',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorGrey500,
                      fontSize: 16,
                    ),
                errorText: _usernameError,
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
          SizedBox(height: 30),
          GestureDetector(
            onTap: () async {
              final username = usernameController.text.trim();
              if (_validateUsername(username)) {
                try {
                  final userRepo = UserProfileRepo(Supabase.instance.client);

                  final exists =
                      await userRepo.checkUsernameAvailability(username);

                  if (exists) {
                    setState(() {
                      _usernameError = 'Username bereits vergeben';
                    });
                    return;
                  }
                  _registerUser();
                } catch (e) {
                  setState(() {
                    _usernameError = 'Fehler bei der Überprüfung des Usernames';
                  });
                }
              }
            },
            child: _buildGradientButton('fertig'),
          ),
        ],
      ),
    );
  }

  void _startRegistration() {
    bool isEmailValid = _validateEmail(signupEmailController.text);
    bool isPasswordValid = _validatePassword(signupPasswordController.text);

    // validate email and password + register to supabase
    if (isEmailValid && isPasswordValid) {
      setState(() {
        _showUsernameOverlay = true;
      });
      _fadeController.forward();
    }
  }

  Future<void> _registerUser() async {
    try {
      final authService = AuthService(Supabase.instance.client);
      final response = await authService.signUp(
        signupEmailController.text,
        signupPasswordController.text,
      );

      if (response.user != null) {
        // update user profile with username and country code
        await UserProfileRepo(Supabase.instance.client).updateUserProfile(
          userId: response.user!.id,
          username: usernameController.text,
          countryCode: 'KE',
        );
      }
    } catch (e) {
      setState(() {
        _emailError = 'Registration fehlgeschlagen: ${e.toString()}';
      });
    }
  }

  void _handleLogin() {
    bool isEmailValid = _validateEmail(loginEmailController.text);
    bool isPasswordValid = _validatePassword(loginPasswordController.text);

    // validate email and password + register to supabase
    if (isEmailValid && isPasswordValid) {
      _loginUser();
    }
  }

  Future<void> _loginUser() async {
    try {
      final authService = AuthService(Supabase.instance.client);
      final response = await authService.signIn(
        loginEmailController.text,
        loginPasswordController.text,
      );

      if (response.user != null) {
        Navigator.pushReplacementNamed(context, RouteNames.home);
      }
    } catch (e) {
      setState(() {
        _emailError = 'Login fehlgeschlagen: ${e.toString()}';
      });
    }
  }
}
