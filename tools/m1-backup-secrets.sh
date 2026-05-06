#!/usr/bin/env bash
#######################################
# tools/m1-backup-secrets.sh
#
# Builds a focused backup tarball of the secrets that don't regenerate on
# a fresh machine: SSH keys, GPG ring, Claude Code configs/commands/plugins.
#
# Excludes:
#   - .claude/projects     (session jsonl logs — regenerate as you work)
#   - .claude/file-history (per-file edit history — recoverable from git)
#   - .claude/paste-cache  (transient paste buffer)
#   - Library/.../Claude   (entire dir — Claude Desktop app data, ~9GB,
#                           rebuilt automatically on first launch)
#
# Output: ~/m1-backup/secrets-YYYY-MM-DD.tar.gz
#
# Upload that file to Bitwarden as a secure-note attachment, alongside the
# atuin encryption key. Restore on M5 with:
#   tar xzf secrets-YYYY-MM-DD.tar.gz -C ~/
#######################################

set -u
set -o pipefail

DATE_TAG="$(date +%F)"
OUT_DIR="${HOME}/m1-backup"
OUT_FILE="${OUT_DIR}/secrets-${DATE_TAG}.tar.gz"

mkdir -p "$OUT_DIR"

# Remove any prior tarball from today so we start clean.
[[ -f "$OUT_FILE" ]] && rm -f "$OUT_FILE"

echo "Building backup tarball..."
echo "  Output: $OUT_FILE"
echo "  Including: ~/.claude (filtered), ~/.ssh, ~/.gnupg"
echo "  Excluding: .claude/projects, .claude/file-history, .claude/paste-cache"
echo

cd "$HOME" || exit 1

# Notes on excludes:
#   - .ssh/agent and .gnupg/S.* are Unix sockets; BSD tar can't archive
#     them ("pax format cannot archive sockets") and the error aborts the
#     whole tarball. Both are runtime sockets, regenerated when ssh-agent /
#     gpg-agent start on the new machine — safe to skip.
tar czf "$OUT_FILE" \
    --exclude='.claude/projects' \
    --exclude='.claude/file-history' \
    --exclude='.claude/paste-cache' \
    --exclude='.ssh/agent' \
    --exclude='.gnupg/S.*' \
    --exclude='.gnupg/*.sock' \
    .claude .ssh .gnupg

rc=$?
if (( rc != 0 )); then
    echo "ERROR: tar exited with code $rc" >&2
    exit "$rc"
fi

echo
echo "Backup complete:"
ls -lh "$OUT_FILE"
echo
echo "Next steps:"
echo "  1) Upload $OUT_FILE to Bitwarden as a secure-note attachment."
echo "  2) Save the atuin encryption key in the same note (24 BIP39 words)."
echo "  3) On M5: tar xzf <file> -C ~/  to restore."
