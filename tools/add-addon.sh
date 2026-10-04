#!/bin/sh
# Envia a URL de um addon (manifest) para o Kinora instalado no Roku.
# A TV mostra um aviso pedindo para confirmar antes de adicionar.
# uso: sh tools/add-addon.sh IP_DO_ROKU URL_DO_MANIFEST
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "uso: sh tools/add-addon.sh IP_DO_ROKU URL_DO_MANIFEST"
    exit 1
fi
curl -s -G -X POST --data-urlencode "addon=$2" "http://$1:8060/launch/dev" && echo "Enviado. Confirme na TV."
