#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cd "$SCRIPT_DIR/../packages/kiln_cli"
dart compile exe bin/kiln.dart -o "$SCRIPT_DIR/kiln"
