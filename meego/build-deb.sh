#!/bin/sh
# Packs the ARM build as a Harmattan .deb. Runs on the build machine after
# "meego/build.sh arm" and "meego/build-rust.sh":
#
#   meego/build-deb.sh            -> build/meego/harbour-radelt_<version>_armel.deb
#   VERSION=0.1.0-meego2 meego/build-deb.sh
#
# Layout on the device:
#   /opt/harbour-radelt/bin/harbour-radelt
#   /opt/harbour-radelt/bin/radelt-fetch        (HTTPS, see meego/fetch)
#   /opt/harbour-radelt/qml
#   /opt/harbour-radelt/translations
#   /usr/share/applications/harbour-radelt.desktop
#   /usr/share/icons/hicolor/80x80/apps/harbour-radelt.png
#
# mkdeb.py writes the .deb itself: Harmattan's dpkg is 1.15 and wants gzip
# members and no slash on the ar names, which GNU ar does differently. It
# also appends the aegis manifest as the fourth ar member -- without it the
# application gets no position on the device.
set -e

HERE=$(cd "$(dirname "$0")/.." && pwd)
PKG=$HERE/meego
OUT=$HERE/build/meego
BIN=$OUT/arm/harbour-radelt
XGCC=${XGCC:-/tmp/xgcc-harmattan}
VERSION=${VERSION:-$(sh "$PKG/version.sh")}

[ -x "$BIN" ] || { echo "ARM binary missing: $BIN (run meego/build.sh arm first)" >&2; exit 1; }
FETCH=$OUT/fetch/radelt-fetch
[ -x "$FETCH" ] || { echo "radelt-fetch missing: $FETCH (run meego/build-rust.sh first)" >&2; exit 1; }

STAGE=$OUT/stage
rm -rf "$STAGE"
mkdir -p "$STAGE/DEBIAN" "$STAGE/opt/harbour-radelt/bin" \
         "$STAGE/usr/share/applications" "$STAGE/usr/share/icons/hicolor/80x80/apps" \
         "$STAGE/usr/share/themes/base/meegotouch/icons" \
         "$STAGE/usr/share/doc/harbour-radelt"

cp "$BIN" "$STAGE/opt/harbour-radelt/bin/harbour-radelt"
"$XGCC/bin/arm-none-linux-gnueabi-strip" "$STAGE/opt/harbour-radelt/bin/harbour-radelt"
cp "$FETCH" "$STAGE/opt/harbour-radelt/bin/radelt-fetch"
chmod 755 "$STAGE/opt/harbour-radelt/bin/harbour-radelt" \
          "$STAGE/opt/harbour-radelt/bin/radelt-fetch"

cp -a "$PKG/qml" "$STAGE/opt/harbour-radelt/qml"
if [ -d "$OUT/arm/translations" ]; then
    cp -a "$OUT/arm/translations" "$STAGE/opt/harbour-radelt/translations"
fi

# Icons: 80x80 for the launcher, 64x64 base64 for the application manager.
# tools/make-icons.py cuts both to the exact silhouette of the stock apps.
cp "$PKG/icons/icon-80.png" "$STAGE/usr/share/icons/hicolor/80x80/apps/harbour-radelt.png"
cp "$PKG/icons/icon-80.png" "$STAGE/usr/share/themes/base/meegotouch/icons/harbour-radelt-80.png"
cp "$PKG/harbour-radelt.desktop" "$STAGE/usr/share/applications/harbour-radelt.desktop"
cp "$HERE/LICENSE" "$STAGE/usr/share/doc/harbour-radelt/copyright"
find "$STAGE" -type f ! -path "*/bin/*" -exec chmod 644 {} +
find "$STAGE" -type d -exec chmod 755 {} +

# control with the icon; the base64 lines need a leading space each.
ICON=$(base64 -w 76 "$PKG/icons/icon-64.png" | sed 's/^/ /')
awk -v version="$VERSION" -v icon="$ICON" '
    { gsub(/@VERSION@/, version) }
    /^@ICON@$/ { print icon; next }
    { print }
' "$PKG/control.in" > "$STAGE/DEBIAN/control"

cp "$PKG/_aegis" "$STAGE/DEBIAN/_aegis"

DEB=$OUT/harbour-radelt_${VERSION}_armel.deb
python3 "$PKG/mkdeb.py" "$STAGE" "$DEB"
python3 "$PKG/mkdeb.py" --info "$DEB" | head -20
