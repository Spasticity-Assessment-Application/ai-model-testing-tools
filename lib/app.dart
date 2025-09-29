import 'package:flutter/material.dart';
import 'package:poc/core/router/app_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AppRouter().router;

    return MaterialApp.router(
      title: 'POC Spasticity Assessment Application',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
