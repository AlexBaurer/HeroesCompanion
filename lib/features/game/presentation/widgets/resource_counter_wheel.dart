import 'package:flutter/material.dart';

/// Иконка ресурса по его имени (пути ассетов как в v1); для неизвестных
/// ресурсов — null (без иконки). Пользователь готовит изображения сам.
const resourceIconPaths = <String, String>{
  'Дерево': 'assets/wood.PNG',
  'Железо': 'assets/iron.PNG',
  'Золото': 'assets/gold.PNG',
  'Ярость': 'assets/fury.PNG',
};

/// Колёсико-счётчик значений 0–99 (как в v1): прокрутка выбирает число,
/// [value] — управляемое значение из сессии (внешний кламп отражается
/// сразу), [onValueChanged] уведомляет об изменениях.
class ResourceCounterWheel extends StatefulWidget {
  const ResourceCounterWheel({
    super.key,
    required this.value,
    required this.onValueChanged,
    this.iconPath,
    this.heightOfWheel = 90,
    this.fontSize = 50,
  });

  final int value;
  final ValueChanged<int> onValueChanged;

  /// Фоновая иконка ресурса (путь ассета) или null.
  final String? iconPath;
  final double heightOfWheel;
  final double fontSize;

  @override
  State<ResourceCounterWheel> createState() => _ResourceCounterWheelState();
}

class _ResourceCounterWheelState extends State<ResourceCounterWheel> {
  static const _maxValue = 99;

  late final FixedExtentScrollController _controller;

  int _indexFor(int value) => _maxValue - value;

  int _valueAt(int index) => _maxValue - index;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(
      initialItem: _indexFor(widget.value),
    );
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ResourceCounterWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shown = _valueAt(_controller.selectedItem);
    if (widget.value != oldWidget.value && widget.value != shown) {
      _controller.jumpToItem(_indexFor(widget.value));
    }
  }

  void _onScroll() {
    final value = _valueAt(_controller.selectedItem);
    if (value >= 0 && value <= _maxValue && value != widget.value) {
      widget.onValueChanged(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(50, 226, 226, 226),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (widget.iconPath != null)
            Positioned.fill(
              child: Image.asset(
                widget.iconPath!,
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(0.5),
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          SizedBox(
            height: widget.heightOfWheel,
            child: ListWheelScrollView.useDelegate(
              itemExtent: 75,
              physics: const FixedExtentScrollPhysics(),
              controller: _controller,
              diameterRatio: 2.5,
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (context, index) {
                  final displayIndex = _valueAt(index);
                  if (displayIndex < 0 || displayIndex > _maxValue) {
                    return const SizedBox.shrink();
                  }
                  return Center(
                    child: Stack(
                      children: [
                        Text(
                          '$displayIndex',
                          style: TextStyle(
                            fontSize: widget.fontSize,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 5
                              ..color = const Color.fromARGB(
                                255,
                                255,
                                255,
                                255,
                              ),
                          ),
                        ),
                        Text(
                          '$displayIndex',
                          style: TextStyle(
                            fontSize: widget.fontSize,
                            color: const Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount: _maxValue + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
