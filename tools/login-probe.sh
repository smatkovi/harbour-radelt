#!/bin/sh
# Letzter offener Verdacht zur Anmeldung an der App-Schnittstelle.
#
#   sh tools/login-probe.sh
#
# Was wir wissen (doc/api.md §10): die Schnittstelle weist über den Keks
# `fw_login` aus, das Webformular auf dashboard.radelt.at nimmt dasselbe
# Konto an (302), /api/v2/login lehnt es ab. Alle bisherigen Versuche gingen
# **ohne jeden Keks** hinaus -- die Original-App dagegen führt ein Keksglas
# (cookie_jar + dio_cookie_manager) und holt sich vor der Anmeldung eine
# Sitzung. Genau das wird hier nachgestellt:
#
#   1. GET auf eine Schnittstellen-Route -> Sitzungskeks einsammeln.
#   2. POST /api/v2/login **mit** diesem Keks.
#   3. Dasselbe noch einmal mit den Kopfzeilen, die dio von sich aus
#      schickt (Useragent Dart, gzip) -- auch das war nie geprüft.
#   4. Und mit den Zugangsdaten als Abfrageparameter statt im Körper.
#
# Das Passwort wird verdeckt eingelesen, steht in keiner Befehlszeile und
# wird nie ausgegeben.
set -e

API=${1:-https://dashboard.radelt.at/api/v2}
GLAS=$(mktemp /tmp/radelt-glas.XXXXXX)
trap 'rm -f "$GLAS"' EXIT

printf 'E-Mail: '
read -r KENNUNG
printf 'Passwort (bleibt verdeckt): '
stty -echo 2>/dev/null || true
read -r GEHEIM
stty echo 2>/dev/null || true
printf '\n\n'
export KENNUNG GEHEIM

kurz() { cut -c1-170; }

koerper() {
    python3 -c 'import json,os; print(json.dumps({"email":os.environ["KENNUNG"],"password":os.environ["GEHEIM"]}))'
}

echo "=== 1. Sitzung bei der Schnittstelle holen ==="
# Über eine oeffentliche Route: geschuetzte geben 401 und setzen keinen
# Keks. validatepostcode ist folgenlos (forgotpassword wuerde Post schicken).
curl -s -m 25 -c "$GLAS" -o /dev/null -w "   GET /validatepostcode: HTTP %{http_code}\n" \
    -H 'Accept: application/json' "$API/validatepostcode?postcode=1220&country=AT"
# Auch HttpOnly-Kekse zeigen: die stehen mit '#HttpOnly_' am Zeilenanfang,
# ein naives grep -v '^#' wirft genau sie weg.
awk 'NF>=7 {printf "   Keks: %-28s %d Zeichen\n", $6, length($7)}' "$GLAS"
printf '\n'

versuch() {
    printf '   %-38s ' "$1"
    shift
    antwort=$(koerper | curl -s -m 25 -X POST --data-binary @- "$@" "$API/login" \
              || echo '{"error":"keine Antwort"}')
    echo "$antwort" | kurz
    printf '\n'
    case "$antwort" in
        *'"success":true'*) printf '\n>>> GEHT\n'; exit 0 ;;
    esac
    sleep 1
}

echo "=== 2. Anmelden mit dieser Sitzung ==="
versuch "mit Sitzungskeks" -b "$GLAS" -c "$GLAS" \
    -H 'Content-Type: application/json' -H 'Accept: application/json'

echo "=== 3. Dazu die Kopfzeilen, die dio schickt ==="
versuch "Keks + Dart-Useragent + gzip" -b "$GLAS" -c "$GLAS" \
    -H 'Content-Type: application/json' -H 'Accept: application/json' \
    -H 'User-Agent: Dart/3.5 (dart:io)' -H 'Accept-Encoding: gzip'

echo "=== 4. Zugangsdaten als Abfrageparameter ==="
printf '   %-38s ' "als Query, leerer Koerper"
curl -s -m 25 -X POST -b "$GLAS" -H 'Accept: application/json' \
    -H 'Content-Type: application/json' -d '{}' \
    --get --data-urlencode "email=$KENNUNG" --data-urlencode "password=$GEHEIM" \
    "$API/login" 2>/dev/null | kurz
printf '\n'

printf '\nKeine Variante hat success:true geliefert.\n'
