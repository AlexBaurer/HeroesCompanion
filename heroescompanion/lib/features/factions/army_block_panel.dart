import 'package:flutter/material.dart';
import 'package:heroescompanion/features/factions/factions_data.dart';
import 'package:heroescompanion/features/factions/resource_counter_wheel.dart';

class ArmyBlockPanel extends StatefulWidget {
  final Faction faction;

  const ArmyBlockPanel({super.key, required this.faction});

  @override
  State<ArmyBlockPanel> createState() => _ArmyBlockPanelState();
}

class _ArmyBlockPanelState extends State<ArmyBlockPanel> {
  // Maps to store the count of total and deployed units
  Map<String, int> _totalUnits = {};
  Map<String, int> _deployedUnits = {};

  @override
  void initState() {
    super.initState();
    _initializeUnitMaps();
  }

  @override
  void didUpdateWidget(covariant ArmyBlockPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reinitialize if the faction has changed
    if (oldWidget.faction != widget.faction) {
      _initializeUnitMaps();
    }
  }

  void _initializeUnitMaps() {
    // Initialize maps with zeros for each unit type
    Map<String, int> newTotalUnits = {};
    Map<String, int> newDeployedUnits = {};
    
    for (int i = 0; i < widget.faction.units.length; i++) {
      String unit = widget.faction.units[i];
      newTotalUnits[unit] = _totalUnits[unit] ?? 0;
      newDeployedUnits[unit] = _deployedUnits[unit] ?? 0;
    }
    
    _totalUnits = newTotalUnits;
    _deployedUnits = newDeployedUnits;
  }

  int getModifiedPower(String unitName) {
    return widget.faction.getModifiedPower(unitName);
  }

  // Calculate total army strength (sum of power of all total units)
  int get totalArmyStrength {
    int strength = 0;
    for (int i = 0; i < widget.faction.units.length; i++) {
      String unit = widget.faction.units[i];
      int power = getModifiedPower(unit);
      if (widget.faction.name != 'Наги') {
        strength += (_totalUnits[unit] ?? 0) * power;
      }
      else {
        strength += (_totalUnits[unit] ?? 0) * (_totalUnits[unit] ?? 0);
      }
    }
    return strength;
  }

  // Calculate deployed army strength (sum of power of all deployed units)
  int get deployedArmyStrength {
    int strength = 0;
    for (int i = 0; i < widget.faction.units.length; i++) {
      String unit = widget.faction.units[i];
      int power = getModifiedPower(unit);
      if (widget.faction.name != 'Наги') {
        strength += (_deployedUnits[unit] ?? 0) * power;
      }
      else {
        strength += (_deployedUnits[unit] ?? 0) * (_deployedUnits[unit] ?? 0);
      }
    }
    return strength;
  }

  void _updateTotalUnits(String unit, int value) {
    setState(() {
      _totalUnits[unit] = value;
      // Ensure deployed units don't exceed total units
      if ((_deployedUnits[unit] ?? 0) > value) {
        _deployedUnits[unit] = value;
      }
    });
  }

  void _updateDeployedUnits(String unit, int value) {
    setState(() {
      _deployedUnits[unit] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use army units data from the faction
    final List<String> armyUnits = widget.faction.units;

    return Container(
      height: 180, // Increased height to accommodate strength counters
      child: Column(
        children: [
          // Strength counters row
          Container(
            height: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Total army strength
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    border: Border.all(color: Colors.white, width: 2.0),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Cила армии: $totalArmyStrength', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),                    
                    ],
                  ),
                ),
                // Deployed army strength
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    border: Border.all(color: Colors.white, width: 2.0),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Сила в бой: $deployedArmyStrength', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),                      
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Units display row
          Expanded(
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
                        widget.faction.unitsAssets[index],
                        fit: BoxFit.fill,
                        width: 100,
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
                              child: ResourceCounterWheel(
                                resource: 'total_$unit',
                                initialValue: _totalUnits[unit] ?? 0,
                                heightOfWheel: 90,
                                fontSize: 40,
                                onValueChanged: (value) {
                                  _updateTotalUnits(unit, value);
                                },
                              ),
                            ),
                            // Deployed units counter
                            Container(
                              child: ResourceCounterWheel(
                                resource: 'deployed_$unit',
                                initialValue: _deployedUnits[unit] ?? 0,
                                heightOfWheel: 50,
                                fontSize: 25,
                                onValueChanged: (value) {
                                  // Only allow deploying up to the total units count
                                  int maxValue = _totalUnits[unit] ?? 0;
                                  if (value <= maxValue) {
                                    _updateDeployedUnits(unit, value);
                                  }
                                },
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
          ),
        ],
      ),
    );
  }
}