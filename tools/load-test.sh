#!/usr/bin/env bash
# Lint e teste de carga da biblioteca inteira com o PHP indicado.
#
#   PHP=php8.4 tools/load-test.sh
#
# 1. php -l em todos os arquivos: qualquer saida alem de "No syntax errors"
#    (erro, warning ou deprecation de compilacao) falha.
# 2. Cada arquivo e carregado num processo isolado (tools/load-test.php):
#    qualquer fatal, warning, notice ou deprecation que nao esteja em
#    tools/load-test-baseline.txt falha.
#
# Variaveis: PHP (padrao: php), JOBS (padrao: numero de CPUs),
# BASELINE (padrao: tools/load-test-baseline.txt).
set -u

ROOT=$(cd "$(dirname "$0")/.." && pwd)
LIB=$ROOT/zendframework1/library
PHP=${PHP:-php}
export PHP LIB ROOT

# modos internos, chamados pelo xargs para cada arquivo
case "${1:-}" in
  --lint-one)
    "$PHP" -d display_errors=stderr -d log_errors=0 -d error_reporting=-1 -l "$2" \
      > "$OUT/$(echo "$2" | tr / _).out" 2>&1
    exit 0 ;;
  --load-one)
    "$PHP" -d display_errors=stdout -d html_errors=0 -d log_errors=0 -d error_reporting=-1 \
      -d memory_limit=512M "$ROOT/tools/load-test.php" "$LIB" "$LIB/$2" \
      > "$OUT/$(echo "$2" | tr / _).out" 2>&1
    exit 0 ;;
esac

BASELINE=${BASELINE:-$ROOT/tools/load-test-baseline.txt}
JOBS=${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
SELF="$ROOT/tools/load-test.sh"

echo "PHP $("$PHP" -r 'echo PHP_VERSION;')"
cd "$LIB" || exit 2
find Zend -name '*.php' | LC_ALL=C sort > "$TMP/files.lst"
echo "arquivos: $(wc -l < "$TMP/files.lst" | tr -d ' ')"

# junta as saidas, tira o caminho absoluto da library e linhas vazias
collect() {
  cat "$1"/*.out | sed "s#$LIB/##g" | grep -v '^[[:space:]]*$' | LC_ALL=C sort -u
}

# 1. lint
mkdir -p "$TMP/lint"
OUT="$TMP/lint" xargs -n1 -P"$JOBS" "$SELF" --lint-one < "$TMP/files.lst"
collect "$TMP/lint" | grep -vE '^No syntax errors detected in |^Errors parsing ' > "$TMP/lint.txt"
LINT=$(wc -l < "$TMP/lint.txt" | tr -d ' ')
echo "lint: $LINT linha(s) de erro/aviso"
[ "$LINT" -eq 0 ] || sed 's/^/  /' "$TMP/lint.txt"

# 2. carga
mkdir -p "$TMP/load"
OUT="$TMP/load" xargs -n1 -P"$JOBS" "$SELF" --load-one < "$TMP/files.lst"
# normaliza: sem numero de linha, aspas simples viram duplas (mensagens do 7.4 x 8.x)
collect "$TMP/load" | sed -E "s/'/\"/g; s/(\.php):[0-9]+/\1/g; s/ on line [0-9]+//g; s/^PHP //" \
  | LC_ALL=C sort -u > "$TMP/load.txt"
grep -v -e '^#' -e '^[[:space:]]*$' "$BASELINE" > "$TMP/baseline.txt"
grep -v -F -f "$TMP/baseline.txt" "$TMP/load.txt" > "$TMP/load-new.txt"
KNOWN=$(( $(wc -l < "$TMP/load.txt") - $(wc -l < "$TMP/load-new.txt") ))
NEW=$(wc -l < "$TMP/load-new.txt" | tr -d ' ')
echo "carga: $KNOWN linha(s) conhecida(s) da baseline, $NEW nova(s)"
[ "$NEW" -eq 0 ] || sed 's/^/  /' "$TMP/load-new.txt"

# baseline sem uso nesta versao do PHP (so informa)
while IFS= read -r pat; do
  grep -q -F -- "$pat" "$TMP/load.txt" || echo "aviso: baseline sem ocorrencia: $pat"
done < "$TMP/baseline.txt"

if [ "$LINT" -ne 0 ] || [ "$NEW" -ne 0 ]; then
  echo "FALHOU"
  exit 1
fi
echo "OK"
