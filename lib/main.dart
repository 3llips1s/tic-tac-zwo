import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tic_tac_zwo/app.dart';
import 'package:tic_tac_zwo/config/auth_config/auth_config.dart';
import 'package:tic_tac_zwo/hive/hive_registrar.g.dart';

import 'config/game_config/theme.dart';
import 'features/game/online/data/models/german_noun_hive.dart';
import 'routes/app_router.dart';
import 'routes/route_names.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AuthConfig.url,
    anonKey: AuthConfig.anonKey,
  );

  final Directory appDocumentDir = await getApplicationDocumentsDirectory();
  Hive
    ..initFlutter(appDocumentDir.path)
    ..registerAdapters();

  await Hive.openBox<GermanNounHive>('german_nouns');
  await Hive.openBox('sync_info');

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark));

  runApp(const ProviderScope(child: MainApp()));
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
      home: Scaffold(body: const App()),
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: RouteNames.home,
      scaffoldMessengerKey: scaffoldMessengerKey,
    );
  }
}
