#!/bin/sh
# Parses the MeeGo QML against Qt 4's QDeclarative on the build machine.
#
#   meego/tests/check-qml.sh
#
# Catches what only shows on the device otherwise: a property that does not
# exist under QtQuick 1.1, a mistyped binding, a file that does not parse.
set -e
HERE=$(cd "$(dirname "$0")/../.." && pwd)
sh "$HERE/meego/build.sh" check
"$HERE/build/meego/check/harbour-radelt" "$HERE/meego/qml"
