import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/token_page.dart';
import 'services/token_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> hasToken() async {
    final tokenService = TokenService();

    final token =
    await tokenService.loadToken();

    return token != null &&
        token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Post Observer',
      theme: ThemeData(
        useMaterial3: true,
      ),

      home: FutureBuilder<bool>(
        future: hasToken(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(
                child:
                CircularProgressIndicator(),
              ),
            );
          }

          final hasToken =
              snapshot.data ?? false;

          if (hasToken) {
            return const HomePage();
          }

          return const TokenPage();
        },
      ),
    );
  }
}