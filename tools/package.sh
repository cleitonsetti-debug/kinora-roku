#!/bin/sh
# Gera o zip para instalar no Roku (o manifest fica na raiz do zip).
# uso: sh tools/package.sh [saida.zip]
set -e
OUT="${1:-kinora.zip}"
case "$OUT" in
    /*) ;;
    *) OUT="$(pwd)/$OUT" ;;
esac
cd "$(dirname "$0")/.."
rm -f "$OUT"
zip -qr "$OUT" . -x "README.md" "CHANGELOG.md" "CONTRIBUTING.md" ".gitignore" ".git/*" ".github/*" "tools/*" "docs/*" "*.zip"
echo "Gerado: $OUT"
