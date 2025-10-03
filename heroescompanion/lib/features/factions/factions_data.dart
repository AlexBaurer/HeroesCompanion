import 'package:flutter/material.dart';

class Faction {
  final String name;
  final Color primaryColor;
  final List<String> resources; // названия ресурсов

  const Faction({
    required this.name,
    required this.primaryColor,
    required this.resources,
  });

  static const all = [
    Faction(
      name: 'Люди',
      primaryColor: Colors.blue,
      resources: ['Золото', 'Дерево', 'Железо'],
    ),
    Faction(
      name: 'Нежить',
      primaryColor: Colors.grey,
      resources: ['Золото', 'Дерево', 'Железо'],
    ),
    Faction(
      name: 'Гномы',
      primaryColor: Colors.brown,
      resources: ['Золото', 'Дерево', 'Железо'],
    ),
    Faction(
      name: 'Орки',
      primaryColor: Colors.green,
      resources: ['Золото', 'Дерево', 'Железо', 'Ярость'],
    ),
    Faction(
      name: 'Эльфы',
      primaryColor: Colors.teal,
      resources: ['Золото', 'Дерево', 'Железо'],
    ),
    Faction(
      name: 'Наги',
      primaryColor: Colors.cyan,
      resources: ['Золото', 'Дерево', 'Железо', 'Краки'],
    ),
    Faction(
      name: 'Гремлины',
      primaryColor: Colors.orange,
      resources: ['Золото', 'Дерево', 'Железо'],
    ),
    Faction(
      name: 'Механизмы',
      primaryColor: Colors.grey,
      resources: ['Золото', 'Дерево', 'Железо'],
    ),
    Faction(
      name: 'Элементали',
      primaryColor: Colors.red,
      resources: ['Золото', 'Дерево', 'Железо'],
    ),
    Faction(
      name: 'Демоны',
      primaryColor: Colors.deepPurple,
      resources: ['Золото', 'Дерево', 'Железо'],
    ),
    Faction(
      name: 'Полурослики',
      primaryColor: Colors.greenAccent,
      resources: ['Золото', 'Дерево', 'Железо'],
    ),
    Faction(
      name: 'Культисты',
      primaryColor: Colors.black,
      resources: ['Золото', 'Дерево', 'Железо'],
    ),
  ];

  static Faction? fromName(String name) {
    return all.firstWhere((f) => f.name == name);
  }
}