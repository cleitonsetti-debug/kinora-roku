#!/bin/sh
# Baixa a ultima release do Kinora e instala no seu Roku (Modo Desenvolvedor ativo).
# uso: sh tools/install.sh IP_DO_ROKU SENHA_DO_MODO_DESENVOLVEDOR
set -e
IP="$1"
PASS="$2"
if [ -z "$IP" ] || [ -z "$PASS" ]; then
    echo "uso: sh tools/install.sh IP_DO_ROKU SENHA_DO_MODO_DESENVOLVEDOR"
    exit 1
fi
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
URL="$(curl -s https://api.github.com/repos/cleitonsetti-debug/kinora-roku/releases | grep -o '"browser_download_url": *"[^"]*roku.zip"' | head -1 | cut -d'"' -f4)"
if [ -z "$URL" ]; then
    echo "Nao encontrei uma release com o zip do Roku."
    exit 1
fi
echo "Baixando $URL"
curl -sL -o "$TMP/kinora.zip" "$URL"
echo "Instalando em $IP"
curl --user "rokudev:$PASS" --digest -s -o /dev/null -w "HTTP %{http_code}\n" -F "mysubmit=Install" -F "archive=@$TMP/kinora.zip" "http://$IP/plugin_install"
echo "Pronto. Abra o canal Kinora no Roku."
