#!/usr/bin/env bash
#
# install.sh — Setup or refresh symlinks from provider outputs to their expected locations.
#
# Usage:
#   install.sh --full      First-time setup (backup existing + create symlinks)
#   install.sh --refresh   Refresh symlinks only (no backup)
#
# This script is idempotent — safe to run multiple times.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
MODE="${1:---refresh}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[]{NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }

# Backup a file/dir before replacing with symlink
backup_if_exists() {
    local target="$1"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        local backup="${target}.bak.$(date +%Y%m%d_%H%M%S)"
        mv "$target" "$backup"
        warn "Backed up $target → $backup"
    fi
}

# Create a symlink, removing existing symlink if present
link() {
    local src="$1"
    local dest="$2"

    if [ ! -e "$src" ]; then
        error "Source does not exist: $src"
        return 1
    fi

    if [ "$MODE" = "--full" ]; then
        backup_if_exists "$dest"
    fi

    # Remove existing symlink
    if [ -L "$dest" ]; then
        rm "$dest"
    fi

    # Create parent directory
    mkdir -p "$(dirname "$dest")"

    ln -sfn "$src" "$dest"
    info "Linked: $dest → $src"
}

echo "================================================"
echo "  AgentSkills Installer ($MODE)"
echo "================================================"
echo ""

# ─── CODEX SKILLS ───────────────────────────────────────────
echo "── Codex Skills ──"
CODEX_SKILLS_DIR="$HOME/.codex/skills"
mkdir -p "$CODEX_SKILLS_DIR"

if [ -d "$REPO_DIR/providers/codex" ]; then
    for skill_dir in "$REPO_DIR/providers/codex"/*/; do
        if [ -d "$skill_dir" ]; then
            skill_name="$(basename "$skill_dir")"
            link "$skill_dir" "$CODEX_SKILLS_DIR/$skill_name"
        fi
    done
fi
echo ""

# ─── KIRO STEERING + SKILLS ────────────────────────────────
echo "── Kiro ──"
KIRO_DIR="$HOME/.kiro"
mkdir -p "$KIRO_DIR"

if [ -d "$REPO_DIR/providers/kiro/steering" ]; then
    link "$REPO_DIR/providers/kiro/steering" "$KIRO_DIR/steering"
fi

if [ -d "$REPO_DIR/providers/kiro/skills" ]; then
    link "$REPO_DIR/providers/kiro/skills" "$KIRO_DIR/skills"
fi
echo ""

# ─── CLAUDE CODE ────────────────────────────────────────────
echo "── Claude Code ──"
if [ -f "$REPO_DIR/providers/claude-code/CLAUDE.md" ]; then
    link "$REPO_DIR/providers/claude-code/CLAUDE.md" "$HOME/CLAUDE.md"
fi
echo ""

# ─── COPILOT ────────────────────────────────────────────────
echo "── Copilot ──"
mkdir -p "$HOME/.github"
if [ -f "$REPO_DIR/providers/copilot/copilot-instructions.md" ]; then
    link "$REPO_DIR/providers/copilot/copilot-instructions.md" "$HOME/.github/copilot-instructions.md"
fi
echo ""

# ─── SHELL ──────────────────────────────────────────────────
echo "── Shell ──"
if [ -f "$REPO_DIR/shell/zshrc" ]; then
    link "$REPO_DIR/shell/zshrc" "$HOME/.zshrc"
fi
if [ -f "$REPO_DIR/shell/bashrc" ]; then
    link "$REPO_DIR/shell/bashrc" "$HOME/.bashrc"
fi
echo ""

# ─── SOURCE AGENT COMMANDS ──────────────────────────────────
echo "── Agent Commands ──"
if [ -f "$REPO_DIR/shell/agent-commands.sh" ]; then
    # Ensure agent-commands.sh is sourced in current shell configs
    AGENT_SOURCE_LINE="source \"$REPO_DIR/shell/agent-commands.sh\""

    # Check zshrc
    if [ -f "$HOME/.zshrc" ] && ! grep -qF "agent-commands.sh" "$HOME/.zshrc" 2>/dev/null; then
        echo "" >> "$HOME/.zshrc"
        echo "# AgentSkills commands" >> "$HOME/.zshrc"
        echo "$AGENT_SOURCE_LINE" >> "$HOME/.zshrc"
        info "Added agent-commands.sh source to .zshrc"
    fi

    # Check bashrc
    if [ -f "$HOME/.bashrc" ] && ! grep -qF "agent-commands.sh" "$HOME/.bashrc" 2>/dev/null; then
        echo "" >> "$HOME/.bashrc"
        echo "# AgentSkills commands" >> "$HOME/.bashrc"
        echo "$AGENT_SOURCE_LINE" >> "$HOME/.bashrc"
        info "Added agent-commands.sh source to .bashrc"
    fi
fi
echo ""

echo "================================================"
echo "  Installation complete!"
echo "  Run: source ~/.zshrc (or restart shell)"
echo "================================================"
