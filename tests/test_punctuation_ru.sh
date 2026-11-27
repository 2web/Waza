#!/usr/bin/env bash
# Russian fork: --lang ru rules of the /write punctuation gate.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

CHECKER="$ROOT/skills/write/scripts/check-punctuation.sh"
tmpdir=$(make_tmpdir)

expect_ok() {
  printf '%s\n' "$1" > "$tmpdir/in.md"
  bash "$CHECKER" --lang ru "$tmpdir/in.md" >"$tmpdir/out" || { echo "ru should pass: $1"; cat "$tmpdir/out"; exit 1; }
  grep -q 'punctuation: ok' "$tmpdir/out"
}

expect_kind() {
  printf '%s\n' "$2" > "$tmpdir/in.md"
  if bash "$CHECKER" --lang ru "$tmpdir/in.md" >"$tmpdir/out"; then
    echo "ru should flag $1: $2"; exit 1
  fi
  grep -q "$1" "$tmpdir/out" || { echo "expected $1 for: $2"; cat "$tmpdir/out"; exit 1; }
}

# Grammatical em dash, en dash in ranges, dialogue dash and «ёлочки» are legal.
expect_ok 'Москва — столица России, а в 2020–2024 годах всё было иначе.'
expect_ok '— Привет, — сказал он.'
expect_ok 'Он сказал «привет» и ушёл.'
expect_ok 'Положите ключ в файл .env и перезапустите.'
# Code, URLs and list markers are exempt.
expect_ok 'Команда `a - b "x"` и ссылка https://example.com/a-b.'
expect_ok '- пункт списка'

expect_kind 'ru-hyphen-as-dash' 'Это плохо - так нельзя.'
expect_kind 'ru-hyphen-as-dash' 'Это плохо – так нельзя.'
expect_kind 'ru-dash-spacing' 'Москва—столица.'
expect_kind 'ru-straight-quotes' 'Он сказал "привет" и ушёл.'
expect_kind 'ru-space-before-punct' 'Он ушёл , не попрощавшись.'
expect_kind 'ru-fullwidth-punct' 'Готово。'

# auto routes Cyrillic-dominant text to ru, and English with one Russian word stays en.
printf '%s\n' 'Москва—столица.' > "$tmpdir/auto.md"
if bash "$CHECKER" "$tmpdir/auto.md" >"$tmpdir/auto.out"; then
  echo "auto should route Cyrillic to ru"; exit 1
fi
grep -q 'ru-dash-spacing' "$tmpdir/auto.out"

printf '%s\n' 'The word привет means hello in this sentence.' > "$tmpdir/en.md"
bash "$CHECKER" "$tmpdir/en.md" >"$tmpdir/en.out"
grep -q 'punctuation: ok' "$tmpdir/en.out"

echo "ok: punctuation ru"
