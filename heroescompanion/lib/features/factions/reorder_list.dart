// import 'package:flutter/material.dart';

// class ResourceOrderImageList extends StatefulWidget {
//   final List<String> imageAssets; // пути к картинкам (или URL)

//   const ResourceOrderImageList({
//     super.key,
//     required this.imageAssets,
//   });

//   @override
//   State<ResourceOrderImageList> createState() =>
//       _CustomReorderableImageListState();
// }

// class _CustomReorderableImageListState extends State<ResourceOrderImageList> {
//   late List<String> _items;

//   @override
//   void initState() {
//     super.initState();
//     _items = List<String>.from(widget.imageAssets);
//   }

//   // Без смены местами
//   void _onReorder(int oldIndex, int newIndex) {
//     setState(() {
//       final newIdx = newIndex > oldIndex ? newIndex - 1 : newIndex;
//       final item = _items.removeAt(oldIndex);
//       _items.insert(newIdx, item);
//     });
//   }

//   // Со сменой местами
//   // void _onReorder(int oldIndex, int newIndex) {
//   // setState(() {
//   //     // Adjust index if dragging downward
//   //     if (newIndex > oldIndex) {
//   //       newIndex -= 1;
//   //     }
      
//   //     // Swap the items instead of shifting
//   //     if (oldIndex != newIndex) {
//   //       final String item = _items[oldIndex];
//   //       _items[oldIndex] = _items[newIndex];
//   //       _items[newIndex] = item;
//   //     }
//   //   });
//   // }

//   @override
//   Widget build(BuildContext context) {
//     return ReorderableListView(
//       onReorder: _onReorder,
//       proxyDecorator: (Widget child, int index, Animation<double> animation) {
//         return AnimatedBuilder(
//           animation: animation,
//           builder: (BuildContext context, Widget? child) {
//             final animValue = Curves.easeInOut.transform(animation.value);
//             return Transform.scale(
//               scale: 1.0 + animValue * 0.05,
//               child: Container(
//                 decoration: BoxDecoration(
//                   boxShadow: [
//                     BoxShadow(
//                       color: const Color.fromARGB(255, 167, 218, 101).withOpacity(0.7),
//                       blurRadius: 16.0,
//                       spreadRadius: 0.5,
//                     ),
//                   ],
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: child,
//               ),
//             );
//           },
//           child: child,
//         );
//       },
//       children: [
//         for (int i = 0; i < _items.length; i++)
//           Card(
//             key: Key(_items[i]),
//             margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
//             borderOnForeground: false,
//             child: SizedBox(
//               height: 55,
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(12),
//                 child: Image.asset(
//                   _items[i],
//                   fit: BoxFit.cover,
//                   errorBuilder: (context, error, stackTrace) {
//                     return const Center(child: Text('Ошибка загрузки'));
//                   },
//                 ),
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';

class ResourceOrderImageList extends StatefulWidget {
  final List<String> imageAssets; // пути к картинкам (или URL)

  const ResourceOrderImageList({
    super.key,
    required this.imageAssets,
  });

  @override
  State<ResourceOrderImageList> createState() =>
      _CustomReorderableImageListState();
}

class _CustomReorderableImageListState extends State<ResourceOrderImageList> {
  late List<String> _items;

  @override
  void initState() {
    super.initState();
    _items = List<String>.from(widget.imageAssets);
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final newIdx = newIndex > oldIndex ? newIndex - 1 : newIndex;
      final item = _items.removeAt(oldIndex);
      _items.insert(newIdx, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ReorderableListView(
          onReorder: _onReorder,
          proxyDecorator: (Widget child, int index, Animation<double> animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (BuildContext context, Widget? child) {
                final animValue = Curves.easeInOut.transform(animation.value);
                return Transform.scale(
                  scale: 1.0 + animValue * 0.05,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(76, 175, 80, 1).withOpacity(0.7),
                          blurRadius: 8.0,
                          spreadRadius: 2.0,
                        ),
                      ],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: child,
                  ),
                );
              },
              child: child,
            );
          },
          children: [
            for (int i = 0; i < _items.length; i++)
              Card(
                key: Key(_items[i]), // уникальный ключ — обязателен!
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                borderOnForeground: false,
                child: SizedBox(
                  height: 55,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      _items[i],
                      fit: BoxFit.cover,                  
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Text('Ошибка загрузки'));
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
        // Fixed position numbers from 1 to 5
        for (int i = 0; i < 5; i++)
          Positioned(
            left: 20,
            top: 10.0 + i * 67.0, // Adjusted for item height and margins
            child: Text(
              '${i + 1}',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(255, 255, 255, 1),
                shadows: [
                  Shadow(
                    offset: Offset(0, 0),
                    blurRadius: 20,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}