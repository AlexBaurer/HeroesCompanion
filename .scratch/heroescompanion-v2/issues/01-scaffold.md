# 01 — Скаффолд проекта v2

**What to build:** Создание Flutter-проекта v2: `flutter create` с applicationId `com.example.heroescompanion` (тот же, что у установленной v1 — требуется для миграции, ADR-0002), подключение зависимостей (riverpod, go_router, shared_preferences, package_info_plus, flutter_lints), единая тема Material 3, каркас go_router со всеми экранами-заглушками (главное меню, выбор фракции, партия, ввод очков, история). Шаблонный код приложения удалён.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] Проект создаётся и собирается с applicationId `com.example.heroescompanion`
- [ ] `flutter pub get` проходит, зависимости подключены
- [ ] Приложение запускается и открывает главное меню-заглушку
- [ ] go_router определяет маршруты всех пяти экранов
- [ ] `flutter analyze` без ошибок
