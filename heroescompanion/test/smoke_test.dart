import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heroescompanion/main.dart';

void main() {
  testWidgets('приложение открывается на главном меню', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HeroesCompanionApp()));

    expect(find.text('Главное меню'), findsOneWidget);
  });
}
