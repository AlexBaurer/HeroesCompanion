import 'package:flutter/material.dart';
import 'package:heroescompanion/features/factions/factions_data.dart';
import 'package:heroescompanion/features/factions/reorder_list.dart';
import 'package:heroescompanion/features/factions/resource_counter_wheel.dart';

class FactionDetailScreen extends StatefulWidget {
  final String factionName;

  const FactionDetailScreen({super.key, required this.factionName});

  @override
  State<FactionDetailScreen> createState() => _FactionDetailScreenState();
}

class _FactionDetailScreenState extends State<FactionDetailScreen> {
  late Faction _faction;
  int _round = 1; // общий счётчик раунда

  // Карта: "название ресурса" → значение
  Map<String, int> _resources = {};

  @override
  void initState() {
    super.initState();
    _faction = Faction.fromName(widget.factionName) ?? Faction.all[0];
    
    // Инициализируем ресурсы нулями
    _resources = {
      for (final res in _faction.resources) res: 0,
    };
  }

  void _nextRound() {
    setState(() {
      _round++;
      _round = _round.clamp(1, 16);
    });
  }

  void _changeResource(String key, int delta) {
    setState(() {
      _resources[key] = (_resources[key]! + delta).clamp(0, 999);
    });
  }

  @override
  Widget build(BuildContext context) {

    final List<String> heroImages = [
          'assets/wood.PNG',
          'assets/iron.PNG',
          'assets/gold.PNG',
          'assets/move.PNG',
          'assets/build.PNG',
        ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_faction.name),
        backgroundColor: _faction.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Кнопка "Следующий раунд"
            _buildNextRoundButton(),
            const SizedBox(height: 24),

            // Текущий раунд (только для информации)
            Text(
              'Текущий раунд: $_round',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            _buildResourceBlocksPanel(),
            const SizedBox(height: 24),

            // Заголовок ресурсов
            const Text(
              'Ресурсы:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Счётчики ресурсов
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: ListView(
                      children: _faction.resources.map((res) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                res,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ResourceCounterWheel(
                                resource: res,
                                initialValue: _resources[res] ?? 0,
                                onValueChanged: (newValue) {
                                  setState(() {
                                    _resources[res] = newValue;
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    height: 350, 
                    width: 160, 
                    child: ResourceOrderImageList(imageAssets: heroImages),
                  ),
                ],
              ),
            ),  
          ],
        ),
      ),
    );
  }

  Widget _buildNextRoundButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _nextRound,
        child: const Text(
          'Следующий раунд',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildResourceBlocksPanel() {
    final List<Map<String, dynamic>> resourceBlocks = [
      {'image': 'assets/wood.PNG', 'count': _resources[_faction.resources.length > 0 ? _faction.resources[0] : ''] ?? 0},
      {'image': 'assets/iron.PNG', 'count': _resources[_faction.resources.length > 1 ? _faction.resources[1] : ''] ?? 0},
      {'image': 'assets/gold.PNG', 'count': _resources[_faction.resources.length > 2 ? _faction.resources[2] : ''] ?? 0},
      {'image': 'assets/move.PNG', 'count': _resources[_faction.resources.length > 3 ? _faction.resources[3] : ''] ?? 0},
      {'image': 'assets/build.PNG', 'count': _resources[_faction.resources.length > 4 ? _faction.resources[4] : ''] ?? 0},
    ];

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: resourceBlocks.map((block) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  block['image'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                ),
                Text(
                  '${block['count']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}


