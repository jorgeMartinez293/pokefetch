#!/bin/zsh

# --- 0. READ POKEFETCH CONFIG ---
BASE_DIR="$HOME/.config/fastfetch"
POKEMONS_DIR="$BASE_DIR/pokemons"
CONFIG_PATH="$BASE_DIR/config.jsonc"
POKEFETCH_CFG="$BASE_DIR/pokefetch_config.json"

FORCED_POKEMON=""
FORCED_MODE=""

if [[ -f "$POKEFETCH_CFG" ]]; then
    _cfg=$(python3 -c "
import json
try:
    with open('$POKEFETCH_CFG') as f:
        c = json.load(f)
    print(c.get('selected_pokemon', ''))
    print(c.get('display_mode', ''))
except:
    print('')
    print('')
" 2>/dev/null)
    FORCED_POKEMON="${_cfg%%$'\n'*}"
    FORCED_MODE="${_cfg##*$'\n'}"
fi

# --- 1. CACHE IMAGEMAGICK COMMAND ---
if command -v magick &>/dev/null; then
    IM_CMD="magick"
elif command -v convert &>/dev/null; then
    IM_CMD="convert"
else
    IM_CMD=""
fi

# Override FORCED_MODE from env (used by the app for live preview)
if [[ -n "$POKEFETCH_PREVIEW_MODE" ]]; then
    FORCED_MODE="$POKEFETCH_PREVIEW_MODE"
fi

# --- 2. FILE SELECTION ---
if [[ -n "$POKEFETCH_PREVIEW" && -f "$POKEFETCH_PREVIEW" ]]; then
    GIF_PATH="$POKEFETCH_PREVIEW"
elif [[ -n "$FORCED_POKEMON" && -f "$POKEMONS_DIR/$FORCED_POKEMON" ]]; then
    GIF_PATH="$POKEMONS_DIR/$FORCED_POKEMON"
else
    files=("$POKEMONS_DIR"/*.gif(.N) "$POKEMONS_DIR"/*.png(.N) "$POKEMONS_DIR"/*.jpg(.N))
    files=("${(@)files:#}" )
    # Filter only existing files
    files=(${^files}(N))
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "No images found in $POKEMONS_DIR. Running default fastfetch."
        fastfetch
        exit 0
    fi
    GIF_PATH="${files[$(( (RANDOM % ${#files[@]}) + 1 ))]}"
fi

# --- 3. VALIDATION ---
if [[ ! -f "$GIF_PATH" ]]; then
    echo "Logo not found at $GIF_PATH. Running default fastfetch."
    fastfetch
    exit 0
fi

# --- 4. DISPLAY MODE LOGIC ---
IS_GIF=$([[ "${GIF_PATH:e:l}" == "gif" ]] && echo "1" || echo "0")

if [[ "$FORCED_MODE" == "gif" ]]; then
    TARGET_IMAGE="$GIF_PATH"
elif [[ "$FORCED_MODE" == "image" ]]; then
    if [[ "$IS_GIF" == "1" ]]; then
        TARGET_IMAGE="${GIF_PATH}[0]"
    else
        TARGET_IMAGE="$GIF_PATH"
    fi
else
    # auto mode (default): use battery state
    POWER_SOURCE=$(pmset -g batt 2>/dev/null | head -n 1 | grep -o "'[^']*'" | tr -d "'")
    if [[ "$POWER_SOURCE" == "Battery Power" && "$IS_GIF" == "1" ]]; then
        TARGET_IMAGE="${GIF_PATH}[0]"
    else
        TARGET_IMAGE="$GIF_PATH"
    fi
fi

# --- 5. IMAGE PROCESSING ---

# --- 5.1 GET ORIGINAL SIZE (single identify call) ---
IMG_W=""
IMG_H=""
if [[ -n "$IM_CMD" ]]; then
    _dims=$($IM_CMD identify -format "%wx%h\n" "$TARGET_IMAGE" 2>/dev/null | head -n 1)
    IMG_W="${_dims%%x*}"
    IMG_H="${_dims##*x}"
fi
if [[ -z "$IMG_W" || -z "$IMG_H" ]]; then
    IMG_W=80; IMG_H=80
fi

# --- 5.2 PROPORTIONAL SCALING ---
LOGO_WIDTH=$(( IMG_W * 35 / 80 ))
LOGO_HEIGHT=$(( IMG_H * 15 / 80 ))

if (( LOGO_WIDTH > 35 )); then LOGO_WIDTH=35; fi
if (( LOGO_HEIGHT > 15 )); then LOGO_HEIGHT=15; fi

# --- 5.3 CENTERING ---
LOGO_PADDING_TOP=$(( (15 - LOGO_HEIGHT) / 2 ))
if (( LOGO_PADDING_TOP < 0 )); then LOGO_PADDING_TOP=0; fi

LOGO_PADDING_LEFT=$(( (35 - LOGO_WIDTH) / 2 ))
if (( LOGO_PADDING_LEFT < 0 )); then LOGO_PADDING_LEFT=0; fi

LOGO_PADDING_RIGHT=$(( 35 - LOGO_WIDTH - LOGO_PADDING_LEFT + 2 ))
if (( LOGO_PADDING_RIGHT < 0 )); then LOGO_PADDING_RIGHT=2; fi

# --- 5.4 CREATE AND PROCESS TEMP FILE ---
TEMP_LOGO=$(mktemp /tmp/fastfetch_logo_XXXXXX.gif)
trap 'rm -f "$TEMP_LOGO"' EXIT INT TERM

# Keep pixel-art crisp with -sample 500%
if [[ -n "$IM_CMD" ]]; then
    $IM_CMD "$TARGET_IMAGE" -sample 500% "$TEMP_LOGO"
else
    cp "$TARGET_IMAGE" "$TEMP_LOGO"
fi

# Guard: if processing failed, fall back to default fastfetch
if [[ ! -s "$TEMP_LOGO" ]]; then
    echo "Warning: image processing failed, running default fastfetch." >&2
    fastfetch
    exit 1
fi

# --- 6. GET AVERAGE COLOR (PASTEL) ---
COLOR=$(python3 "$BASE_DIR/get_color.py" "${TARGET_IMAGE%\[0\]}")

# --- 7. RUN FASTFETCH ---
fastfetch --config "$CONFIG_PATH" \
          --logo-type iterm \
          --logo "$TEMP_LOGO" \
          --logo-width "$LOGO_WIDTH" \
          --logo-height "$LOGO_HEIGHT" \
          --logo-padding-top "$LOGO_PADDING_TOP" \
          --logo-padding-left "$LOGO_PADDING_LEFT" \
          --logo-padding-right "$LOGO_PADDING_RIGHT" \
          --color-keys "$COLOR"
