import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'design_tokens.dart';
import 'router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep a slightly larger in-memory image cache to avoid frequent re-decodes
  // while moving between screens with heavy photo content.
  PaintingBinding.instance.imageCache.maximumSize = 250;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 180 << 20;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CowBnB',
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
