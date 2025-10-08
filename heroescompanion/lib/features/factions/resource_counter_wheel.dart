import 'package:flutter/material.dart';

class ResourceCounterWheel extends StatefulWidget {
  final String resource;
  final int initialValue;
  final ValueChanged<int> onValueChanged;
  final double heightOfWheel;
  final double fontSize;

  const ResourceCounterWheel({
    super.key,
    required this.resource,
    required this.initialValue,
    required this.onValueChanged,
    this.heightOfWheel = 90,
    this.fontSize = 50,
  });

  @override
  _ResourceCounterWheelState createState() => _ResourceCounterWheelState();
}

class _ResourceCounterWheelState extends State<ResourceCounterWheel> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: 99 - widget.initialValue);
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
    if (newIndex >= 0 && newIndex <= 99) {
      widget.onValueChanged(99 - newIndex);
    }
  }

  @override
  Widget build(BuildContext context) {

    final List<String> resourcesAssets = [
          'assets/wood.PNG',
          'assets/iron.PNG',
          'assets/gold.PNG',
        ];
        String backImage = ''; // Empty by default

    if (widget.resource == 'Дерево'){
      backImage = resourcesAssets[0];
    } else if (widget.resource == 'Железо'){
      backImage = resourcesAssets[1];
    } else if (widget.resource == 'Золото'){
      backImage = resourcesAssets[2];
    }
    // For any other resource, backImage remains empty

    return Container(
      decoration: BoxDecoration(
        image: backImage.isNotEmpty ? DecorationImage(image: AssetImage(backImage), fit: BoxFit.cover, opacity: 0.5) : null,
        color: const Color.fromARGB(50, 226, 226, 226),
        borderRadius: BorderRadius.circular(8)
      ),
      child: SizedBox(
        height: widget.heightOfWheel,
        child: ListWheelScrollView.useDelegate(
          itemExtent: 75,
          physics: const FixedExtentScrollPhysics(),
          controller: _controller,
          diameterRatio: 2.5,
          childDelegate: ListWheelChildBuilderDelegate(
            builder: (context, index) {
              final displayIndex = 99 - index;
              if (displayIndex < 0 || displayIndex > 99) return const SizedBox();
              return Center(                
                child: Stack(
                  children: <Widget>[
                    // Stroked text as border.
                    Text(
                      '$displayIndex',
                      style: TextStyle(
                        fontSize: widget.fontSize,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 5
                          ..color = const Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    // Solid text as fill.
                    Text(
                      '$displayIndex',
                      style: TextStyle(
                        fontSize: widget.fontSize,
                        color: const Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                  ],
                )
              );                                      
            },
            childCount: 100,
          ),
        ),
      ),
    );
  }
}