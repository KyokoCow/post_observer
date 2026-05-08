import 'package:flutter/material.dart';

import '../services/token_service.dart';
import 'home_page.dart';

class TokenPage extends StatefulWidget {
  const TokenPage({super.key});

  @override
  State<TokenPage> createState() =>
      _TokenPageState();
}

class _TokenPageState
    extends State<TokenPage> {
  final controller = TextEditingController();

  final tokenService = TokenService();

  Future<void> save() async {
    await tokenService.saveToken(
      controller.text.trim(),
    );

    if (mounted) {
      Future<void> save() async {
        await tokenService.saveToken(
          controller.text.trim(),
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const HomePage(),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qiita Token'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration:
              const InputDecoration(
                labelText:
                'Qiita API Token',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: save,
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}