#!/bin/sh
# Builds radelt-fetch (meego/fetch) for the N9/N950 -- statically against
# musl, on the build machine. meego/remote-build.sh runs this there.
#
#   meego/build-rust.sh     -> build/meego/fetch/radelt-fetch
set -e
HERE=$(cd "$(dirname "$0")/.." && pwd)
. "$HERE/meego/cross.env"
[ -x "$CARGO_HOME/bin/cargo" ] || { echo "cargo missing under $CARGO_HOME" >&2; exit 1; }
cd "$HERE/meego/fetch"
CARGO_TARGET_DIR=${CARGO_TARGET_DIR:-/tmp/radelt-fetch-target}
export CARGO_TARGET_DIR
nice cargo build --release --target "$ZIEL"
mkdir -p "$HERE/build/meego/fetch"
cp "$CARGO_TARGET_DIR/$ZIEL/release/radelt-fetch" "$HERE/build/meego/fetch/radelt-fetch"
ls -la "$HERE/build/meego/fetch/radelt-fetch"
