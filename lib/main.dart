import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tic_tac_zwo/app.dart';
import 'package:tic_tac_zwo/config/auth_config/auth_config.dart';

import 'config/game_config/theme.dart';
import 'routes/app_router.dart';
import 'routes/route_names.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  await Supabase.initialize(
      url: AuthConfig.url,
      anonKey: AuthConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ));

  runApp(ProviderScope(child: const MainApp()));
}

class MainApp extends StatelessWidget {
  // global key for scaffold messenger
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: Scaffold(
        body: const App(),
      ),
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: RouteNames.home,
      scaffoldMessengerKey: scaffoldMessengerKey,
    );
  }
}
