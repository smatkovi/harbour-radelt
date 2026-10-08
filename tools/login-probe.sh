#!/bin/sh
# Sucht den Weg, auf dem sich das radelt.at-Konto an der App-Schnittstelle
# anmelden laesst.
#
#   sh tools/login-probe.sh [https://wien.radelt.at]
#
# Jedes Bundesland hat eine eigene Instanz mit eigener Benutzerdatenbank;
# die Anmeldung auf www.radelt.at leitet auf die richtige weiter. Der Host
# gehoert deshalb als Argument hierher.
#
# Vier Teile, jeder grenzt den naechsten ein:
#   1. Webformular (/dashboard/login, email + password + _token). Kommt eine
#      Weiterleitung, stimmen die Zugangsdaten.
#   2. Mit dieser Sitzung das Profil holen und den **Benutzernamen**
#      herausziehen -- das Webformular nimmt Mail oder Benutzername, die
#      Schnittstelle vielleicht nur letzteren.
#   3. Die Seiten nach einem Token durchsuchen, den die App brauchen koennte.
#   4. /api/v2/login mit allem, was wir jetzt haben: Mail und Benutzername,
#      Klartext und Hashes, dazu Basic-Auth im Kopf statt im Koerper.
#
# Das Passwort wird verdeckt eingelesen, steht in keiner Befehlszeile und
# wird nie ausgegeben; Hashes entstehen hier auf dem Geraet. Token in den
# Antworten werden unkenntlich gemacht.
set -e

BASIS=${1:-${BASIS:-https://wien.radelt.at}}
API=$BASIS/dashboard/api/v2
KEKSE=$(mktemp /tmp/radelt-kekse.XXXXXX)
SEITE=$KEKSE.page
trap 'rm -f "$KEKSE" "$SEITE" "$SEITE".*' EXIT

printf 'E-Mail oder Benutzername: '
read -r KENNUNG
printf 'Passwort (bleibt verdeckt): '
stty -echo 2>/dev/null || true
read -r GEHEIM
stty echo 2>/dev/null || true
printf '\n'
printf 'Gelesen: [%s], Passwort %d Zeichen, Server %s\n\n' "$KENNUNG" "${#GEHEIM}" "$BASIS"
export KENNUNG GEHEIM

kurz() {
    sed -E 's/("(api_)?token"[[:space:]]*:[[:space:]]*")[^"]+"/\1…"/g' | cut -c1-200
}

echo "=== 1. Webformular ==="
curl -s -m 30 -c "$KEKSE" -o "$SEITE" "$BASIS/dashboard/login"
TOKEN=$(sed -n 's/.*name="_token"[^>]*value="\([^"]*\)".*/\1/p' "$SEITE" | head -1)
[ -n "$TOKEN" ] || TOKEN=$(sed -n 's/.*<meta name="csrf-token" content="\([^"]*\)".*/\1/p' "$SEITE" | head -1)
ERGEBNIS=$(curl -s -m 30 -b "$KEKSE" -c "$KEKSE" -o "$SEITE" -w '%{http_code} -> %{redirect_url}' \
    -X POST "$BASIS/dashboard/login" \
    --data-urlencode "_token=$TOKEN" \
    --data-urlencode "email=$KENNUNG" \
    --data-urlencode "password=$GEHEIM")
printf '   Antwort: %s\n' "$ERGEBNIS"
case "$ERGEBNIS" in
    302*) echo '   -> angemeldet.' ;;
    *)    echo '   -> abgelehnt; die weiteren Teile sind dann wenig wert.' ;;
esac
printf '\n'

echo "=== 2. Benutzername aus dem Profil ==="
BENUTZER=""
for pfad in /dashboard/home /dashboard/profile /dashboard/account /dashboard/settings /dashboard/profil; do
    curl -s -m 30 -b "$KEKSE" -c "$KEKSE" -o "$SEITE.$$" -L "$BASIS$pfad" 2>/dev/null || continue
    [ -s "$SEITE.$$" ] || continue
    gefunden=$(sed -n 's/.*name="username"[^>]*value="\([^"]*\)".*/\1/p' "$SEITE.$$" | head -1)
    [ -n "$gefunden" ] || gefunden=$(sed -n 's/.*id="username"[^>]*value="\([^"]*\)".*/\1/p' "$SEITE.$$" | head -1)
    if [ -n "$gefunden" ]; then
        BENUTZER=$gefunden
        printf '   %s -> Benutzername [%s]\n' "$pfad" "$BENUTZER"
        break
    fi
    printf '   %s: kein Benutzernamensfeld (%s Byte)\n' "$pfad" "$(wc -c < "$SEITE.$$")"
done
[ -n "$BENUTZER" ] || echo '   Keinen Benutzernamen gefunden -- bitte im Web-Dashboard unter Profil nachsehen.'
printf '\n'

echo "=== 3. Token auf den Seiten? ==="
grep -ohE '(api_?[Tt]oken|auth_?[Tt]oken|access_?[Tt]oken)["'"'"']?\s*[:=]\s*["'"'"'][^"'"'"']{10,}' "$SEITE.$$" 2>/dev/null \
    | sed -E 's/(["'"'"'])[^"'"'"']{10,}$/\1…/' | sort -u | head -5 || true
echo '   (leer = nichts gefunden)'
printf '\n'

echo "=== 4. Anmeldung an der Schnittstelle ==="
versuch() {
    printf '   %-40s ' "$1"
    antwort=$(printf '%s' "$2" | curl -s -m 30 -X POST \
        -H 'Content-Type: application/json' -H 'Accept: application/json' \
        --data-binary @- "$API/login" || echo '{"error":"keine Antwort"}')
    echo "$antwort" | kurz
    printf '\n'
    case "$antwort" in
        *'"success":true'*) printf '\n>>> Diese Variante geht: %s\n' "$1"; exit 0 ;;
    esac
    sleep 1
}

koerper() {   # $1 Feldname, $2 Wert, $3 Passwortform
    RADELT_FELD=$1 RADELT_WERT=$2 RADELT_FORM=$3 python3 -c '
import hashlib, json, os
geheim = os.environ["GEHEIM"]
form = os.environ["RADELT_FORM"]
if form != "klartext":
    geheim = hashlib.new(form, geheim.encode()).hexdigest()
print(json.dumps({os.environ["RADELT_FELD"]: os.environ["RADELT_WERT"], "password": geheim}))'
}

if [ -n "$BENUTZER" ]; then
    for feld in username email login; do
        versuch "$feld = Benutzername" "$(koerper $feld "$BENUTZER" klartext)"
    done
    versuch "username = Benutzername, sha256" "$(koerper username "$BENUTZER" sha256)"
fi

versuch "email = Mail (Gegenprobe)" "$(koerper email "$KENNUNG" klartext)"

# Basic-Auth im Kopf statt im Koerper: im Binaer steht "Basic " --
# vielleicht liest der Server die Zugangsdaten von dort.
BASIC=$(printf '%s' "$KENNUNG:$GEHEIM" | base64 -w0 2>/dev/null || printf '%s' "$KENNUNG:$GEHEIM" | base64 | tr -d '\n')
printf '   %-40s ' "Basic-Auth mit Mail"
curl -s -m 30 -X POST -H 'Accept: application/json' -H "Authorization: Basic $BASIC" \
    -H 'Content-Type: application/json' -d '{}' "$API/login" | kurz
printf '\n'

if [ -n "$BENUTZER" ]; then
    BASICU=$(printf '%s' "$BENUTZER:$GEHEIM" | base64 -w0 2>/dev/null || printf '%s' "$BENUTZER:$GEHEIM" | base64 | tr -d '\n')
    printf '   %-40s ' "Basic-Auth mit Benutzername"
    curl -s -m 30 -X POST -H 'Accept: application/json' -H "Authorization: Basic $BASICU" \
        -H 'Content-Type: application/json' -d '{}' "$API/login" | kurz
    printf '\n'
fi

printf '\nKeine Variante hat success:true geliefert.\n'
