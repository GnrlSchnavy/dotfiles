#!/bin/bash

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Get current timestamp for backup naming
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="$HOME/.dotfiles_backup_$TIMESTAMP"

echo "🗄️  Dotfiles Backup Script"
echo "Creating backup of current configurations..."
echo

# Create backup directory
print_step "Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# List of files to backup (those managed by stow)
declare -a DOTFILES=(
    "$HOME/.zprofile"
    "$HOME/.zshrc"
    "$HOME/.gitconfig"
    "$HOME/.gitignore_global"
    "$HOME/.ideavimrc"
    "$HOME/.docker"
    "$HOME/.claude"
)

# Backup individual dotfiles
print_step "Backing up dotfiles..."
for file in "${DOTFILES[@]}"; do
    if [ -e "$file" ]; then
        # Preserve directory structure
        target_dir="$BACKUP_DIR/$(dirname "${file#$HOME/}")"
        mkdir -p "$target_dir"

        if [ -L "$file" ]; then
            # It's a symlink - copy the target
            cp -rL "$file" "$target_dir/" 2>/dev/null || echo "  ⚠️  Could not backup $file"
            echo "  📄 $(basename "$file") (symlink target)"
        else
            # It's a regular file/directory
            cp -r "$file" "$target_dir/" 2>/dev/null || echo "  ⚠️  Could not backup $file"
            echo "  📄 $(basename "$file")"
        fi
    fi
done

# Backup current system state information
print_step "Backing up system information..."

# Nix Darwin generation info
if command -v darwin-version > /dev/null 2>&1; then
    darwin-version > "$BACKUP_DIR/darwin-version.txt" 2>/dev/null
    echo "  📋 Darwin version info"
fi

# Homebrew package list
if command -v brew > /dev/null 2>&1; then
    brew list --cask > "$BACKUP_DIR/brew-casks.txt" 2>/dev/null || true
    brew list --formula > "$BACKUP_DIR/brew-formulas.txt" 2>/dev/null || true
    echo "  📋 Homebrew package lists"
fi

# System information
sw_vers > "$BACKUP_DIR/system-version.txt" 2>/dev/null
echo "  📋 System version info"

# Create a restore script
print_step "Creating restore script..."
cat > "$BACKUP_DIR/restore.sh" << 'EOF'
#!/bin/bash
echo "🔄 Dotfiles Restore Script"
echo "This script will help restore your backed-up configurations."
echo
echo "⚠️  WARNING: This will overwrite current configurations!"
echo "   Make sure you understand what you're restoring."
echo
read -p "Do you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Restore cancelled."
    exit 1
fi

echo "📁 Backup contents:"
ls -la
echo
echo "📝 To manually restore files:"
echo "   - Copy files from this backup to your home directory"
echo "   - Be careful not to overwrite newer configurations"
echo "   - Consider using 'stow --adopt' for managed dotfiles"
echo
echo "🚀 To restore the full dotfiles setup:"
echo "   1. Clone the dotfiles repository to ~/.dotfiles"
echo "   2. Run the setup script: ~/.dotfiles/setup.sh"
echo "   3. Manually copy any custom configurations from this backup"
EOF

chmod +x "$BACKUP_DIR/restore.sh"

# Create backup summary
print_step "Creating backup summary..."
cat > "$BACKUP_DIR/README.md" << EOF
# Dotfiles Backup - $TIMESTAMP

This backup was created on $(date) for user: $USER

## Contents

### Dotfiles
- Shell configurations (.zprofile, .zshrc)
- Git configuration (.gitconfig, .gitignore_global)
- Editor configurations (.ideavimrc)
- Development tools (.docker/, .claude/)

### System Information
- \`darwin-version.txt\`: Nix Darwin generation info
- \`brew-casks.txt\`: Installed Homebrew casks
- \`brew-formulas.txt\`: Installed Homebrew formulas
- \`system-version.txt\`: macOS version information

### Restore Options

1. **Full Setup**: Use the main dotfiles repository setup script
2. **Manual Restore**: Copy specific files from this backup
3. **Partial Restore**: Use \`restore.sh\` for guided restoration

## Notes

- Symlinked files have been resolved to their targets
- This backup captures the state at the time of creation
- Always review configurations before restoring to avoid conflicts

EOF

print_success "Backup completed successfully!"
echo
echo "📍 Backup location: $BACKUP_DIR"
echo "📋 Backup size: $(du -sh "$BACKUP_DIR" | cut -f1)"
echo
echo "💡 Next steps:"
echo "  - Review the backup contents in: $BACKUP_DIR"
echo "  - Run the restore script if needed: $BACKUP_DIR/restore.sh"
echo "  - Consider archiving old backups to save space"