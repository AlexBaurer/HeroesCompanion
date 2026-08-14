/// Строка записи в формате v1 (ADR-0002) — ровно так писала её v1
/// (ключ `score_records`): дата ISO-8601 и playerScores. Общий фикстур
/// для тестов миграции (тикет 10).
const v1RecordSource =
    '{"dateTime":"2026-08-12T18:30:00.000","playerScores":'
    '[{"playerName":"Иван","score":42,"faction":"Майя"},'
    '{"playerName":"Пётр","score":35,"faction":"Наги"}]}';
