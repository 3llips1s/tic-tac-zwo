import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tic_tac_zwo/config/game_config/constants.dart';

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
  bool _obscurePassword = true;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _showUsernameOverlay = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
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
    emailController.dispose();
    passwordController.dispose();
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
            ),
            cursorColor: colorGrey400,
          ),

          SizedBox(height: 20),

          // password
          TextField(
            obscureText: _obscurePassword,
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
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colorGrey400),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colorGrey400),
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: _obscurePassword ? colorGrey400 : colorGrey200,
                  size: 20,
                ),
              ),
            ),
            cursorColor: colorGrey400,
          ),

          SizedBox(height: 50),

          _buildGradientButton('einloggen'),

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
            controller: emailController,
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
            controller: passwordController,
            obscureText: _obscurePassword,
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
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colorGrey400),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colorGrey400),
              ),
              suffixIcon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: _obscurePassword ? colorGrey400 : colorGrey200,
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
                value: !_obscurePassword,
                onChanged: (value) {
                  setState(() {
                    _obscurePassword = !(value ?? false);
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
            onTap: _handleRegistration,
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
    final TextEditingController usernameController = TextEditingController();

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
            onTap: () {
              // Save username and continue to main app
              // if (usernameController.text.isNotEmpty) {
              //   // Update user profile with the username
              //   // Then navigate to your main app screen
              //   Navigator.pushReplacementNamed(context, RouteNames.login);
              // }
              Navigator.pushReplacementNamed(context, RouteNames.login);
            },
            child: _buildGradientButton('fertig'),
          ),
        ],
      ),
    );
  }

  void _handleRegistration() {
    // validate email and password

    // if valid register user with supabase

    setState(() {
      _showUsernameOverlay = true;
    });
    _fadeController.forward();
  }
}
