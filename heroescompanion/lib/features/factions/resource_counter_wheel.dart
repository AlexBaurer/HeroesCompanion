import 'package:flutter/material.dart';

class ResourceCounterWheel extends StatefulWidget {
  final String resource;
  final int initialValue;
  final ValueChanged<int> onValueChanged;

  const ResourceCounterWheel({
    super.key,
    required this.resource,
    required this.initialValue,
    required this.onValueChanged,
  });

  @override
  _ResourceCounterWheelState createState() => _ResourceCounterWheelState();
}

class _ResourceCounterWheelState extends State<ResourceCounterWheel> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: widget.initialValue);
    // Слушаем изменения только после инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.addListener(_onScroll);
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    final newIndex = _controller.selectedItem;
    if (newIndex != null && newIndex >= 0 && newIndex <= 99) {
      widget.onValueChanged(newIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListWheelScrollView.useDelegate(
        itemExtent: 75,
        physics: const FixedExtentScrollPhysics(), // ← ВОТ КЛЮЧЕВАЯ СТРОКА
        controller: _controller,
        diameterRatio: 2.5,
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            if (index < 0 || index > 99) return const SizedBox();
            return Center(
              child: Text(
                '$index',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            );
          },
          childCount: 100,
        ),
      ),
    );
  }
}