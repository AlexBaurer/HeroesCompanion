import 'package:flutter/material.dart';

class Faction {
  final String name;
  final String backgroundPicture;
  final Color primaryColor;
  final List<String> resources;
  final List<String> units;
  final List<String> unitsAssets;
  final List<String> unitsPower;

  const Faction({
    required this.name,
    required this.backgroundPicture,
    required this.primaryColor,
    required this.resources,
    required this.units,
    required this.unitsAssets,
    required this.unitsPower,
    });

  static const all = [
    Faction(
      name: 'Люди',
      backgroundPicture: 'assets/faction_background/humans.PNG',
      primaryColor: Color.fromARGB(255, 190, 87, 55),
      resources: ['Дерево', 'Железо', 'Золото'],
      units: ['Солдат', 'Латник', 'Архимаг'],
      unitsAssets: ['assets/units/soldier.PNG', 'assets/units/latnik.PNG', 'assets/units/archimage.PNG'],
      unitsPower: ['2', '3', '5'],
    ),
    Faction(
      name: 'Нежить',
      backgroundPicture: 'assets/faction_background/necros.PNG',
      primaryColor: Color.fromARGB(255, 8, 138, 170),
      resources: ['Дерево', 'Железо', 'Золото'],
      units: ['Скелет', 'Палач', 'Лич'],
      unitsAssets: ['assets/units/skeleton.PNG', 'assets/units/paladin.PNG', 'assets/units/lich.PNG'],
      unitsPower: ['1', '0', '5'],
    ),
    Faction(
      name: 'Гномы',
      backgroundPicture: 'assets/faction_background/gnomes.PNG',
      primaryColor: Color.fromARGB(255, 100, 100, 100),
      resources: ['Дерево', 'Железо', 'Золото'],
      units: ['Механик', 'Стреколёт', 'Автоматон', 'Мехозавр'],
      unitsAssets: ['assets/units/mechanic.PNG', 'assets/units/skarlat.PNG', 'assets/units/automaton.PNG', 'assets/units/mechazavr.PNG'],
      unitsPower: ['0', '2', '4', '5'],
    ),
    Faction(
      name: 'Орки',
      backgroundPicture: 'assets/faction_background/orcs.PNG',
      primaryColor: Color.fromARGB(255, 219, 173, 19),
      resources: ['Дерево', 'Железо', 'Золото', 'Ярость'],
      units: ['Разведчик', 'Громила', 'Взрыватель'],
      unitsAssets: ['assets/units/explorer.PNG', 'assets/units/grom.PNG', 'assets/units/vzryvatel.PNG'],
      unitsPower: ['2', '5', '9'],
    ),
    Faction(
      name: 'Эльфы',
      backgroundPicture: 'assets/faction_background/elfs.PNG',
      primaryColor: Color.fromARGB(255, 115, 46, 180),
      resources: ['Дерево', 'Железо', 'Золото'],
      units: ['Пикси', 'Грифон', 'Энт'],
      unitsAssets: ['assets/units/pixi.PNG', 'assets/units/grifon.PNG', 'assets/units/ent.PNG'],
      unitsPower: ['1', '3', '6'],
    ),
    Faction(
      name: 'Наги',
      backgroundPicture: 'assets/faction_background/nags.PNG',
      primaryColor: Color.fromARGB(255, 0, 198, 212),
      resources: ['Дерево', 'Железо', 'Золото'],
      units: ['Краки'],
      unitsAssets: ['assets/units/kraki.PNG'],
      unitsPower: ['1'],
    ),
    Faction(
      name: 'Гремлины',
      backgroundPicture: 'assets/faction_background/gremlins.PNG',
      primaryColor: Color.fromARGB(255, 199, 83, 147),
      resources: ['Дерево', 'Железо', 'Золото'],
      units: ['Вышибала', 'Наливала', 'Летала'],
      unitsAssets: ['assets/units/vyshivabla.PNG', 'assets/units/nalivala.PNG', 'assets/units/letala.PNG'],
      unitsPower: ['1', '4', '9'],
    ),
    Faction(
      name: 'Механизмы',
      backgroundPicture: 'assets/faction_background/mechanisms.PNG',
      primaryColor: Color.fromARGB(255, 145, 182, 77),
      resources: ['Дерево', 'Золото'],
      units: ['Ядро', 'Крушитель', 'Колосс'],
      unitsAssets: ['assets/units/yadro.PNG', 'assets/units/krushitel.PNG', 'assets/units/koloss.PNG'],
      unitsPower: ['1', '4', '0'],
    ),
    Faction(
      name: 'Элементали',
      backgroundPicture: 'assets/faction_background/elementals.PNG',
      primaryColor: Colors.red,
      resources: ['Дерево', 'Железо', 'Золото'],
      units: ['Зефира', 'Тур', 'Джазир', 'Майя'],
      unitsAssets: ['assets/units/zefira.PNG', 'assets/units/tur.PNG', 'assets/units/dzazir.PNG', 'assets/units/maya.PNG'],
      unitsPower: ['2', '1', '0', '7'],
    ),
    Faction(
      name: 'Демоны',
      backgroundPicture: 'assets/faction_background/demons.PNG',
      primaryColor: Color.fromARGB(255, 76, 47, 124),
      resources: ['Дерево', 'Железо', 'Золото'],
      units: ['Бес', 'Суккуб', 'Мясник'],
      unitsAssets: ['assets/units/bes.PNG', 'assets/units/sukkub.PNG', 'assets/units/myasnik.PNG'],
      unitsPower: ['1', '4', '7'],
    ),
    Faction(
      name: 'Полурослики',
      backgroundPicture: 'assets/faction_background/halflings.PNG',
      primaryColor: Color.fromARGB(255, 221, 121, 6),
      resources: ['Дерево', 'Железо', 'Золото'],
      units: ['Гладиатор', 'Легионер'],
      unitsAssets: ['assets/units/gladiator.PNG', 'assets/units/legioner.PNG'],
      unitsPower: ['3', '6'],
    ),
    Faction(
      name: 'Культисты',
      backgroundPicture: 'assets/faction_background/cultists.PNG',
      primaryColor: Color.fromARGB(255, 88, 63, 43),
      resources: ['Дерево', 'Железо', 'Золото'],
      units: ['Проповедник', 'Паломник'],
      unitsAssets: ['assets/units/propovednik.PNG', 'assets/units/palomnik.PNG'],
      unitsPower: ['3', '0'],
    ),
  ];

  static Faction? fromName(String name) {
    return all.firstWhere((f) => f.name == name);
  }
}