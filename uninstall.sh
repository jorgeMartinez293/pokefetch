#!/bin/zsh

# ============================================
#  pokefetch — uninstaller
# ============================================

INSTALL_DIR="$HOME/.config/fastfetch"
ZSHRC="$HOME/.zshrc"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo "${GREEN}✓${NC} $1" }
warn() { echo "${YELLOW}⚠${NC} $1" }
info() { echo "${CYAN}→${NC} $1" }

echo ""
echo "${BOLD}    ⚡ pokefetch uninstaller ⚡${NC}"
echo ""

# ---------- confirmation ----------
echo -n "This will remove pokefetch from your system. Continue? [y/N] "
read -r REPLY
if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""

# ---------- remove installed files ----------
if [[ -d "$INSTALL_DIR" ]]; then
    info "Removing $INSTALL_DIR..."
    rm -f "$INSTALL_DIR/display_gif.sh"
    rm -f "$INSTALL_DIR/get_pokemon.sh"
    rm -f "$INSTALL_DIR/get_color.py"
    rm -f "$INSTALL_DIR/config.jsonc"
    rm -rf "$INSTALL_DIR/pokemons"
    
    # Remove the directory only if it's empty
    rmdir "$INSTALL_DIR" 2>/dev/null && ok "Removed $INSTALL_DIR" || \
        warn "$INSTALL_DIR not empty — other fastfetch configs may exist, leaving it"
else
    warn "$INSTALL_DIR not found — skipping"
fi

# ---------- remove shell integration ----------
if [[ -f "$ZSHRC" ]]; then
    if grep -q "# pokefetch" "$ZSHRC"; then
        info "Cleaning up ~/.zshrc..."
        # Remove the pokefetch block (marker + next 2 lines)
        sed -i '' '/^# pokefetch$/,+2d' "$ZSHRC"
        # Remove any trailing blank line left behind
        sed -i '' -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$ZSHRC"
        ok "Shell integration removed"
    else
        ok "No pokefetch entries in ~/.zshrc"
    fi
fi

echo ""
echo "${GREEN}${BOLD}    ✓ pokefetch uninstalled${NC}"
echo ""
echo "    Dependencies (fastfetch, ImageMagick, Pillow) were NOT removed."
echo "    Remove them manually with: ${BOLD}brew uninstall fastfetch imagemagick${NC}"
echo ""
