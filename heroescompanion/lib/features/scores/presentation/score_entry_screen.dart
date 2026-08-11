import 'package:flutter/material.dart';

class ScoreEntryScreen extends StatelessWidget {
  const ScoreEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ввод очков')),
      body: const Center(child: Text('Заглушка: ввод очков')),
    );
  }
}
