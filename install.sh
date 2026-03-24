#!/bin/zsh

# ============================================
#  pokefetch — installer
# ============================================

set -e

SCRIPT_DIR="${0:A:h}"
INSTALL_DIR="$HOME/.config/fastfetch"
POKEMONS_DIR="$INSTALL_DIR/pokemons"

# ---------- colors ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo "${GREEN}✓${NC} $1" }
warn() { echo "${YELLOW}⚠${NC} $1" }
err()  { echo "${RED}✗${NC} $1" }
info() { echo "${CYAN}→${NC} $1" }

# ---------- banner ----------
echo ""
echo "${BOLD}    ⚡ pokefetch installer ⚡${NC}"
echo "    Show animated Pokémon sprites with fastfetch"
echo ""

# ---------- check macOS ----------
if [[ "$(uname)" != "Darwin" ]]; then
    err "pokefetch currently only supports macOS."
    exit 1
fi

# ---------- check / install Homebrew ----------
if ! command -v brew &> /dev/null; then
    warn "Homebrew is not installed."
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
ok "Homebrew"

# ---------- check / install fastfetch ----------
if ! command -v fastfetch &> /dev/null; then
    info "Installing fastfetch..."
    brew install fastfetch
fi
ok "fastfetch $(fastfetch --version 2>/dev/null | head -n1)"

# ---------- check / install ImageMagick ----------
if ! command -v magick &> /dev/null; then
    info "Installing ImageMagick..."
    brew install imagemagick
fi
ok "ImageMagick"

# ---------- check / install Python 3 ----------
if ! command -v python3 &> /dev/null; then
    info "Installing Python 3..."
    brew install python3
fi
ok "Python $(python3 --version 2>&1 | awk '{print $2}')"

# ---------- check / install Pillow ----------
if ! python3 -c "from PIL import Image" 2> /dev/null; then
    info "Installing Pillow..."
    pip3 install Pillow --break-system-packages 2>/dev/null || pip3 install Pillow
fi
ok "Pillow"

echo ""

# ---------- copy files ----------
info "Installing pokefetch to ${BOLD}$INSTALL_DIR${NC}"

mkdir -p "$INSTALL_DIR"
mkdir -p "$POKEMONS_DIR"

cp "$SCRIPT_DIR/config.jsonc"    "$INSTALL_DIR/config.jsonc"
cp "$SCRIPT_DIR/display_gif.sh"  "$INSTALL_DIR/display_gif.sh"
cp "$SCRIPT_DIR/get_pokemon.sh"  "$INSTALL_DIR/get_pokemon.sh"
cp "$SCRIPT_DIR/get_color.py"    "$INSTALL_DIR/get_color.py"

chmod +x "$INSTALL_DIR/display_gif.sh"
chmod +x "$INSTALL_DIR/get_pokemon.sh"

ok "Scripts installed"

# ---------- copy GIFs ----------
GIF_COUNT=$(ls "$SCRIPT_DIR/pokemons/"*.gif 2>/dev/null | wc -l | tr -d ' ')
if [[ "$GIF_COUNT" -gt 0 ]]; then
    cp "$SCRIPT_DIR/pokemons/"*.gif "$POKEMONS_DIR/"
    ok "Copied $GIF_COUNT Pokémon GIFs"
else
    warn "No GIFs found in pokemons/ — add .gif files to $POKEMONS_DIR manually"
fi

# ---------- shell integration ----------
ZSHRC="$HOME/.zshrc"
MARKER="# pokefetch"

if ! grep -q "$MARKER" "$ZSHRC" 2>/dev/null; then
    info "Adding pokefetch to ${BOLD}~/.zshrc${NC}"
    cat >> "$ZSHRC" << 'EOF'

# pokefetch
alias c='clear && $HOME/.config/fastfetch/display_gif.sh'
$HOME/.config/fastfetch/display_gif.sh
EOF
    ok "Shell integration added"
else
    ok "Shell integration already present"
fi

# ---------- done ----------
echo ""
echo "${GREEN}${BOLD}    ✓ pokefetch installed successfully!${NC}"
echo ""
echo "    Open a new terminal to see it in action,"
echo "    or run: ${BOLD}source ~/.zshrc${NC}"
echo ""
