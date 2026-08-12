# HeroesCompanion

Flutter-компаньон для настольной игры «Герои». Версия v1 (референс) зафиксирована на ветке `legacy/v1-reference`; разработка v2 ведётся на ветке `ver3`.

## Окружение разработки

На этой машине **нет установленного Flutter** — команды `flutter analyze`, `flutter test`, `flutter pub get`, `flutter build` здесь не запускаются. Код пишется и коммитится с этой машины, а сборка, анализ и тесты выполняются на отдельном компе с Flutter (рабочая папка `heroescompanion_v3`): там выполняется `git pull`, затем `flutter pub get && flutter analyze && flutter test` (коммитить на том компе только `android/`, `.metadata`, `pubspec.lock` — никаких `git add -A`).

## Agent skills

### Issue tracker

Issues and specs live as markdown files in `.scratch/<feature-slug>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Five canonical roles: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
