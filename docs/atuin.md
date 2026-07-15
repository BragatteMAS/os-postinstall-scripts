# Persistent Shell History with Atuin (optional)

End-to-end encrypted shell history that syncs across machines via the Atuin
Hub. Ctrl+R becomes a fuzzy-search TUI over your full history with
cwd/exit-code/duration metadata.

> **Positioning:** atuin is OPTIONAL and not part of any profile's default
> flow. For machine-to-machine moves, the project default is plain-file
> history transfer (`~/.zsh_history` via rsync — see
> [`migration-guide.md`](migration-guide.md)). Use atuin if you want
> continuous multi-machine sync and are comfortable managing its encryption
> key.

## TL;DR — first-time setup

```sh
brew install atuin
atuin register -u <your-username>          # opens browser; Atuin Hub OAuth
cat ~/.local/share/atuin/key                # COPY → password vault (24-word BIP39)
echo 'eval "$(atuin init zsh)"' >> ~/.zshrc
exec zsh -l                                 # reload shell so atuin init takes effect
atuin import zsh                            # or: atuin import bash, atuin import fish
atuin sync
atuin status                                # confirm "Last sync: <current time>"
```

**Save in your password vault** (text-only, fits free Bitwarden):

- Atuin Hub username + password
- 24 BIP39 words from `cat ~/.local/share/atuin/key`
- Server: `https://api.atuin.sh`

## Why save the encryption key

Atuin is end-to-end encrypted. The server stores ciphertext only; **your key
never leaves your machine**. Lose the key → lose access to your history on
other machines. There is no recovery — it's mathematics.

## Restoring on a new machine

After running `setup.sh` (atuin is in `csv:rust-shell`):

```sh
atuin login -u <your-username>     # asks for password + key (24 words from vault)
eval "$(atuin init zsh)"
atuin sync                         # pulls history from server

# make persistent:
echo 'eval "$(atuin init zsh)"' >> ~/.zshrc
```

Ctrl+R now sees the history from the old machine.

## Common gotchas

| Symptom | Cause | Fix |
|---|---|---|
| `Already authenticated with Atuin Hub` | Already registered on this host | Proceed to saving the key |
| `Failed to find $ATUIN_SESSION` | atuin init not loaded in current shell | `eval "$(atuin init zsh)" && atuin sync` |
| `atuin import auto` does nothing | `$HISTFILE` not exported | Pass shell explicitly: `atuin import zsh` |
| `Last sync: 1969-12-31` | Never synced (epoch zero) | Run `atuin sync` (atuin init must be loaded first) |
| Ctrl+R opens Warp's command search | Warp captures Ctrl+R before zsh sees it | Warp Settings → Features → Session → remap "Command search" off `Ctrl+R` |
| `atuin key` seems empty | Output went too fast | `cat ~/.local/share/atuin/key` |

## Web UI shows nothing under sync history?

By design. Atuin Hub stores your shell history encrypted with a key that lives
only on your machine — the web UI cannot decrypt it. Verify sync via CLI:

```sh
atuin status                # Last sync timestamp
atuin search docker         # query that should return historical commands
```

The web UI's **Runbooks** tab is a separate feature — Jupyter-style command
notebooks you create deliberately. It's empty by default; nothing to do with
your synced history.

## Using atuin (after setup)

| Action | How |
|---|---|
| Open search | Ctrl+R (TUI fullscreen) |
| Filter | Type — fuzzy search incremental |
| Navigate | ↑ ↓ |
| Paste command (no execute) | Enter |
| Edit before executing | Tab |
| Close | Esc |
| Toggle global ↔ session-only | Ctrl+R (again, inside the TUI) |
