# Machine Migration Guide

How to move from an old machine to a new one using this repo — without
Migration Assistant, without cloning disks, and without carrying years of
cruft. OS-agnostic by design: the model below was validated live on a
macOS→macOS cutover (~4h total, ~10 min of actual transfer), but nothing in
it is Mac-specific except the transport notes.

The core idea: **a machine is three layers, and each layer travels
differently.**

## The three layers

| Layer | What it is | How it travels |
|-------|-----------|----------------|
| **Reproduce** | Apps, packages, tools | It doesn't — the new machine runs `./setup.sh <profile>` and rebuilds it from the manifests. Never copy programs. |
| **Sync** | The irreducible state: SSH keys, shell history, app state, working directories, personal configs | `rsync` over ssh, old machine → new. This is the only layer that actually moves. |
| **Re-auth** | Credentials, tokens, `.env`, logins | Never copied. Re-authenticate on the new machine, service by service, on first use. |

If something feels hard to classify, ask: *could I regenerate it from a
manifest or a remote?* Yes → Reproduce. *Is it a secret?* → Re-auth.
Everything else → Sync.

## The order that makes it painless: continuity first

Sync the identity/state layer **before** installing anything beyond a
minimal bootstrap (git + package manager + this repo). Result: the new
machine "knows who you are" — editor state, AI-assistant memory, shell
history, keys — while the package install runs unattended in parallel.

1. **New machine:** enable Remote Login (sshd), get the old machine's
   public key into `~/.ssh/authorized_keys` (send it as a FILE — see
   pitfalls).
2. **Old machine:** push the state layer with rsync (dotfiles, `~/.ssh`
   minus `authorized_keys`, histories, app-state dirs, working dirs).
3. **New machine:** bootstrap (package manager + `git clone` this repo),
   then `./setup.sh <profile>` — dry-run first if you want the preview.
4. Re-auth as you start using things. Done.

## The git-resolve rule (what NOT to rsync)

- **Working trees travel by rsync** — it preserves local branches, stashes,
  untracked files and hooks that a fresh `git clone` would lose. Exclude
  the derivable weight: `node_modules/`, `.venv/`, `target/`, `dist/`,
  caches.
- **Bloated repos re-clone instead**: when `.git` history is most of the
  size and the remote is the source of truth, a fresh clone beats moving
  gigabytes of pack files.
- **Derived data re-downloads**: browser profiles, Docker images, model
  weights, video caches. Sign in / re-pull; don't ship.

## Transport

Anything that carries ssh works. Ranked by speed: Thunderbolt/USB4 cable
(the two machines form an IP bridge; 100+ MB/s), wired LAN, Wi-Fi. The
pattern that works best: **push from the old machine** (where the data and
the context live) into the new one's sshd. A cable also solves the "how do
I safely move private keys" question — it never touches a network you don't
own.

## Pitfalls that will bite you (all field-tested)

- **GUI clipboard between machines corrupts shell blocks** (smart quotes,
  broken newlines, `dquote>` prompts). Ship scripts as files and run
  `bash file.sh`; never paste multi-line blocks across machines.
- **A passphrase-protected SSH key without an agent/keychain breaks every
  non-interactive client** — and the debug output misleads you toward the
  server. Load it into the agent/keychain once per machine, in a real TTY.
- **macOS gates SSH by group** (`com.apple.access_ssh`) *before* checking
  keys: `Permission denied` may have nothing to do with your key.
- **Cloud file sync must stay off during the move** (e.g. iCloud
  Desktop & Documents relocates `~/Desktop`/`~/Documents` into its
  container, changing the paths rsync targets). Re-enable selectively after.
- **sudo-gated installers fail (correctly) in unattended runs** — collect
  them and do one interactive pass at the end.
- **Keep the old machine intact** as a powered-off mirror for a while. It
  is the only rollback you need — and it costs nothing.

## Cross-OS boundary

The three-layer model holds for Linux↔macOS in both directions (POSIX +
rsync + the same profiles in this repo). Windows is deliberately a separate
path: no native rsync, different ACLs and shells — the Reproduce layer works
(`setup.ps1`), but the Sync layer needs another transport. Treat it as a
future extension, not a small variation.
