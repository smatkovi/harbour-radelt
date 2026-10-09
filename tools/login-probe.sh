#!/bin/sh
# Prueft das aus dem Binaer rekonstruierte Anmeldeformat.
#
#   sh tools/login-probe.sh
#
# blutter hat auf arch das Dart-Abbild rekonstruiert. Der Anmelde-Koerper
# sieht danach so aus (_$LoginRequestToJson, exakte Schluessel):
#
#   { "secure", "user", "password", "oneSignalUserId",
#     "platform":"android", "appVersion", "language" }
#
# Zwei Dinge, die keine einzige bisherige Probe hatte: die Kennung heisst
# **user** (nicht email -- die Registrierung nutzt dagegen email, die
# Routen sind uneinheitlich), und es gibt eine Signatur **secure**:
#
#   secure = md5Hex( user + password + "TourDeBoedele" )
#
# Das Salz steht wortwoertlich im Binaer. Offen war nur die Reihenfolge im
# md5 -- die probiert dieses Skript beide Wege durch.
#
# Das Passwort wird verdeckt eingelesen, nie ausgegeben und nur lokal
# gehasht.
set -e

API=${1:-https://dashboard.radelt.at/api/v2}

printf 'Kennung (E-Mail oder Benutzername): '
read -r KENNUNG
printf 'Passwort (bleibt verdeckt): '
stty -echo 2>/dev/null || true
read -r GEHEIM
stty echo 2>/dev/null || true
printf '\n\n'
export KENNUNG GEHEIM

versuch() {
    printf '   %-34s ' "$1"
    antwort=$(RADELT_ORDER="$2" RADELT_FELD="$3" python3 -c '
import hashlib, json, os
user = os.environ["KENNUNG"]; pw = os.environ["GEHEIM"]
roh = (user + pw) if os.environ["RADELT_ORDER"] == "up" else (pw + user)
secure = hashlib.md5((roh + "TourDeBoedele").encode("utf-8")).hexdigest()
print(json.dumps({
    "secure": secure,
    os.environ["RADELT_FELD"]: user,
    "password": pw,
    "oneSignalUserId": None,
    "platform": "android",
    "appVersion": "10.4.2",
    "language": "de",
}))' | curl -s -m 25 -X POST --data-binary @- \
        -H 'Content-Type: application/json' -H 'Accept: application/json' \
        "$API/login" || echo '{"error":"keine Antwort"}')
    # Token unkenntlich machen, bevor etwas sichtbar wird.
    echo "$antwort" | sed -E 's/("(api_)?token"[[:space:]]*:[[:space:]]*")[^"]+"/\1…"/g' | cut -c1-190
    printf '\n'
    case "$antwort" in
        *'"success":true'*) printf '\n>>> GEHT: %s\n' "$1"; exit 0 ;;
    esac
    sleep 1
}

echo "=== Mit Signatur, Feldname user ==="
versuch "secure=md5(user+passwort+Salz)" up user
versuch "secure=md5(passwort+user+Salz)" pu user

echo "=== Gegenprobe mit Feldname email ==="
versuch "email, md5(user+passwort+Salz)" up email

printf '\nKeine Variante hat success:true geliefert.\n'
printf 'Dann ist das Format zwar richtig, aber dieses Konto an der\n'
printf 'App-Schnittstelle nicht freigeschaltet (siehe doc/api.md §10).\n'
