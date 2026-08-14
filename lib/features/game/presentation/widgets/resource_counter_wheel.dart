import 'package:flutter/material.dart';

/// Иконка ресурса по его имени (пути ассетов как в v1); для неизвестных
/// ресурсов — null (без иконки). Пользователь готовит изображения сам.
const resourceIconPaths = <String, String>{
  'Дерево': 'assets/wood.PNG',
  'Железо': 'assets/iron.PNG',
  'Золото': 'assets/gold.PNG',
  'Ярость': 'assets/fury.PNG',
};

/// Колёсико-счётчик значений 0–[maxValue] (по умолчанию 99, как в v1):
/// прокрутка выбирает число, [value] — управляемое значение из сессии
/// (внешний кламп отражается сразу), [onValueChanged] уведомляет
/// об изменениях. Значения выше [maxValue] в колёсике отсутствуют —
/// прокрутить за границу нельзя.
class ResourceCounterWheel extends StatefulWidget {
  const ResourceCounterWheel({
    super.key,
    required this.value,
    required this.onValueChanged,
    this.iconPath,
    this.heightOfWheel = 90,
    this.fontSize = 50,
    this.maxValue = 99,
  });

  final int value;
  final ValueChanged<int> onValueChanged;

  /// Фоновая иконка ресурса (путь ассета) или null.
  final String? iconPath;
  final double heightOfWheel;
  final double fontSize;

  /// Верхняя граница выбираемых значений; колёсико содержит ровно
  /// значения 0..[maxValue].
  final int maxValue;

  @override
  State<ResourceCounterWheel> createState() => _ResourceCounterWheelState();
}

class _ResourceCounterWheelState extends State<ResourceCounterWheel> {
  late final FixedExtentScrollController _controller;

  /// Перескок колёсика в [didUpdateWidget] идёт в фазе сборки, а уведомление
  /// о прокрутке синхронно вызовет [onValueChanged] — менять провайдер
  /// в этой фазе нельзя, поэтому уведомления на время перескока гасятся.
  bool _programmaticJump = false;

  int _indexFor(int value) => widget.maxValue - value;

  int _valueAt(int index) => widget.maxValue - index;

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
      _programmaticJump = true;
      _controller.jumpToItem(_indexFor(widget.value));
      _programmaticJump = false;
    }
  }

  void _onScroll() {
    if (_programmaticJump) return;
    final value = _valueAt(_controller.selectedItem);
    if (value >= 0 && value <= widget.maxValue && value != widget.value) {
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
                  if (displayIndex < 0 || displayIndex > widget.maxValue) {
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
                childCount: widget.maxValue + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
