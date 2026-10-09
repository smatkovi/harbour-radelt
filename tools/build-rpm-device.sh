#!/bin/sh
# Builds the aarch64 RPM on a Sailfish device itself, without the SDK.
#
#   sh tools/build-rpm-device.sh        # -> ~/ps/rpms/radelt/harbour-radelt-<v>-1.aarch64.rpm
#
# The proper way is tools/build-rpms.sh on the build machine, which builds
# every architecture in the SDK container. This is for when that machine is
# not reachable and the phone it is meant for is aarch64 anyway.
#
# Three things the device's own Qt installation lacks, all worked around
# here instead of by installing more onto a phone that is in daily use:
#   * GLES headers. qt5-qtgui-devel's <GLES3/gl31.h> comes from
#     android-headers, which no repository offers. The Khronos originals do
#     the same job and are fetched into $GLES once.
#   * libGLESv2.so. Only the versioned libGLESv2.so.2 is installed; the
#     linker wants the bare name, so a symlink to it is made in $COMPLIB.
#   * %qtc_qmake5. That macro belongs to the SDK; here qmake is called
#     directly and the package is built from the staged tree.
set -e

SRC=$(cd "$(dirname "$0")/.." && pwd)
BUILD=${BUILD:-/tmp/radelt-build}
STAGE=${STAGE:-/tmp/radelt-root}
GLES=${GLES:-/tmp/gles-headers}
COMPLIB=$BUILD/complib
OUT=${OUT:-$HOME/ps/rpms/radelt}
VERSION=$(sed -n 's/^Version: *//p' "$SRC/rpm/harbour-radelt.spec" | head -1)
RELEASE=$(sed -n 's/^Release: *//p' "$SRC/rpm/harbour-radelt.spec" | head -1)
ARCH=$(uname -m)

# The Khronos headers, fetched once.
if [ ! -f "$GLES/GLES3/gl31.h" ]; then
    echo "GLES-Header holen nach $GLES"
    mkdir -p "$GLES/GLES2" "$GLES/GLES3" "$GLES/KHR"
    for f in GLES2/gl2.h GLES2/gl2ext.h GLES2/gl2platform.h \
             GLES3/gl3.h GLES3/gl31.h GLES3/gl32.h GLES3/gl3platform.h; do
        curl -fsS -o "$GLES/$f" "https://registry.khronos.org/OpenGL/api/$f"
    done
    curl -fsS -o "$GLES/KHR/khrplatform.h" \
        "https://registry.khronos.org/EGL/api/KHR/khrplatform.h"
fi

mkdir -p "$COMPLIB"
for l in GLESv2 EGL; do
    target=$(ls /usr/lib64/lib$l.so.* 2>/dev/null | head -1)
    [ -n "$target" ] && ln -sf "$target" "$COMPLIB/lib$l.so"
done

cd "$BUILD"
qmake "$SRC/harbour-radelt.pro" "INCLUDEPATH+=$GLES" "LIBS+=-L$COMPLIB"
make -j"$(nproc)"
rm -rf "$STAGE"
make install INSTALL_ROOT="$STAGE"

# Nothing of the build machine may stick to the binary.
strip --strip-unneeded "$STAGE/usr/bin/harbour-radelt"

SPEC=$BUILD/device.spec
cat > "$SPEC" <<SPEC_END
Name:       harbour-radelt
Summary:    Kilometres for Österreich radelt
Version:    $VERSION
Release:    $RELEASE
Group:      Qt/Qt
License:    GPLv3
URL:        https://github.com/smatkovi/harbour-radelt
BuildArch:  $ARCH
Requires:   sailfishsilica-qt5 >= 0.10.9
Requires:   qt5-qtdeclarative-import-positioning
Requires:   libkeepalive >= 1.8
AutoReqProv: no
# The device's rpm runs the usual post-install scripts with busybox tools,
# which do not take the options those scripts pass; there is nothing for
# them to do here anyway, the tree is already built and stripped.
%define __os_install_post %{nil}
%define debug_package %{nil}

%description
Records bicycle rides with the satellite receiver, keeps them on the phone as
GPX, and sends the kilometres to the Österreich radelt platform. Rides can
also be typed in by hand.

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}
cp -a $STAGE/. %{buildroot}/

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
%{_datadir}/ambience/%{name}
SPEC_END

rpmbuild -bb "$SPEC" --define "_topdir $BUILD/rpm" --define "_rpmdir $BUILD/rpm"
mkdir -p "$OUT"
cp "$BUILD"/rpm/"$ARCH"/harbour-radelt-*.rpm "$OUT/"
ls -l "$OUT"/harbour-radelt-*."$ARCH".rpm
