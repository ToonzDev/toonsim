#!/bin/sh
# Starts the FreeToon (LVGL) simulator on PC (Linux / WSL).
# Usage:
#   ./toonsim-freetoon.sh [--size toon2|toon1] [--build] [mode / args]
#   ./toonsim.sh --freetoon [--size toon2|toon1]

HOME_DIR="$(cd "$(dirname "$0")" && pwd)"
FREETOON_DIR=""

if [ -n "$FREETOON_PATH" ] && [ -f "$FREETOON_PATH/lvgl_ui_recovered/src/Makefile" ]; then
    FREETOON_DIR="$FREETOON_PATH"
elif [ -f "$HOME_DIR/../freetoon-lvgl/lvgl_ui_recovered/src/Makefile" ]; then
    FREETOON_DIR="$(cd "$HOME_DIR/../freetoon-lvgl" && pwd)"
elif [ -f "$HOME_DIR/freetoon-lvgl/lvgl_ui_recovered/src/Makefile" ]; then
    FREETOON_DIR="$(cd "$HOME_DIR/freetoon-lvgl" && pwd)"
fi

if [ -z "$FREETOON_DIR" ]; then
    echo "[ERROR] Could not find the freetoon-lvgl repository."
    echo "Please clone freetoon-lvgl next to toonsim or set FREETOON_PATH."
    exit 1
fi

MODEL="toon2"
if [ -f "$HOME_DIR/firmware/toon-model.txt" ]; then
    MODEL="$(tr -d '\r\n' < "$HOME_DIR/firmware/toon-model.txt")"
fi

DO_BUILD=0
FORWARD_ARGS=""

while [ $# -gt 0 ]; do
    case "$1" in
        --size)
            MODEL="$2"
            shift 2
            ;;
        toon1)
            MODEL="toon1"
            shift
            ;;
        toon2)
            MODEL="toon2"
            shift
            ;;
        --build)
            DO_BUILD=1
            shift
            ;;
        --freetoon)
            shift
            ;;
        --ui)
            shift
            if [ "$1" = "freetoon" ]; then shift; fi
            ;;
        --help|-h)
            cat <<EOF
=========================================================================
FreeToon LVGL Simulator for Toon Simulator
=========================================================================
Usage:
  ./toonsim-freetoon.sh [--size toon2|toon1] [--build] [mode / args]
  ./toonsim.sh --freetoon [--size toon2|toon1]

Modes:
  (no arguments)       Interactive graphical simulator window (X11)
  all [dir]            Export all screen images to PPM files (default: /tmp)
  nav [out.ppm] [x,y]  Interactive navigation trace
  <screen> [out.ppm]   Render a specific screen (home, settings, thermostat, etc.)

Options:
  --size toon2         Toon 2 layout (1024x600, default)
  --size toon1         Toon 1 layout (800x480)
  --build              Force recompile before running
  --help, -h           Show this help
=========================================================================
EOF
            exit 0
            ;;
        *)
            FORWARD_ARGS="$FORWARD_ARGS $1"
            shift
            ;;
    esac
done

if [ "$MODEL" = "toon1" ]; then
    BIN_NAME="toonui-sim1"
    TARGET="sim1"
    BUILD_SUBDIR="build-sim1"
    RES_INFO="800x480"
else
    BIN_NAME="toonui-sim"
    TARGET="sim"
    BUILD_SUBDIR="build-sim"
    RES_INFO="1024x600"
fi

BIN_PATH="$FREETOON_DIR/lvgl_ui_recovered/$BUILD_SUBDIR/$BIN_NAME"

if [ ! -f "$BIN_PATH" ] || [ "$DO_BUILD" -eq 1 ]; then
    echo "[toonsim] Building FreeToon simulator ($TARGET, $RES_INFO)..."
    make -C "$FREETOON_DIR/lvgl_ui_recovered/src" TARGET="$TARGET" -j4 || {
        echo "[ERROR] FreeToon simulator build failed."
        exit 1
    }
fi

export DISPLAY="${DISPLAY:-:0}"
mkdir -p /mnt/data 2>/dev/null && chmod 777 /mnt/data 2>/dev/null || true
echo "[toonsim] Starting FreeToon Simulator ($MODEL, $RES_INFO)..."
cd "$FREETOON_DIR/lvgl_ui_recovered/$BUILD_SUBDIR"
exec "./$BIN_NAME" $FORWARD_ARGS

