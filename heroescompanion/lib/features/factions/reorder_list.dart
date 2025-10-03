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
    return ReorderableListView(
      onReorder: _onReorder,
      children: [
        for (int i = 0; i < _items.length; i++)
          Card(
            key: Key(_items[i]), // уникальный ключ — обязателен!
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
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
    );
  }
}