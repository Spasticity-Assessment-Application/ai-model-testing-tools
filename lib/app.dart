import 'package:flutter/material.dart';
import 'package:poc/core/router/app_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AppRouter().router;

    return MaterialApp.router(
      title: 'Application d\'évaluation de la spasticité POC',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
