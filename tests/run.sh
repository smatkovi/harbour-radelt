#!/bin/sh
# Builds and runs the core tests. Needs only Qt Core, so it works on the
# Sailfish device, on the build machine and in the SDK container.
#
#   sh tests/run.sh
set -e
HERE=$(cd "$(dirname "$0")/.." && pwd)
OUT=${OUT:-/tmp/radelt-tests}
mkdir -p "$OUT"

QTINC=${QTINC:-/usr/include/qt5}
if [ ! -d "$QTINC/QtCore" ]; then
    QTINC=$(pkg-config --variable=includedir Qt5Core 2>/dev/null || echo /usr/include/qt5)
fi

g++ -O1 -Wall -o "$OUT/coretest" \
    "$HERE/tests/coretest.cpp" "$HERE/src/json.cpp" "$HERE/src/track.cpp" \
    -I"$HERE/src" -I"$QTINC" -I"$QTINC/QtCore" -fPIC \
    -lQt5Core -lm
"$OUT/coretest"
