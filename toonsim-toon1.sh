#!/bin/sh
# Starts the FreeToon (LVGL) simulator in Toon 1 mode (800x480).
# Usage:
#   ./toonsim-toon1.sh [mode / args]

HERE="$(cd "$(dirname "$0")" && pwd)"
exec "$HERE/toonsim-freetoon.sh" --size toon1 "$@"

