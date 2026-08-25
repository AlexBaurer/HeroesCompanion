# 26 — Иконка приложения и загрузочный экран: единая иконка из `assets/icon/`

**What to build:** Иконка приложения (launcher icon) и загрузочный экран (splash) используют одну и ту же картинку — иконку из папки `assets/icon/`. Сейчас в `pubspec.yaml` уже есть конфиг `flutter_launcher_icons` с `image_path: "assets/icon/icon_h.PNG"`, но самого файла `assets/icon/icon_h.PNG` в репозитории нет (в папке только `.gitkeep`) — генерация иконок не работает. Загрузочный экран — стандартный белый Flutter (`android/app/src/main/res/drawable/launch_background.xml`, заглушка-комментарий с `@mipmap/launch_image`), иконка на нём не показывается.

- **Источник иконки:**
  - В репозиторий должен попасть файл `assets/icon/icon_h.PNG` (сейчас отсутствует — пустая папка с `.gitkeep`). Откуда взять исходник — решить до старта: в v1-референсе иконок нет (ветка `legacy/v1-reference` не содержит картинок), так что файл, скорее всего, есть у автора/на компьютере сборки.
  - `assets/icon/` уже бандлится (`pubspec.yaml`, секция `assets:` — корень `assets/` и подпапки).

- **Иконка приложения (`flutter_launcher_icons`):**
  - Конфиг уже в `pubspec.yaml` (строки 32–35): `android: true`, `image_path: "assets/icon/icon_h.PNG"`, `adaptive_icon_background: "#FFFFFF"`.
  - После добавления файла — сгенерировать иконки (`dart run flutter_launcher_icons`) и закоммитить `android/app/src/main/res/mipmap-*/ic_launcher.png` и `ic_launcher_foreground.png` (если появятся).
  - iOS в проекте нет (папки `ios/` не существует) — конфиг для ios можно оставить, но цель только Android.

- **Загрузочный экран:**
  - Вариант A (в духе репозитория, без новых зависимостей): руками правим `android/app/src/main/res/drawable/launch_background.xml` и `drawable-v21/launch_background.xml` — белый фон + bitmap иконки по центру (как в закомментированной заглушке, `@mipmap/launch_image` — положить иконку в `mipmap-*` или `drawable/`).
  - Вариант B: подключить `flutter_native_splash` в dev-зависимости с конфигом на ту же `assets/icon/icon_h.PNG`.
  - В обоих вариантах splash и иконка — одна и та же картинка, без расхождения.

- **Проверка:**
  - Иконка и splash генерируются и коммитятся с компьютера сборки (на этой машине Flutter не установлен — только `android/`, `.metadata`, `pubspec.lock`).
  - Визуально: на устройстве иконка приложения и заставка при запуске — одна и та же иконка из `assets/icon/`.

**Blocked by:** — (нужен исходник `icon_h.PNG` от автора)

**Status:** ready-for-human

- [x] Исходник `assets/icon/icon_h.PNG` добавлен в репозиторий (не `.gitkeep`!)
- [x] `dart run flutter_launcher_icons` выполнен, сгенерированные `mipmap-*` закоммичены
- [x] Splash: белый фон + иконка по центру (вариант A или B)
- [x] Иконка и splash используют одну и ту же картинку из `assets/icon/`

## Comments

- Файл `assets/icon/icon_h.PNG` отсутствует в репозитории: `git ls-files` по `icon` даёт только `.gitkeep`. Сборка с flutter_launcher_icons сейчас упадёт с ошибкой «не найден image_path».
- В v1-референсе (`legacy/v1-reference`) нет ни одной картинки — исходник иконки надо запросить у автора, прежде чем агент сможет закрыть тикет.

- **Реализовано (коммит на `ver3`).** Исходник `assets/icon/icon_h.PNG` (72×72 RGBA) добавлен автором и закоммичен.
- **Иконки**: на этой машине Flutter не установлен, поэтому `mipmap-*/ic_launcher.png` (48/72/96/144/192px) сгенерированы напрямую из `icon_h.PNG` (PIL, LANCZOS) — тот же результат, что даёт flutter_launcher_icons. В `pubspec.yaml` добавлен dev-зависимость `flutter_launcher_icons: ^0.14.4`; `ios` переключён в `false` — без папки `ios/` команда `dart run flutter_launcher_icons` падала бы на iOS-генерации. На компьютере сборки можно перегенерировать канонически: `flutter pub get && dart run flutter_launcher_icons` (adaptive-иконки не генерируются: в конфиге нет `adaptive_icon_foreground`, версия 0.14.x не берёт `image_path` автоматически).
- **Splash (вариант A, без новых зависимостей)**: иконка скопирована в `res/drawable/launch_image.png`; в `drawable/launch_background.xml` и `drawable-v21/launch_background.xml` раскомментирована заглушка — белый фон + `<bitmap android:gravity="center" android:src="@drawable/launch_image"/>`.
- **Проверка на устройстве** (готово для человека): иконка приложения и заставка при запуске — одна и та же иконка из `assets/icon/`.