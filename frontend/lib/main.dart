import 'package:flutter/material.dart';
import 'design_tokens.dart';
import 'router.dart';

void main() {
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
