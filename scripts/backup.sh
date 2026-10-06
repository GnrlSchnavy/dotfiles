#!/bin/bash

set -euo pipefail

# Backs up the state git can't regenerate: app-owned settings, the codemem
# memory databases and the Docker config, plus package and version lists.
# Managed dotfiles are skipped — a rebuild recreates them from the repo.
# Backups go to ~/.dotfiles-backups/<timestamp>/ (owner-only: the Docker
# and Claude files can hold credentials); the newest $BACKUP_KEEP are kept.

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}💾 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

umask 077

BACKUP_ROOT="$HOME/.dotfiles-backups"
BACKUP_KEEP="${BACKUP_KEEP:-5}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

echo "🗄️  Dotfiles Backup Script"
echo

print_step "Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# App-owned files (paths relative to $HOME). Missing ones are skipped.
declare -a STATE_FILES=(
    ".claude/settings.json"
    ".claude.json"
    ".claude-work/settings.json"
    ".claude-work/.claude.json"
    ".docker/config.json"
)

print_step "Backing up app-owned settings..."
for rel in "${STATE_FILES[@]}"; do
    src="$HOME/$rel"
    [ -f "$src" ] || continue
    mkdir -p "$BACKUP_DIR/home/$(dirname "$rel")"
    if cp "$src" "$BACKUP_DIR/home/$rel"; then
        echo "  📄 ~/$rel"
    else
        print_warning "Could not back up ~/$rel"
    fi
done

# sqlite3's .backup takes a consistent copy even while codemem is writing.
print_step "Backing up codemem memory databases..."
for db in "$HOME"/.codemem/*/mem.sqlite; do
    [ -f "$db" ] || continue
    rel="${db#"$HOME"/}"
    mkdir -p "$BACKUP_DIR/home/$(dirname "$rel")"
    if sqlite3 "$db" ".backup '$BACKUP_DIR/home/$rel'" 2>/dev/null || cp "$db" "$BACKUP_DIR/home/$rel"; then
        echo "  🧠 ~/$rel"
    else
        print_warning "Could not back up ~/$rel"
    fi
done

print_step "Recording system state..."
if command -v darwin-version > /dev/null 2>&1; then
    darwin-version > "$BACKUP_DIR/darwin-version.txt" 2>/dev/null || true
fi
if command -v brew > /dev/null 2>&1; then
    brew list --cask > "$BACKUP_DIR/brew-casks.txt" 2>/dev/null || true
    brew list --formula > "$BACKUP_DIR/brew-formulas.txt" 2>/dev/null || true
fi
sw_vers > "$BACKUP_DIR/system-version.txt" 2>/dev/null || true
git -C "$HOME/.dotfiles" rev-parse HEAD > "$BACKUP_DIR/dotfiles-commit.txt" 2>/dev/null || true

cat > "$BACKUP_DIR/README.md" << EOF
# Backup $TIMESTAMP

Taken on $(date) for $(id -un).

\`home/\` mirrors \$HOME: copy a file back to the same path under \$HOME to
restore it. Quit Claude Code (or Docker Desktop) first, since they rewrite
these files. For example:

    cp home/.claude/settings.json ~/.claude/settings.json
    cp home/.codemem/personal/mem.sqlite ~/.codemem/personal/mem.sqlite

Then rebuild, which merges the lane-owned keys back into the Claude settings.
Everything else (dotfiles, packages) comes from the repo: clone it and run
setup.sh. \`dotfiles-commit.txt\` is the repo commit at backup time.
EOF

print_step "Pruning old backups (keeping the newest $BACKUP_KEEP)..."
count=$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
excess=$((count - BACKUP_KEEP))
if [ "$excess" -gt 0 ]; then
    find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d | sort | head -n "$excess" | while read -r old; do
        rm -rf "$old"
        echo "  🗑  $(basename "$old")"
    done
fi

print_success "Backup completed"
echo "📍 $BACKUP_DIR ($(du -sh "$BACKUP_DIR" | cut -f1))"
