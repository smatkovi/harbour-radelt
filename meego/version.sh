#!/bin/sh
# The version the MeeGo build stamps into package and binary: the Sailfish
# release this edition follows (rpm/harbour-radelt.yaml) plus its own
# revision. Count the revision up for every new .deb, otherwise build-deb.sh
# quietly writes the same package twice and dpkg sees no update.
HERE=$(cd "$(dirname "$0")/.." && pwd)
UP=$(sed -n 's/^Version: *//p' "$HERE/rpm/harbour-radelt.yaml" | head -1)
echo "${UP:-0.1.0}-meego1"
