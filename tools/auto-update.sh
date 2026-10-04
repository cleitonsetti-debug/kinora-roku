#!/bin/sh
# Atualiza o Kinora no seu Roku sozinho quando sai uma versao nova no GitHub.
# O Roku nao atualiza apps instalados por fora (modo desenvolvedor), entao quem faz isso e o seu computador:
# ele consulta as releases, baixa o zip e instala pelo instalador do modo desenvolvedor.
#
# uso:
#   sh tools/auto-update.sh --setup           guarda o IP e a senha do modo desenvolvedor (so neste computador)
#   sh tools/auto-update.sh                   verifica e instala se houver versao nova
#   sh tools/auto-update.sh --force           reinstala a ultima release mesmo que ja esteja instalada
#   sh tools/auto-update.sh --install-timer   verifica sozinho a cada 30 min (systemd, sem precisar de root)
#   sh tools/auto-update.sh --remove-timer    desliga a verificacao automatica
#
# Precisa de: curl e python3. Nao instala nada enquanto um video estiver tocando no Roku.

REPO="cleitonsetti-debug/kinora-roku"
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kinora"
CONF="$CONF_DIR/auto-update.conf"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/kinora"
STATE="$STATE_DIR/installed"
SHARE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/kinora"
UNIT_DIR="$HOME/.config/systemd/user"

log() { printf '%s  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }

setup() {
    mkdir -p "$CONF_DIR"
    printf 'IP do Roku (Ajustes > Rede > Sobre): '
    read -r IP
    printf 'Senha do modo desenvolvedor (nao aparece na tela): '
    stty -echo 2>/dev/null
    read -r PASS
    stty echo 2>/dev/null
    printf '\n'
    if [ -z "$IP" ] || [ -z "$PASS" ]; then
        echo "IP e senha sao obrigatorios."
        exit 1
    fi
    umask 077
    printf 'ROKU_IP=%s\nROKU_PASS=%s\n' "$IP" "$PASS" > "$CONF"
    chmod 600 "$CONF"
    echo "Guardado em $CONF (somente voce consegue ler)."
}

install_timer() {
    mkdir -p "$SHARE_DIR" "$UNIT_DIR"
    cp "$0" "$SHARE_DIR/auto-update.sh"
    cat > "$UNIT_DIR/kinora-auto-update.service" <<UNIT
[Unit]
Description=Atualiza o Kinora no Roku quando sai versao nova

[Service]
Type=oneshot
ExecStart=/bin/sh $SHARE_DIR/auto-update.sh
UNIT
    cat > "$UNIT_DIR/kinora-auto-update.timer" <<UNIT
[Unit]
Description=Verifica versao nova do Kinora a cada 30 minutos

[Timer]
OnBootSec=2min
OnUnitActiveSec=30min

[Install]
WantedBy=timers.target
UNIT
    systemctl --user daemon-reload
    systemctl --user enable --now kinora-auto-update.timer
    echo "Ligado. Para ver o historico: journalctl --user -u kinora-auto-update.service"
}

remove_timer() {
    systemctl --user disable --now kinora-auto-update.timer 2>/dev/null
    rm -f "$UNIT_DIR/kinora-auto-update.service" "$UNIT_DIR/kinora-auto-update.timer"
    systemctl --user daemon-reload
    echo "Desligado."
}

case "$1" in
    --setup) setup; exit 0 ;;
    --install-timer) install_timer; exit 0 ;;
    --remove-timer) remove_timer; exit 0 ;;
    ""|--force) ;;
    *) echo "opcao desconhecida: $1"; exit 1 ;;
esac

if [ ! -f "$CONF" ]; then
    echo "Falta configurar. Rode antes: sh tools/auto-update.sh --setup"
    exit 1
fi
. "$CONF"
if [ -z "$ROKU_IP" ] || [ -z "$ROKU_PASS" ]; then
    echo "Configuracao incompleta em $CONF. Rode: sh tools/auto-update.sh --setup"
    exit 1
fi

# 1) qual e a release mais nova (a primeira que nao e rascunho e tem o zip do Roku)
INFO="$(curl -fsS --max-time 20 -H 'User-Agent: kinora-auto-update' "https://api.github.com/repos/$REPO/releases?per_page=5" | python3 -c '
import json, sys
try:
    for r in json.load(sys.stdin):
        if r.get("draft"):
            continue
        for a in r.get("assets", []):
            if a.get("name", "").endswith("-roku.zip"):
                print(r.get("tag_name", "") + " " + a.get("browser_download_url", ""))
                raise SystemExit
except SystemExit:
    pass
except Exception:
    pass
')"
TAG="${INFO%% *}"
URL="${INFO#* }"
if [ -z "$TAG" ] || [ -z "$URL" ] || [ "$TAG" = "$INFO" ]; then
    log "Nao consegui consultar as releases (sem internet ou sem release com o zip do Roku)."
    exit 0
fi

CUR=""
[ -f "$STATE" ] && CUR="$(cat "$STATE")"
if [ "$1" != "--force" ] && [ -n "$CUR" ]; then
    NEWEST="$(printf '%s\n%s\n' "$CUR" "$TAG" | sort -V | tail -1)"
    if [ "$CUR" = "$TAG" ] || [ "$NEWEST" != "$TAG" ]; then
        log "Ja esta atualizado ($CUR)."
        exit 0
    fi
fi

# 2) o Roku esta ligado e nao esta tocando video?
if ! curl -fsS --max-time 5 "http://$ROKU_IP:8060/query/device-info" >/dev/null 2>&1; then
    log "Roku nao respondeu em $ROKU_IP (desligado ou fora da rede). Tento de novo depois."
    exit 0
fi
if curl -fsS --max-time 5 "http://$ROKU_IP:8060/query/media-player" 2>/dev/null | grep -q 'state="play"'; then
    log "Tem um video tocando no Roku; vou instalar $TAG depois."
    exit 0
fi

# 3) baixa e confere o zip (o manifest precisa estar na raiz)
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
log "Baixando $TAG"
if ! curl -fsSL --max-time 180 -o "$TMP/kinora.zip" "$URL"; then
    log "Falha ao baixar o zip."
    exit 1
fi
if ! python3 -c '
import sys, zipfile
z = zipfile.ZipFile(sys.argv[1])
assert z.testzip() is None
assert "manifest" in z.namelist()
' "$TMP/kinora.zip" 2>/dev/null; then
    log "O zip baixado e invalido (sem manifest na raiz). Nada foi instalado."
    exit 1
fi

# 4) instala pelo instalador do modo desenvolvedor
log "Instalando $TAG em $ROKU_IP"
OUT="$(curl --digest -u "rokudev:$ROKU_PASS" -sS --max-time 180 -F "mysubmit=Install" -F "archive=@$TMP/kinora.zip" "http://$ROKU_IP/plugin_install" 2>&1)"
if printf '%s' "$OUT" | grep -qiE 'Install Success|Application Received|Identical'; then
    mkdir -p "$STATE_DIR"
    printf '%s' "$TAG" > "$STATE"
    log "Pronto: Kinora $TAG instalado no Roku."
    command -v notify-send >/dev/null 2>&1 && notify-send "Kinora" "Atualizado para $TAG no Roku"
else
    log "O Roku nao confirmou a instalacao (senha errada ou modo desenvolvedor desligado?)."
    exit 1
fi
