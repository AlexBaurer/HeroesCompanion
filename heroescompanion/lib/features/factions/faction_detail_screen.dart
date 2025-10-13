import 'package:flutter/material.dart';
import 'package:heroescompanion/features/factions/factions_data.dart';
import 'package:heroescompanion/features/factions/reorder_list.dart';
import 'package:heroescompanion/features/factions/resource_counter_wheel.dart';
import 'package:heroescompanion/features/factions/army_block_panel.dart';
import 'package:heroescompanion/features/factions/strenght_mod_modal_menu.dart';

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

  final Map<String, List<bool>> _strengthModifierStates = {};

  @override
  void initState() {
    super.initState();
    _faction = Faction.fromName(widget.factionName) ?? Faction.all[0];
    
    // Инициализируем ресурсы нулями
    _resources = {
      for (final res in _faction.resources) res: 0,
    };

    _initializeStrengthModifierStates(_faction.name);
  }

  void _initializeStrengthModifierStates(String factionName) {
    if (!_strengthModifierStates.containsKey(factionName)) {
      _strengthModifierStates[factionName] = List<bool>.filled(3, false);
    }
  }

  void _nextRound() {
    setState(() {
      _round++;
      _round = _round.clamp(1, 16);
    });
  }

  void _showModalWindow(BuildContext context) {

    _initializeStrengthModifierStates(_faction.name);

    showModalBottomSheet(      
      context: context,
      builder: (BuildContext context) {
        return StrengthModModalMenu(
          faction: _faction,
          initialCheckboxValues: _strengthModifierStates[_faction.name]!,
          onFactionUpdated: (Faction updatedFaction) {
            setState(() {
              _faction = updatedFaction;
              // Save checkbox states
              _strengthModifierStates[_faction.name] = List<bool>.from(
                (_strengthModifierStates[_faction.name] ?? List<bool>.filled(3, false))
              );
            });
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {

    final List<String> resourceImages = [
          'assets/wood.PNG',
          'assets/iron.PNG',
          'assets/gold.PNG',
          'assets/move.PNG',
          'assets/build.PNG',
        ];

    return Scaffold(
      appBar: AppBar(
        // title: Text(_faction.name),
        backgroundColor: _faction.primaryColor,
        // foregroundColor: Colors.white,
        toolbarHeight: 0,
        
      ),
      body: Stack(
        children: [
          // Background image with semi-transparency
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 109, 109, 109),
              ),
              child: Opacity(
                opacity: 0.2, 
                child: Image.asset(
                  _faction.backgroundPicture,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Кнопка "Следующий раунд"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Текущий раунд (только для информации)
                    Text(
                      'Текущий\nраунд: $_round',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    _buildNextRoundButton(),
                  ],
                ),
                const SizedBox(height: 14),

                // _buildArmyBlocksPanel(_faction),
                ArmyBlockPanel(faction: _faction),
                const SizedBox(height: 4),

                Center(
                  child: SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    
                      onPressed: () {
                        _showModalWindow(context);
                      },
                        child: Text('МОДИФИКАТОРЫ СИЛЫ', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 4),

                // Заголовок ресурсов
                Row(
                  children: [
                    // Заголовок ресурсов
                    SizedBox(width: 10),
                    Text(
                      'Ресурсы',                      
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: const Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    // Кнопка "Изменить порядок ресурсов"
                    // SizedBox(width: 70),
                    Spacer(),
                    Text('Порядок действий',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: const Color.fromARGB(255, 255, 255, 255),                    
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
                const SizedBox(height: 4),

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
                                  // Text(
                                  //   res,
                                  //   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  // ),
                                  // const SizedBox(height: 8),
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
                      Expanded(
                        // height: 350, 
                        // width: 160, 
                        child: ResourceOrderImageList(imageAssets: resourceImages),
                      ),
                    ],
                  ),
                ),  
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextRoundButton() {
    return SizedBox(
      width: 200,
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
}