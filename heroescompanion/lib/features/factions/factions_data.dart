import 'package:flutter/material.dart';

class Faction {
  final String name;
  final Color primaryColor;
  final List<String> resources;
  final List<String> units;
  final List<String> unitsAssets;

  const Faction({
    required this.name,
    required this.primaryColor,
    required this.resources,
    required this.units,
    required this.unitsAssets,
    });

  static const all = [
    Faction(
      name: 'Люди',
      primaryColor: Color.fromARGB(255, 190, 87, 55),
      resources: ['Золото', 'Дерево', 'Железо'],
      units: ['Солдат', 'Латник', 'Архимаг'],
      unitsAssets: ['assets/units/soldier.PNG', 'assets/units/latnik.PNG', 'assets/units/archimage.PNG'],
    ),
    Faction(
      name: 'Нежить',
      primaryColor: Color.fromARGB(255, 8, 138, 170),
      resources: ['Золото', 'Дерево', 'Железо'],
      units: ['Скелет', 'Палач', 'Лич'],
      unitsAssets: ['assets/units/skeleton.PNG', 'assets/units/paladin.PNG', 'assets/units/lich.PNG'],
    ),
    Faction(
      name: 'Гномы',
      primaryColor: Color.fromARGB(255, 100, 100, 100),
      resources: ['Золото', 'Дерево', 'Железо'],
      units: ['Механик', 'Стреколёт', 'Автоматон', 'Мехозавр'],
      unitsAssets: ['assets/units/mechanic.PNG', 'assets/units/skarlat.PNG', 'assets/units/automaton.PNG', 'assets/units/mechazavr.PNG'],
    ),
    Faction(
      name: 'Орки',
      primaryColor: Color.fromARGB(255, 219, 173, 19),
      resources: ['Золото', 'Дерево', 'Железо', 'Ярость'],
      units: ['Разведчик', 'Громила', 'Взрыватель'],
      unitsAssets: ['assets/units/explorer.PNG', 'assets/units/grom.PNG', 'assets/units/vzryvatel.PNG'],
    ),
    Faction(
      name: 'Эльфы',
      primaryColor: Color.fromARGB(255, 115, 46, 180),
      resources: ['Золото', 'Дерево', 'Железо'],
      units: ['Пикси', 'Грифон', 'Энт'],
      unitsAssets: ['assets/units/pixi.PNG', 'assets/units/grifon.PNG', 'assets/units/ent.PNG'],
    ),
    Faction(
      name: 'Наги',
      primaryColor: Color.fromARGB(255, 0, 198, 212),
      resources: ['Золото', 'Дерево', 'Железо'],
      units: ['Краки'],
      unitsAssets: ['assets/units/kraki.PNG'],
    ),
    Faction(
      name: 'Гремлины',
      primaryColor: Color.fromARGB(255, 199, 83, 147),
      resources: ['Золото', 'Дерево', 'Железо'],
      units: ['Вышибала', 'Наливала', 'Летала'],
      unitsAssets: ['assets/units/vyshivabla.PNG', 'assets/units/nalivala.PNG', 'assets/units/letala.PNG'],
    ),
    Faction(
      name: 'Механизмы',
      primaryColor: Color.fromARGB(255, 145, 182, 77),
      resources: ['Золото', 'Дерево'],
      units: ['Ядро', 'Крушитель', 'Колосс'],
      unitsAssets: ['assets/units/yadro.PNG', 'assets/units/krushitel.PNG', 'assets/units/koloss.PNG'],
    ),
    Faction(
      name: 'Элементали',
      primaryColor: Colors.red,
      resources: ['Золото', 'Дерево', 'Железо'],
      units: ['Зефира', 'Тур', 'Джазир', 'Майя'],
      unitsAssets: ['assets/units/zefira.PNG', 'assets/units/tur.PNG', 'assets/units/dzazir.PNG', 'assets/units/maya.PNG'],
    ),
    Faction(
      name: 'Демоны',
      primaryColor: Color.fromARGB(255, 76, 47, 124),
      resources: ['Золото', 'Дерево', 'Железо'],
      units: ['Бес', 'Суккуб', 'Мясник'],
      unitsAssets: ['assets/units/bes.PNG', 'assets/units/sukkub.PNG', 'assets/units/myasnik.PNG'],
    ),
    Faction(
      name: 'Полурослики',
      primaryColor: Color.fromARGB(255, 221, 121, 6),
      resources: ['Золото', 'Дерево', 'Железо'],
      units: ['Гладиатор', 'Легионер'],
      unitsAssets: ['assets/units/gladiator.PNG', 'assets/units/legioner.PNG'],
    ),
    Faction(
      name: 'Культисты',
      primaryColor: Color.fromARGB(255, 88, 63, 43),
      resources: ['Золото', 'Дерево', 'Железо'],
      units: ['Проповедник', 'Паломник'],
      unitsAssets: ['assets/units/propovednik.PNG', 'assets/units/palomnik.PNG'],
    ),
  ];

  static Faction? fromName(String name) {
    return all.firstWhere((f) => f.name == name);
  }
}