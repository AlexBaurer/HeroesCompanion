import 'package:flutter/material.dart';
// import 'package:heroescompanion/routes/app_routes.dart';

class FactionChooseMenu extends StatelessWidget {
  const FactionChooseMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('          Герои\nВыбери фракцию'),
        centerTitle: true,
      ),
      body: const MainMenuContent(),
    );
  }
}

class MainMenuContent extends StatelessWidget {
  const MainMenuContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Список всех фракций/существ
    final List<String> factions = [
      'Люди',
      'Нежить',
      'Гномы',
      'Орки',
      'Эльфы',
      'Наги',
      'Гремлины',
      'Механизмы',
      'Элементали',
      'Демоны',
      'Полурослики',
      'Культисты',
    ];

    // Делим на два столбца
    final leftColumn = factions.sublist(0, 6);
    final rightColumn = factions.sublist(6, 12);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              _MenuColumn(items: leftColumn),
              const SizedBox(width: 16),
              _MenuColumn(items: rightColumn),
            ],
          ),          
        ],
      ),
      ),
    );
  }
}

class _MenuColumn extends StatelessWidget {
  final List<String> items;

  const _MenuColumn({required this.items});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              height: 90,
              width: 160,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getFactionColor(item),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/faction',
                    arguments: item,
                  );
                },
                child: Text(
                  item,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getFactionColor(String faction) {
    switch (faction) {
      case 'Люди': return const Color.fromARGB(255, 190, 87, 55);
      case 'Нежить': return const Color.fromARGB(255, 8, 138, 170);
      case 'Гномы': return const Color.fromARGB(255, 100, 100, 100);
      case 'Орки': return const Color.fromARGB(255, 219, 173, 19);
      case 'Эльфы': return const Color.fromARGB(255, 115, 46, 180);
      case 'Наги': return const Color.fromARGB(255, 0, 198, 212);
      case 'Гремлины': return const Color.fromARGB(255, 199, 83, 147);
      case 'Механизмы': return const Color.fromARGB(255, 145, 182, 77);
      case 'Элементали': return Colors.red;
      case 'Демоны': return const Color.fromARGB(255, 76, 47, 124);
      case 'Полурослики': return const Color.fromARGB(255, 221, 121, 6);
      case 'Культисты': return const Color.fromARGB(255, 88, 63, 43);
      default: return Colors.blue;
    }
  }
}