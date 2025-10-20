import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:heroescompanion/features/factions/factions_data.dart';

class StrengthModModalMenu extends StatefulWidget {
  final Faction faction;
  final Function(Faction) onFactionUpdated;
  final Map<String, List<dynamic>> modifierStates; // Changed to dynamic to store both bool and int
  final String factionName;
  
  const StrengthModModalMenu({
    super.key, 
    required this.faction,
    required this.onFactionUpdated,
    required this.modifierStates,
    required this.factionName,
  });

  @override
  State<StrengthModModalMenu> createState() => _StrengthModModalMenuState();
}

class _StrengthModModalMenuState extends State<StrengthModModalMenu> {
  late List<StrengthModifier> _modifiers;

  @override
  void initState() {
    super.initState();
    // Create a copy of the modifiers to work with
    _modifiers = widget.faction.strengthModifiers.map((modifier) {
      if (modifier is ToggleStrengthModifier) {
        return ToggleStrengthModifier(
          unitName: modifier.unitName,          
          basePower: modifier.basePower,
          bonusPower: modifier.bonusPower,
          isEnabled: _getModifierState(modifier.unitName, modifier.type),
        );
      } else if (modifier is CounterStrengthModifier) {
        final counterModifier = modifier as CounterStrengthModifier;
        return CounterStrengthModifier(
          unitName: counterModifier.unitName,          
          basePower: counterModifier.basePower,
          powerPerCount: counterModifier.powerPerCount,
          maxCount: counterModifier.maxCount,
          count: _getCounterState(counterModifier.unitName),
        );
      }
      return modifier;
    }).toList();
  }

  bool _getModifierState(String unitName, String type) {
    if (type == 'toggle') {
      final states = widget.modifierStates[widget.factionName];
      if (states != null) {
        final index = widget.faction.strengthModifiers
            .where((m) => m.type == 'toggle')
            .toList()
            .indexWhere((m) => m.unitName == unitName);
        if (index != -1 && index < states.length) {
          return states[index] as bool? ?? false;
        }
      }
    }
    return false;
  }

  int _getCounterState(String unitName) {
    final states = widget.modifierStates[widget.factionName];
    if (states != null) {
      // Counters are stored after toggles
      final toggleModifiersCount = widget.faction.strengthModifiers
          .where((m) => m.type == 'toggle')
          .length;
      
      final counterModifiers = widget.faction.strengthModifiers
          .where((m) => m.type == 'counter')
          .toList();
          
      final index = counterModifiers.indexWhere((m) => m.unitName == unitName);
      
      if (index != -1) {
        final position = toggleModifiersCount + index;
        if (position < states.length) {
          return states[position] as int? ?? 0;
        }
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 800,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Модификаторы силы для "${widget.faction.name}"',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _modifiers.length,
              itemBuilder: (context, index) {
                final modifier = _modifiers[index];
                if (modifier is ToggleStrengthModifier) {
                  return CheckboxListTile(
                    title: Text('Увеличить силу юнита (${modifier.unitName}): '
                        '${modifier.basePower} → ${modifier.bonusPower}'),
                    value: modifier.isEnabled,
                    onChanged: (bool? value) {
                      setState(() {
                        modifier.toggle();
                        _saveModifierState(modifier);
                        _updateFaction();
                      });
                    },
                  );
                } else if (modifier is CounterStrengthModifier) {
                  return ListTile(
                    title: Text('Увеличить силу юнита (${modifier.unitName})'),
                    subtitle: Text('Базовая сила: ${modifier.basePower}, '
                        'Текущая: ${modifier.applyModifier(modifier.basePower)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              if (modifier.count > 0) {
                                modifier.count--;                                
                                _saveCounterState(modifier);
                                _updateFaction();
                              }
                            });
                          },
                        ),
                        Text('${modifier.count}', style: TextStyle(fontSize: 25)),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              if (modifier.count < modifier.maxCount) {
                                modifier.count++;                                
                                _saveCounterState(modifier);
                                _updateFaction();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }
                return Container();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _saveModifierState(ToggleStrengthModifier modifier) {
    // Find the index of this modifier among toggle modifiers
    final toggleModifiers = widget.faction.strengthModifiers
        .where((m) => m is ToggleStrengthModifier)
        .toList();
    
    final index = toggleModifiers.indexWhere((m) => m.unitName == modifier.unitName);
    
    if (index != -1) {
      // Ensure the list is large enough
      if (widget.modifierStates[widget.factionName]!.length <= index) {
        // Extend the list with default values
        final currentLength = widget.modifierStates[widget.factionName]!.length;
        widget.modifierStates[widget.factionName]!
            .addAll(List<dynamic>.filled(index - currentLength + 1, false));
      }
      
      // Update the state
      widget.modifierStates[widget.factionName]![index] = modifier.isEnabled;
    }
  }

  void _saveCounterState(CounterStrengthModifier modifier) {
    // Find the index of this modifier among counter modifiers
    final counterModifiers = widget.faction.strengthModifiers
        .where((m) => m is CounterStrengthModifier)
        .toList();
    
    final index = counterModifiers.indexWhere((m) => m.unitName == modifier.unitName);
    
    if (index != -1) {
      // Counter values are stored after toggle values
      final toggleModifiersCount = widget.faction.strengthModifiers
          .where((m) => m is ToggleStrengthModifier)
          .length;
          
      final position = toggleModifiersCount + index;
      
      // Ensure the list is large enough
      if (widget.modifierStates[widget.factionName]!.length <= position) {
        // Extend the list with default values
        final currentLength = widget.modifierStates[widget.factionName]!.length;
        widget.modifierStates[widget.factionName]!
            .addAll(List<dynamic>.filled(position - currentLength + 1, 0));
      }
      
      // Update the state
      widget.modifierStates[widget.factionName]![position] = modifier.count;
    }
  }

  void _updateFaction() {
    // Create a new faction with updated modifiers and notify parent
    final updatedFaction = widget.faction.copyWith(
      strengthModifiers: _modifiers,
    );

    if (kDebugMode) {
      debugPrint('Updating faction with modifiers:');
      for (var modifier in _modifiers) {
        if (modifier is ToggleStrengthModifier) {
          debugPrint('  ${modifier.unitName}: ${modifier.isEnabled}');
        } else if (modifier is CounterStrengthModifier) {
          debugPrint('  ${modifier.unitName}: ${modifier.count}');
        }
      }
    }
    
    widget.onFactionUpdated(updatedFaction);
  }
}