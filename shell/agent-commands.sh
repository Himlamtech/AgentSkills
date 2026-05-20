#!/usr/bin/env bash
#
# agent-commands.sh — CLI for managing AgentSkills across servers.
#
# Source this file in .zshrc or .bashrc:
#   source "$HOME/.agent-skills/shell/agent-commands.sh"
#
# Commands:
#   agent change [message]  — Transpile + commit + push changes to GitHub
#   agent update            — Pull from GitHub + transpile + refresh symlinks
#   agent install           — First-time clone + full setup
#   agent status            — Show git status of the repo
#   agent diff              — Show uncommitted changes
#   agent edit              — Open canonical/ in editor
#   agent list              — List all canonical skills and rules

AGENT_REPO="${AGENT_REPO:-$HOME/.agent-skills}"
AGENT_REMOTE="${AGENT_REMOTE:-origin}"
AGENT_BRANCH="${AGENT_BRANCH:-main}"

# Colors (works in both bash and zsh)
_ag_green()  { printf '\033[0;32m%s\033[0m\n' "$1"; }
_ag_yellow() { printf '\033[1;33m%s\033[0m\n' "$1"; }
_ag_red()    { printf '\033[0;31m%s\033[0m\n' "$1"; }

agent() {
    local cmd="${1:-help}"
    shift 2>/dev/null || true

    case "$cmd" in
        change)
            # Transpile + commit + push
            local msg="${*:-update: $(date +%Y-%m-%d_%H:%M:%S)}"

            if [ ! -d "$AGENT_REPO" ]; then
                _ag_red "Agent repo not found at $AGENT_REPO. Run: agent install"
                return 1
            fi

            _ag_green "→ Transpiling canonical/ → providers/..."
            python3 "$AGENT_REPO/transpile.py" || { _ag_red "Transpile failed"; return 1; }

            _ag_green "→ Committing changes..."
            git -C "$AGENT_REPO" add -A
            git -C "$AGENT_REPO" commit -m "$msg" 2>/dev/null || {
                _ag_yellow "Nothing to commit."
                return 0
            }

            _ag_green "→ Pushing to $AGENT_REMOTE/$AGENT_BRANCH..."
            git -C "$AGENT_REPO" push -u "$AGENT_REMOTE" "$AGENT_BRANCH" || {
                _ag_red "Push failed. Check your SSH key or network."
                return 1
            }

            _ag_green "✓ Changes pushed successfully."
            ;;

        update)
            # Pull + transpile + refresh symlinks
            if [ ! -d "$AGENT_REPO" ]; then
                _ag_red "Agent repo not found at $AGENT_REPO. Run: agent install"
                return 1
            fi

            _ag_green "→ Pulling latest from $AGENT_REMOTE/$AGENT_BRANCH..."
            git -C "$AGENT_REPO" pull --rebase "$AGENT_REMOTE" "$AGENT_BRANCH" || {
                _ag_red "Pull failed. Resolve conflicts manually."
                return 1
            }

            _ag_green "→ Transpiling canonical/ → providers/..."
            python3 "$AGENT_REPO/transpile.py" || { _ag_red "Transpile failed"; return 1; }

            _ag_green "→ Refreshing symlinks..."
            bash "$AGENT_REPO/install.sh" --refresh

            _ag_green "✓ Updated successfully."
            ;;

        install)
            # First-time setup
            if [ -d "$AGENT_REPO/.git" ]; then
                _ag_yellow "Repo already exists at $AGENT_REPO. Running update instead."
                agent update
                return $?
            fi

            local repo_url="${1:-git@github.com:Himlamtech/AgentSkills.git}"

            _ag_green "→ Cloning $repo_url → $AGENT_REPO..."
            git clone "$repo_url" "$AGENT_REPO" || {
                _ag_red "Clone failed. Check SSH key or URL."
                return 1
            }

            _ag_green "→ Transpiling..."
            python3 "$AGENT_REPO/transpile.py" || { _ag_red "Transpile failed"; return 1; }

            _ag_green "→ Running full install..."
            bash "$AGENT_REPO/install.sh" --full

            _ag_green "✓ Installation complete. Restart your shell or run: source ~/.zshrc"
            ;;

        status)
            git -C "$AGENT_REPO" status
            ;;

        diff)
            git -C "$AGENT_REPO" diff
            ;;

        edit)
            # Open in default editor
            local editor="${EDITOR:-vim}"
            "$editor" "$AGENT_REPO/canonical/"
            ;;

        list)
            echo ""
            _ag_green "═══ Canonical Skills ═══"
            for f in "$AGENT_REPO/canonical/skills"/*.md; do
                [ -f "$f" ] && echo "  • $(basename "$f" .md)"
            done
            echo ""
            _ag_green "═══ Canonical Rules ═══"
            for f in "$AGENT_REPO/canonical/rules"/*.md; do
                [ -f "$f" ] && echo "  • $(basename "$f" .md)"
            done
            echo ""
            _ag_green "═══ References ═══"
            for f in "$AGENT_REPO/canonical/references"/*.md; do
                [ -f "$f" ] && echo "  • $(basename "$f" .md)"
            done
            echo ""
            ;;

        help|*)
            echo ""
            echo "Usage: agent <command> [args]"
            echo ""
            echo "Commands:"
            echo "  change [msg]  Transpile + commit + push (default msg: timestamp)"
            echo "  update        Pull + transpile + refresh symlinks"
            echo "  install [url] First-time clone + full setup"
            echo "  status        Show git status"
            echo "  diff          Show uncommitted changes"
            echo "  edit          Open canonical/ in \$EDITOR"
            echo "  list          List all skills, rules, and references"
            echo "  help          Show this help"
            echo ""
            ;;
    esac
}
