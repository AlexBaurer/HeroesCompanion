import 'package:flutter/material.dart';
import 'package:heroescompanion/features/factions/factions_data.dart';
import 'package:heroescompanion/features/factions/resource_counter_wheel.dart';

class ArmyBlockPanel extends StatelessWidget {
  final Faction faction;

  const ArmyBlockPanel({super.key, required this.faction});

  @override
  Widget build(BuildContext context) {
    // This panel now shows army unit slots based on the selected faction
    // Each unit slot has an image and two counters: total units and deployed units
    
    // Use army units data from the faction
    final List<String> armyUnits = faction.units ?? [];

    return Container(
      height: 106,
      // decoration: BoxDecoration(
      //   // color: Colors.grey[200],
      //   // borderRadius: BorderRadius.circular(8),
      // ),
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
                        // color: Colors.black54,
                        // height: 50,
                        child: ResourceCounterWheel(
                          resource: 'total_$unit',
                          initialValue: 0,
                          heightOfWheel: 50,
                          onValueChanged: (value) {
                            // Handle total units value change
                          },
                        ),
                      ),
                      // Deployed units counter
                      Container(
                        // color: Colors.redAccent,
                        // height: 50,
                        child: ResourceCounterWheel(
                            resource: 'deployed_$unit',
                            initialValue: 0,
                            heightOfWheel: 50,
                            onValueChanged: (value) {
                              // Handle deployed units value change
                            },
                          ),
                      ),
                    ],
                  ),
                ),
                // Positioned(
                //   top: 5,
                //   left: 5,
                //   child: ResourceCounterWheel(
                //     resource: 'total_$unit',
                //     initialValue: 0,
                //     onValueChanged: (value) {
                //       // Handle total units value change
                //     },
                //   ),
                // ),
                // Positioned(
                //   top: 5,
                //   right: 5,
                //   child: ResourceCounterWheel(
                //     resource: 'deployed_$unit',
                //     initialValue: 0,
                //     onValueChanged: (value) {
                //       // Handle deployed units value change
                //     },
                //   ),
                // ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}