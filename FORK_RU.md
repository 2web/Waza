# Waza: русская адаптация

Этот форк — [tw93/Waza](https://github.com/tw93/Waza) с поддержкой русского языка. Изменения сделаны так, чтобы обновления из upstream сливались почти без конфликтов: тексты навыков остаются английскими (модель понимает их одинаково хорошо), а русская часть добавлена отдельными файлами и короткими вставками.

## Что изменено

**Новые файлы** (в upstream их нет, конфликтов не бывает):

| Файл | Зачем |
|---|---|
| `skills/write/references/write-ru.md` | Справочник `/write` для русской прозы: канцелярит, кальки, ИИ-шаблоны, типографика (тире, «ёлочки», ё) |
| `rules/russian.md` | Необязательное постоянное правило против ИИ-шаблонов в русских ответах (аналог `rules/chinese.md`) |
| `tests/test_punctuation_ru.sh` | Тест русского режима проверки пунктуации |
| `scripts/sync-upstream.sh` | Слияние с upstream с пересборкой генерируемых файлов |
| `FORK_RU.md` | Этот файл |

**Точечные правки upstream-файлов** (здесь возможны конфликты):

| Файл | Правка |
|---|---|
| `skills/*/SKILL.md` | Русские фразы дописаны в **конец** строки `when_to_use` |
| `skills/write/SKILL.md` | `description` упоминает Russian; строка маршрутизации на `write-ru.md`; `ru` в команде проверки пунктуации; исключение для русского в правиле «No em-dash» |
| `skills/write/scripts/check_punctuation.py` | Режим `--lang ru` (функция `check_ru`), автоопределение кириллицы в `detect_lang`, `ru` в `choices` |

**Генерируемые файлы** (`plugins/waza/**`, `.claude-plugin/marketplace.json`, `.agents/plugins/marketplace.json`) руками не правятся: их пересобирает `python3 scripts/build_metadata.py`.

### Режим пунктуации `--lang ru`

В отличие от `zh`/`en`, тире не запрещено: в русском оно грамматически нужно. Проверяются:

- `ru-hyphen-as-dash` — дефис или короткое тире с пробелами между словами (« - » → « — »);
- `ru-dash-spacing` — тире без пробелов между словами (`Москва—столица`);
- `ru-straight-quotes` — прямые кавычки рядом с кириллицей (нужны «ёлочки»);
- `ru-space-before-punct` — пробел перед знаком препинания;
- `ru-fullwidth-punct` — китайские полноширинные знаки.

Короткое тире в диапазонах (`2020–2024`), тире в начале реплики, код и URL не трогаются. В режиме `auto` текст считается русским, когда кириллических букв больше, чем латинских.

## Установка из форка

Команды из `README.md` ставят **оригинал** (`tw93/Waza`). Чтобы поставить форк:

```bash
# Claude Code, плагином
/plugin marketplace add 2web/Waza
/plugin install waza@waza

# или через skills CLI
npx skills add 2web/Waza -a claude-code codex cursor -g -y
```

Правило `rules/russian.md` установщик `setup-rule.sh` не найдёт (он качает из `tw93/Waza`), поэтому копируем вручную:

```bash
mkdir -p ~/.claude/rules && cp rules/russian.md ~/.claude/rules/russian.md
```

Для Codex — добавить содержимое файла в `~/.codex/AGENTS.md`.

## Обновление из upstream

```bash
bash scripts/sync-upstream.sh          # слить upstream/main
# или конкретный релиз:
bash scripts/sync-upstream.sh v3.43.0
```

Скрипт:

1. проверяет, что рабочее дерево чистое, и подтягивает `upstream` (`https://github.com/tw93/Waza.git`);
2. делает `git merge --no-commit`;
3. конфликты в генерируемых файлах решает в пользу upstream (они всё равно пересобираются);
4. пересобирает `plugins/waza` и marketplace, приводит окончания строк к LF;
5. запускает `build_metadata.py --check`, `verify_skills.py`, `check_routing_drift.py` и русский тест.

Коммит остаётся за тобой: посмотри `git diff --cached` и закоммить.

### Если остались конфликты

Чаще всего это строка `when_to_use` в `SKILL.md`, когда upstream добавил свои триггеры. Решение: взять строку upstream и дописать в её конец русские фразы из нашей версии. Для `check_punctuation.py` — сохранить блоки с пометкой `Russian fork` и функцию `check_ru`. Потом:

```bash
git add <файлы>
bash scripts/sync-upstream.sh --after-merge
```

### Windows

Python в Windows по умолчанию читает файлы в cp1251 и пишет CRLF. Скрипт сам выставляет `PYTHONUTF8=1` и чистит CR. Если запускаешь проверки вручную, сначала выполни `export PYTHONUTF8=1`. Тест `tests/test_punctuation.sh` из upstream падает в Windows на последнем шаге (сохранение CRLF при `--fix`); это поведение upstream, к форку отношения не имеет.
