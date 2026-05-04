#!/usr/bin/env bash
# tools/macos-inventory.sh — read-only macOS inventory for migration / audit
#
# Purpose: capture the complete software/config state of a macOS system into
# a versioned-but-gitignored snapshot directory. Use cases:
#   1. Migration to a new Mac — diff against data/packages/*.txt to curate
#      what to actually keep.
#   2. Periodic audit — detect drift between installed state and declared lists.
#   3. Onboarding — share a sanitized snapshot to demonstrate environment.
#
# This is a MANUAL tool (per CLAUDE.md: "NO CI/CD Automation"). Run it yourself:
#
#     bash tools/macos-inventory.sh
#
# Output: .migration/<hostname>-snapshot/<NN-category>.txt   (gitignored)
#
# Guarantees:
#   - read-only        no mutations, no sudo, no network, no symlinks
#   - idempotent       re-running overwrites prior snapshot for same host
#   - tolerant         missing tools logged, never fatal
#   - bash 3.2 compat  works on stock macOS bash
#
# Exit codes:
#   0  inventory completed (some captures may be skipped)
#   1  fatal error (cannot create snapshot dir / wrong OS)

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "ERROR: macos-inventory.sh is macOS only (detected: $(uname -s))" >&2
    exit 1
fi

HOSTNAME_SHORT="$(hostname -s 2>/dev/null || echo unknown)"
SNAPSHOT_DIR="$REPO_ROOT/.migration/${HOSTNAME_SHORT}-snapshot"
TIMESTAMP="$(date '+%Y-%m-%dT%H:%M:%S%z')"

mkdir -p "$SNAPSHOT_DIR" || {
    echo "ERROR: cannot create $SNAPSHOT_DIR" >&2
    exit 1
}

# Colors (TTY only)
if [[ -t 1 ]]; then
    GREEN=$'\033[1;32m'; YELLOW=$'\033[1;33m'; CYAN=$'\033[1;36m'
    DIM=$'\033[2m'; NC=$'\033[0m'
else
    GREEN=""; YELLOW=""; CYAN=""; DIM=""; NC=""
fi

ok()   { printf "${GREEN}  ✓${NC} %-34s ${DIM}%s${NC}\n" "$1" "$2"; }
skip() { printf "${YELLOW}  ⊘${NC} %-34s ${DIM}%s${NC}\n" "$1" "$2"; }

write_header() {
    local file="$1" desc="$2" cmd="$3"
    {
        echo "# $desc"
        echo "# Captured: $TIMESTAMP"
        echo "# Host:     $HOSTNAME_SHORT"
        [[ -n "$cmd" ]] && echo "# Command:  $cmd"
        echo "# ---"
    } > "$file"
}

# Capture a simple command; skip cleanly if not installed
capture_cmd() {
    local file="$1" desc="$2"
    shift 2
    local out="$SNAPSHOT_DIR/$file"
    write_header "$out" "$desc" "$*"
    if command -v "$1" >/dev/null 2>&1; then
        "$@" >> "$out" 2>&1 || true
        ok "$file" "$1"
    else
        echo "(command not found: $1)" >> "$out"
        skip "$file" "$1 not installed"
    fi
}

# Strip headers and blanks from inventory files for diffing
strip_meta() { grep -vE '^(#|$)' "$1" 2>/dev/null; }

echo
printf "${CYAN}=== macOS inventory ===${NC}\n"
echo "Snapshot dir: $SNAPSHOT_DIR"
echo "Started:      $TIMESTAMP"
echo

# ---------- 00 system ----------
{
    write_header "$SNAPSHOT_DIR/00-system.txt" "System identification" ""
    echo "## uname"; uname -a
    echo
    echo "## sw_vers"; sw_vers 2>/dev/null
    echo
    echo "## arch"; arch
    echo
    echo "## CPU"; sysctl -n machdep.cpu.brand_string 2>/dev/null
    echo
    echo "## RAM (bytes)"; sysctl -n hw.memsize 2>/dev/null
} >> "$SNAPSHOT_DIR/00-system.txt"
ok "00-system.txt" "uname/sw_vers/sysctl"

# ---------- 10..13 brew ----------
if command -v brew >/dev/null 2>&1; then
    capture_cmd "10-brew-leaves.txt"               "Top-level brew formulae"        brew leaves
    capture_cmd "11-brew-installed-on-request.txt" "Explicitly installed formulae"  brew list --installed-on-request
    {
        write_header "$SNAPSHOT_DIR/12-brew-cask.txt" "Brew cask apps with versions" "brew list --cask --versions"
        brew list --cask --versions 2>&1 || true
    } >> "$SNAPSHOT_DIR/12-brew-cask.txt"
    ok "12-brew-cask.txt" "brew cask"
    {
        write_header "$SNAPSHOT_DIR/13-Brewfile" "Portable Brewfile" "brew bundle dump --describe"
        brew bundle dump --describe --file=- 2>&1 || true
    } >> "$SNAPSHOT_DIR/13-Brewfile"
    ok "13-Brewfile" "brew bundle dump"
else
    skip "10..13 brew*" "brew not installed"
fi

# ---------- 20..21 apps ----------
capture_cmd "20-mas.txt" "Mac App Store apps" mas list

{
    write_header "$SNAPSHOT_DIR/21-applications.txt" "Standalone applications" "ls /Applications + ~/Applications"
    echo "## /Applications"
    ls "/Applications" 2>/dev/null | sort
    echo
    echo "## ~/Applications"
    ls "$HOME/Applications" 2>/dev/null | sort
} >> "$SNAPSHOT_DIR/21-applications.txt"
ok "21-applications.txt" "ls Applications"

# ---------- 30..36 CLI globals ----------
capture_cmd "30-cargo.txt"       "Rust globals (cargo install)" cargo install --list
capture_cmd "31-npm-global.txt"  "npm globals"                  npm ls -g --depth=0
capture_cmd "32-pnpm-global.txt" "pnpm globals"                 pnpm ls -g --depth=0
capture_cmd "33-bun-global.txt"  "bun globals"                  bun pm ls -g
capture_cmd "34-pipx.txt"        "pipx isolated apps"           pipx list
capture_cmd "35-uv-tools.txt"    "uv tools"                     uv tool list

{
    write_header "$SNAPSHOT_DIR/36-go-bin.txt" "Go-installed binaries" "ls \$GOPATH/bin"
    if command -v go >/dev/null 2>&1; then
        gopath="$(go env GOPATH 2>/dev/null)"
        if [[ -n "$gopath" && -d "$gopath/bin" ]]; then
            ls -la "$gopath/bin" 2>/dev/null
        else
            echo "(no GOPATH/bin)"
        fi
    else
        echo "(go not installed)"
    fi
} >> "$SNAPSHOT_DIR/36-go-bin.txt"
ok "36-go-bin.txt" "go binaries"

# ---------- 40 runtimes & version managers ----------
{
    write_header "$SNAPSHOT_DIR/40-runtimes.txt" "Language runtime versions" ""
    echo "## interpreters"
    for cmd in python python3 node bun deno ruby go rustc; do
        if command -v "$cmd" >/dev/null 2>&1; then
            v=$("$cmd" --version 2>&1 | head -n1)
            printf "%-10s %s\n" "$cmd" "$v"
        fi
    done
    echo
    echo "## version managers"
    for vm in mise asdf fnm pyenv rbenv; do
        if command -v "$vm" >/dev/null 2>&1; then
            echo "[$vm]"
            case "$vm" in
                mise|asdf) "$vm" ls 2>&1 | head -50 ;;
                fnm)       "$vm" list 2>&1 ;;
                pyenv)     "$vm" versions 2>&1 ;;
                rbenv)     "$vm" versions 2>&1 ;;
            esac
            echo
        fi
    done
} >> "$SNAPSHOT_DIR/40-runtimes.txt"
ok "40-runtimes.txt" "runtimes + version mgrs"

# ---------- 42 drift vs package lists ----------
{
    write_header "$SNAPSHOT_DIR/42-drift-vs-packages.txt" \
        "Drift between installed state and data/packages/*.txt" ""

    cmp_lists() {
        local label="$1" installed_file="$2" listed_file="$3"
        echo
        echo "## $label"
        if [[ ! -f "$installed_file" ]]; then
            echo "(no inventory file: $installed_file)"
            return
        fi
        if [[ ! -f "$listed_file" ]]; then
            echo "(no package list: $listed_file)"
            return
        fi
        echo "### Installed but NOT in $(basename "$listed_file"):"
        comm -23 <(strip_meta "$installed_file" | awk '{print $1}' | sort -u) \
                 <(grep -vE '^\s*(#|$)' "$listed_file" | sort -u)
        echo
        echo "### In $(basename "$listed_file") but NOT installed:"
        comm -13 <(strip_meta "$installed_file" | awk '{print $1}' | sort -u) \
                 <(grep -vE '^\s*(#|$)' "$listed_file" | sort -u)
    }

    cmp_lists "brew formulae (base)"      "$SNAPSHOT_DIR/10-brew-leaves.txt" "$REPO_ROOT/data/packages/brew.txt"
    cmp_lists "brew casks (developer)"    "$SNAPSHOT_DIR/12-brew-cask.txt"   "$REPO_ROOT/data/packages/brew-cask-developer.txt"
    # cargo: Rust tools moved to data/packages.csv (Onda 5) — diff vs CSV is non-trivial; skip here
} >> "$SNAPSHOT_DIR/42-drift-vs-packages.txt"
ok "42-drift-vs-packages.txt" "diff vs data/packages"

# ---------- 50..51 editor extensions ----------
capture_cmd "50-vscode-extensions.txt" "VSCode extensions" code --list-extensions
capture_cmd "51-cursor-extensions.txt" "Cursor extensions" cursor --list-extensions

# ---------- 60 MCPs ----------
capture_cmd "60-mcp-list.txt" "MCP Launchpad servers" mcpl list

# ---------- 70..73 macOS defaults ----------
{
    write_header "$SNAPSHOT_DIR/70-defaults-domains.txt" "Customized defaults domains" "defaults domains"
    defaults domains 2>/dev/null | tr ',' '\n' | sed 's/^ *//' | sort
} >> "$SNAPSHOT_DIR/70-defaults-domains.txt"
ok "70-defaults-domains.txt" "defaults domains"

{
    write_header "$SNAPSHOT_DIR/71-defaults-key-domains.txt" "Key domain dumps" ""
    for domain in NSGlobalDomain com.apple.dock com.apple.finder com.apple.HIToolbox \
                  com.apple.symbolichotkeys com.apple.universalaccess \
                  com.apple.menuextra.clock com.apple.screencapture com.apple.spaces; do
        echo "## $domain"
        defaults read "$domain" 2>/dev/null || echo "(empty or unreadable)"
        echo
    done
} >> "$SNAPSHOT_DIR/71-defaults-key-domains.txt"
ok "71-defaults-key-domains.txt" "defaults read"

{
    write_header "$SNAPSHOT_DIR/72-loginitems.txt" "Login items" "osascript"
    osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null \
        | tr ',' '\n' | sed 's/^[ ,]*//' \
        || echo "(unable to read; may need automation permission)"
} >> "$SNAPSHOT_DIR/72-loginitems.txt"
ok "72-loginitems.txt" "login items"

{
    write_header "$SNAPSHOT_DIR/73-dock-persistent.txt" "Dock persistent apps" "defaults read com.apple.dock"
    defaults read com.apple.dock persistent-apps 2>/dev/null \
        | grep '"file-label"' | sed 's/.*= "//;s/";//' | sort -u \
        || echo "(none)"
} >> "$SNAPSHOT_DIR/73-dock-persistent.txt"
ok "73-dock-persistent.txt" "dock layout"

# ---------- 80 fonts ----------
{
    write_header "$SNAPSHOT_DIR/80-fonts-user.txt" "User-installed fonts" "ls ~/Library/Fonts"
    ls "$HOME/Library/Fonts" 2>/dev/null | sort || echo "(none)"
} >> "$SNAPSHOT_DIR/80-fonts-user.txt"
ok "80-fonts-user.txt" "user fonts"

# ---------- 90..91 secrets metadata only (NEVER content) ----------
{
    write_header "$SNAPSHOT_DIR/90-ssh-list.txt" "SSH key file names (NOT contents)" "ls ~/.ssh"
    if [[ -d "$HOME/.ssh" ]]; then
        ls -1 "$HOME/.ssh" 2>/dev/null | sort
    else
        echo "(no ~/.ssh)"
    fi
} >> "$SNAPSHOT_DIR/90-ssh-list.txt"
ok "90-ssh-list.txt" "ssh metadata"

capture_cmd "91-gpg-keys.txt" "GPG secret keys (IDs only, no key material)" \
    gpg --list-secret-keys --keyid-format LONG

# ---------- 99 zsh history (top commands) ----------
{
    write_header "$SNAPSHOT_DIR/99-zsh-history-top100.txt" "Top 100 commands from ~/.zsh_history" ""
    if [[ -f "$HOME/.zsh_history" ]]; then
        echo "## Top 100 first-words (proxy for command frequency)"
        # zsh extended history format: ': <ts>:<dur>;<cmd>' — strip metadata, take first token
        LC_ALL=C awk -F';' '
            /^: [0-9]+:/ { sub(/^[^;]*;/, ""); print; next }
            { print }
        ' "$HOME/.zsh_history" 2>/dev/null \
            | LC_ALL=C awk '{print $1}' \
            | LC_ALL=C sort \
            | LC_ALL=C uniq -c \
            | LC_ALL=C sort -rn \
            | head -100
    else
        echo "(no ~/.zsh_history)"
    fi
} >> "$SNAPSHOT_DIR/99-zsh-history-top100.txt"
ok "99-zsh-history-top100.txt" "history top 100"

# ---------- summary ----------
echo
total=$(find "$SNAPSHOT_DIR" -type f | wc -l | tr -d ' ')
size=$(du -sh "$SNAPSHOT_DIR" 2>/dev/null | awk '{print $1}')
printf "${CYAN}✓ Inventory complete${NC}\n"
echo "  Files: $total"
echo "  Size:  $size"
echo "  Path:  $SNAPSHOT_DIR"
echo
echo "Next: review the .txt files manually, or run a curation pass."
echo
