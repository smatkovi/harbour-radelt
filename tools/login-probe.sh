#!/bin/sh
# Sucht den Weg, auf dem die App an ihren Keks fw_login kommt.
#
#   sh tools/login-probe.sh
#
# Stand der Erkenntnis: die Schnittstelle weist ueber den Keks `fw_login`
# aus (nachgemessen am Original, doc/api.md §10.5). Der Name sagt
# "Fahrradwettbewerb-Login", und `POST https://dashboard.radelt.at/login`
# antwortet mit 419 -- das ist Laravels CSRF-Schutz, also eine Webroute mit
# Formular. Die Vermutung: die App meldet sich dort an, nicht ueber
# /api/v2/login, und benutzt danach den Keks.
#
# Dieses Skript geht genau das durch:
#   1. Anmeldeseite von dashboard.radelt.at holen (Sitzung + CSRF-Marke).
#   2. Dort anmelden wie ein Browser.
#   3. Nachsehen, welche Kekse zurueckkamen -- besonders fw_login.
#   4. Mit dem Keks die Schnittstelle fragen. 200 heisst: Weg gefunden.
#   5. Nur zur Vollstaendigkeit noch /api/v2/login mit denselben Daten.
#
# Das Passwort wird verdeckt eingelesen, steht in keiner Befehlszeile und
# wird nie ausgegeben. Von den Keksen werden nur Namen und Laengen gezeigt.
set -e

BASIS=${1:-https://dashboard.radelt.at}
KEKSE=$(mktemp /tmp/radelt-kekse.XXXXXX)
SEITE=$KEKSE.page
trap 'rm -f "$SEITE"' EXIT          # das Keksglas bleibt absichtlich liegen

printf 'E-Mail: '
read -r KENNUNG
printf 'Passwort (bleibt verdeckt): '
stty -echo 2>/dev/null || true
read -r GEHEIM
stty echo 2>/dev/null || true
printf '\n\n'

echo "=== 1. Anmeldeseite $BASIS/login ==="
curl -s -m 30 -c "$KEKSE" -o "$SEITE" "$BASIS/login"
TOKEN=$(sed -n 's/.*name="_token"[^>]*value="\([^"]*\)".*/\1/p' "$SEITE" | head -1)
[ -n "$TOKEN" ] || TOKEN=$(sed -n 's/.*<meta name="csrf-token" content="\([^"]*\)".*/\1/p' "$SEITE" | head -1)
printf '   CSRF-Marke: %d Zeichen\n' "${#TOKEN}"
printf '   Felder im Formular: '
grep -oE '<input[^>]*name="[^"]+"' "$SEITE" | sed -E 's/.*name="([^"]+)"/\1/' | tr '\n' ' '
printf '\n   Formularziel: '
grep -oE '<form[^>]*action="[^"]*"' "$SEITE" | head -2 | tr '\n' ' '
printf '\n\n'

echo "=== 2. Anmelden ==="
ERGEBNIS=$(curl -s -m 30 -b "$KEKSE" -c "$KEKSE" -o "$SEITE" -w '%{http_code} -> %{redirect_url}' \
    -X POST "$BASIS/login" \
    --data-urlencode "_token=$TOKEN" \
    --data-urlencode "email=$KENNUNG" \
    --data-urlencode "password=$GEHEIM" \
    --data-urlencode "remember=on")
printf '   %s\n\n' "$ERGEBNIS"

echo "=== 3. Kekse danach ==="
awk '!/^#/ && NF >= 7 { printf "   %-28s %d Zeichen\n", $6, length($7) }' "$KEKSE"
if grep -q fw_login "$KEKSE"; then
    echo '   -> fw_login ist da. Das ist der Weg.'
else
    echo '   -> kein fw_login.'
fi
printf '\n'

echo "=== 4. Schnittstelle mit diesen Keksen ==="
for pfad in person dashboard bikes; do
    printf '   %-10s ' "$pfad"
    curl -s -m 25 -b "$KEKSE" -H 'Accept: application/json' \
        "https://dashboard.radelt.at/api/v2/$pfad" | cut -c1-120
    printf '\n'
done
printf '\n'

echo "=== 5. Gegenprobe /api/v2/login ==="
KENNUNG=$KENNUNG GEHEIM=$GEHEIM python3 -c '
import json, os
print(json.dumps({"email": os.environ["KENNUNG"], "password": os.environ["GEHEIM"]}))' \
| curl -s -m 25 -X POST -H 'Content-Type: application/json' -H 'Accept: application/json' \
    --data-binary @- https://dashboard.radelt.at/api/v2/login | cut -c1-160
printf '\n\nDas Keksglas liegt in %s (nur fuer dich lesbar).\n' "$KEKSE"
chmod 600 "$KEKSE"
