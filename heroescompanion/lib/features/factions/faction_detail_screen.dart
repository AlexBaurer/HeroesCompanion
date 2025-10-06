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

            _buildArmyBlocksPanel(_faction),
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

  Widget _buildArmyBlocksPanel(faction) {
    // This panel now shows army unit slots based on the selected faction
    // Each unit slot has an image and two counters: total units and deployed units
    
    // Use army units data from the faction
    final List<String> armyUnits = faction.units ?? [];

    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: armyUnits.asMap().entries.map((entry) {
          int index = entry.key;
          String unit = entry.value;
          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: Stack(
              children: [
                // Unit image
                Image.asset(
                  faction.unitsAssets[index],
                  fit: BoxFit.cover,
                ),
                // Counters overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      // Total units counter
                      Container(
                        color: Colors.black54,
                        child: Text(
                          unit,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Deployed units counter
                      Container(
                        color: Colors.redAccent,
                        child: Text(
                          unit,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
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


