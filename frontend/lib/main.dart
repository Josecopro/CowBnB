import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'design_tokens.dart';
import 'router.dart';
import 'services/firebase_service.dart';
import 'providers/auth_provider.dart';
import 'providers/terrenos_provider.dart';

final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep a slightly larger in-memory image cache to avoid frequent re-decodes
  // while moving between screens with heavy photo content.
  PaintingBinding.instance.imageCache.maximumSize = 250;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 180 << 20;

  // Initialize Firebase
  try {
    await FirebaseService.initialize();
    logger.i('Firebase initialized successfully');
  } catch (e) {
    logger.e('Failed to initialize Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Provider
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        // Terrenos Provider
        ChangeNotifierProvider<TerrenoProvider>(
          create: (_) => TerrenoProvider(),
        ),
      ],
      child: MaterialApp.router(
        title: 'CowBnB',
        theme: buildAppTheme(),
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
