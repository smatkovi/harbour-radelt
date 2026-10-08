#!/bin/sh
# Liest nach, was die Original-App unter Androidsupport abgelegt hat.
#
#   sudo sh tools/read-android-app.sh
#
# Warum das reicht: die App haengt einen Zwischenspeicher in ihre
# HTTP-Kette (dio_cache_interceptor mit Hive-Ablage) und fuehrt ein
# Keksglas. Beides liegt als Datei im Behaelter. Aus den gespeicherten
# Antworten lassen sich die echten Feldnamen und Formate ablesen, ohne
# die TLS-Verbindung aufzubrechen.
#
# Ausgegeben werden **Schluesselnamen und Formen**, keine Werte: alles,
# was laenger als ein paar Zeichen ist, wird gekuerzt. Was hier zu sehen
# sein soll, ist der Aufbau der Antworten, nicht der Inhalt des Kontos.
set -e

PAKET=${PAKET:-com.jonasit.fahrradwettbewerb.oer}
WURZEL=/home/.appsupport/instance/$(logname 2>/dev/null || echo defaultuser)/data/data/$PAKET

[ -d "$WURZEL" ] || { echo "Nicht gefunden: $WURZEL" >&2; exit 1; }

echo "=== Dateien (groesste zuerst) ==="
find "$WURZEL" -type f -printf '%10s  %P\n' 2>/dev/null | sort -rn | head -40

echo
echo "=== Einstellungen (XML) ==="
for f in "$WURZEL"/shared_prefs/*.xml; do
    [ -f "$f" ] || continue
    echo "--- ${f##*/}"
    sed -E 's/>[^<]{12,}</>…</g' "$f" | head -40
done

echo
echo "=== Zeichenketten in den Hive-/Cache-Dateien, die nach JSON aussehen ==="
find "$WURZEL" -type f \( -name '*.hive' -o -name '*.lock' -o -path '*cache*' \) 2>/dev/null |
while read -r f; do
    treffer=$(strings -n 6 "$f" 2>/dev/null | grep -cE '"(success|data|message|api_token|token|personId|rideId)"' || true)
    [ "${treffer:-0}" -gt 0 ] && printf '%6s Treffer  %s\n' "$treffer" "${f#$WURZEL/}"
done

echo
echo "=== Schluessel aus den gefundenen JSON-Stuecken ==="
find "$WURZEL" -type f 2>/dev/null | while read -r f; do
    strings -n 8 "$f" 2>/dev/null | grep -oE '\{"[^"]+":' | sort -u
done | sort -u | head -40

echo
echo "=== Keksglas / Sitzungen ==="
find "$WURZEL" -iname '*cookie*' -o -iname '*.cookies' 2>/dev/null | while read -r f; do
    echo "--- ${f#$WURZEL/}"
    strings -n 4 "$f" 2>/dev/null | grep -iE 'session|xsrf|token|radelt' | sed -E 's/(.{24}).*/\1…/' | head -10
done
