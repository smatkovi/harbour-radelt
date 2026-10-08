#!/bin/sh
# Builds the MeeGo Harmattan edition (Nokia N9/N950) on the build machine,
# inside the synchronised source tree:
#
#   meego/build.sh arm     the device binary -> build/meego/arm/harbour-radelt
#   meego/build.sh check   the QML checker against the SDK's desktop Qt 4
#
# The ARM build needs the GCC cross toolchain (XGCC) and the MADDE sysroot
# (SYSROOT); moc and lrelease come from the Qt Simulator's Qt 4.7.4, the
# version on the device. libstdc++ is linked statically and kept private, so
# Qt on the device stays on its own GCC 4.4 runtime.
set -e

HERE=$(cd "$(dirname "$0")/.." && pwd)
MODE=${1:-arm}
XGCC=${XGCC:-/tmp/xgcc-harmattan}
SYSROOT=${SYSROOT:-$HOME/QtSDK/Madde/sysroots/harmattan_sysroot_10.2011.34-1_slim}
SIMQT=${SIMQT:-$HOME/QtSDK/Simulator/Qt/gcc}
JOBS=${JOBS:-8}
VERSION=${VERSION:-$(sh "$HERE/meego/version.sh")}
OUT=$HERE/build/meego/$MODE
mkdir -p "$OUT"

# src/harbour-radelt.cpp (SailfishApp) is replaced by meego/main.cpp; the
# rest of src/ is shared with the Sailfish edition unchanged.
APP_SRC="src/api.cpp \
 src/format.cpp \
 src/http.cpp \
 src/json.cpp \
 src/recorder.cpp \
 src/ridestore.cpp \
 src/settings.cpp \
 src/track.cpp \
 meego/main.cpp"

# Headers with a Q_OBJECT in them.
MOC_HEADERS="src/api.h \
 src/format.h \
 src/http.h \
 src/recorder.h \
 src/ridestore.h \
 src/settings.h"

INCLUDES="-I$HERE -I$HERE/src -I$HERE/meego"
DEFINES="-DAPP_VERSION='\"$VERSION\"' -DQT_NO_DEBUG"

COMMON_FLAGS="-O2 -Wall -Wno-deprecated-declarations -Wno-unused-parameter \
 $DEFINES $INCLUDES"
CXX_ONLY="-std=gnu++98"

# QtLocation is QtMobility's positioning module -- the Harmattan name for
# what Qt 5 calls QtPositioning.
QT4_MODULES="QtCore QtGui QtNetwork QtDeclarative QtLocation"

case "$MODE" in
arm)
    CXX=$XGCC/bin/arm-none-linux-gnueabi-g++
    [ -x "$CXX" ] || { echo "cross compiler missing: $CXX" >&2; exit 1; }
    MOC=$SIMQT/bin/moc
    LRELEASE=$SIMQT/bin/lrelease
    QTINC=$SYSROOT/usr/include/qt4
    CXXFLAGS="--sysroot=$SYSROOT $COMMON_FLAGS $CXX_ONLY -I$QTINC"
    for m in $QT4_MODULES; do CXXFLAGS="$CXXFLAGS -I$QTINC/$m"; done
    # Harmattan is hard-float but kept the old loader name; the static
    # libstdc++ of the newer GCC stays private to the binary.
    LDFLAGS="--sysroot=$SYSROOT -static-libstdc++ -static-libgcc -Wl,-O1 -Wl,--as-needed \
 -Wl,--exclude-libs,ALL -Wl,--dynamic-linker=/lib/ld-linux.so.3"
    LIBS="-lQtDeclarative -lQtLocation -lQtGui -lQtNetwork -lQtCore -lpthread"
    ;;
check)
    # The QML checker is built against the plain desktop Qt of the SDK
    # (4.8.1): the Simulator's Qt aborts without a display even for a
    # program without a window, and the device Qt does not run here.
    CXX=${CXX:-g++}
    PROBEQT=${PROBEQT:-$HOME/QtSDK/Desktop/Qt/4.8.1/gcc}
    [ -x "$PROBEQT/bin/moc" ] || { echo "SDK Qt 4.8 missing: $PROBEQT" >&2; exit 1; }
    MOC=$PROBEQT/bin/moc
    LRELEASE=$PROBEQT/bin/lrelease
    QTINC=$PROBEQT/include
    CXXFLAGS="$COMMON_FLAGS $CXX_ONLY -I$QTINC"
    for m in QtCore QtGui QtNetwork QtDeclarative; do CXXFLAGS="$CXXFLAGS -I$QTINC/$m"; done
    LDFLAGS="-L$PROBEQT/lib -Wl,-rpath,$PROBEQT/lib"
    LIBS="-lQtDeclarative -lQtGui -lQtNetwork -lQtCore -lpthread"
    # The checker brings its own stand-ins (meego/tests/stubs.h) instead of
    # the real objects: those pull in QtMobility, which the desktop Qt here
    # does not have, and the QML does not need them to be parsed.
    APP_SRC="meego/tests/qml_check.cpp"
    MOC_HEADERS="meego/tests/stubs.h"
    ;;
*)
    echo "usage: $0 arm|check" >&2; exit 2 ;;
esac

MK=$OUT/Makefile
{
    echo "CXX=$CXX"; echo "MOC=$MOC"
    echo "CXXFLAGS=$CXXFLAGS"
    echo "LDFLAGS=$LDFLAGS"; echo "LIBS=$LIBS"; echo "SRC=$HERE"; echo
    objs=
    for s in $APP_SRC; do
        o=$(basename "$s" .cpp).o; objs="$objs $o"
        echo "$o: \$(SRC)/$s"; printf '\t$(CXX) $(CXXFLAGS) -MMD -MP -c $< -o $@\n'
    done
    for h in $MOC_HEADERS; do
        base=$(basename "$h" .h)
        o=moc_$base.o; objs="$objs $o"
        echo "moc_$base.cpp: \$(SRC)/$h"; printf '\t$(MOC) $(filter -I%%,$(CXXFLAGS)) $< -o $@\n'
        echo "$o: moc_$base.cpp"; printf '\t$(CXX) $(CXXFLAGS) -c $< -o $@\n'
    done
    echo
    echo "harbour-radelt:$objs"; printf '\t$(CXX) $(LDFLAGS) -o $@ %s $(LIBS)\n' "$objs"
    echo
    echo "-include \$(wildcard *.d)"
} > "$MK"

make -C "$OUT" -f Makefile -j"$JOBS" harbour-radelt

# The translations travel with the package.
if [ -f "$HERE/translations/harbour-radelt-de.ts" ] && [ -x "$LRELEASE" ]; then
    mkdir -p "$OUT/translations"
    "$LRELEASE" "$HERE/translations/harbour-radelt-de.ts" \
        -qm "$OUT/translations/harbour-radelt-de.qm"
fi

ls -la "$OUT/harbour-radelt"
