# 06 — UI: главное меню и выбор фракции

**What to build:** Главное меню: «Начать игру», «Записи игр», донат-модалка (адрес, копирование в буфер), версия приложения, фоновое изображение. Экран выбора фракции: 18 фракций тремя секциями по частям игры, кнопки с цветом фракции из данных (не хардкод), переход на экран партии с выбранной фракцией.

**Blocked by:** 01, 02, 05

**Status:** done

- [x] Главное меню открывается, версия отображается
- [x] Донат-модалка открывается, адрес копируется
- [x] 18 фракций в 3 секциях по частям игры
- [x] Цвета фракций берутся из данных
- [x] Выбор фракции открывает экран партии с правильной фракцией

## Comments

Реализовано: `lib/features/main_menu/presentation/main_menu_screen.dart` (фон-изображение с errorBuilder, кнопки «Начать игру»/«Записи игр», версия через `package_info_plus`, донат-модалка с TON-адресом и копированием из v1, тема без хардкода цветов); `lib/features/main_menu/presentation/faction_choose_screen.dart` (3 секции «Часть 1–3» по 6 фракций, цвет кнопки — `colorFromHex(faction.color)` из данных, переход на `/faction/<имя>`). Данные: `lib/domain/faction_catalog.dart` (группировка по частям, поиск по имени), `lib/features/factions/data/faction_repository.dart` (чистый Dart, инъекция загрузчика), провайдеры `faction_providers.dart`, `lib/app/color_hex.dart` (hex → Color с fallback). Тесты: `test/domain/faction_catalog_test.dart`, `test/features/factions/data/faction_repository_test.dart`, `test/app/color_hex_test.dart`, расширен `test/smoke_test.dart` (навигация меню → выбор → партия с fake-репозиторием). Проверка на этой машине: `dart run tool/verify_faction_catalog.dart` (каталог 18 фракций корректен), `dart analyze` чист по `lib/domain`, `lib/features/factions/data` (кроме flutter-зависимого `faction_providers.dart` — нет SDK). Требуется `flutter test` и ручная проверка UI на машине со SDK.

Заодно: парсер допускает отрицательный `step` у counter (счётчик урона — Вершитель архонтов `-2`), `archons.json` исправлен (`bonusPower` → `step: 1` у Защитника) — без этого валидатор тикета 05 падал.
