# Machine Migration Guide

How to move from an old machine to a new one using this repo — without
Migration Assistant, without cloning disks, and without carrying years of
cruft. OS-agnostic by design: the model below was validated live on two
macOS→macOS cutovers (July 2026 over a Thunderbolt cable, ~4h total; September
2026 onto a re-formatted machine over Wi-Fi: repo-first bootstrap, then ~50 GB
of rsync in 23 minutes). Nothing in it is Mac-specific except the transport
notes.

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

## Repo-first bootstrap (when the state layer itself lives in repos)

If your dotfiles are under chezmoi, your AI-assistant memory is a private git
repo and your tooling comes from this repo's manifests, the new machine can
know who you are from the network alone, before any cable or rsync:

1. Package manager, `git` and `gh`; `gh auth login` over HTTPS (no ssh key is
   needed for GitHub).
2. `git clone` the memory vault into place.
3. `chezmoi init <dotfiles-repo>` then `chezmoi apply` (exclude encrypted files
   until their key is on the machine).
4. `git clone` this repo → `./setup.sh <profile>` (dry-run first).
5. Only then rsync what no repo covers: working trees (with their stashes and
   local branches), app state, shell history.

September 2026 numbers: the AI assistant was usable on the new machine after
~20 minutes; the 50 GB rsync ran afterwards, unattended, while `setup.sh`
finished.

## The fresh-stack rule (what NOT to copy even though you could)

Language runtimes and their libraries are *version*, not *authorship*: an R
package library, a `uv` tool venv, `node_modules`, a `python@3.12` next to
3.14. Reinstall them from the manifests on the new machine, at the latest
versions, and copy only what you authored: editor settings, AI-assistant
config, skills and agents, shell config. Copying old installs migrates entropy
and pins the new machine to yesterday's versions.

## The git-resolve rule (what NOT to rsync)

- **Working trees travel by rsync** — it preserves local branches, stashes,
  untracked files and hooks that a fresh `git clone` would lose. Exclude
  the derivable weight: `node_modules/`, `.venv/`, `target/`, `dist/`,
  caches.
- **Bloated repos re-clone instead**: when `.git` history is most of the
  size and the remote is the source of truth, a fresh clone beats moving
  gigabytes of pack files (September 2026: an 18.6 GiB clone at 26 MB/s
  instead of a 30 GiB copy).
- **Derived data re-downloads**: browser profiles, Docker images, model
  weights, video caches. Sign in / re-pull; don't ship.

## Transport

Anything that carries ssh works. Ranked by speed: Thunderbolt/USB4 cable
(the two machines form an IP bridge; 100+ MB/s), wired LAN, Wi-Fi (~36 MB/s
in September 2026: 50 GB in 23 minutes). The pattern that works best:
**push from the old machine** (where the data and the context live) into
the new one's sshd. A cable also solves the "how do I safely move private
keys" question — it never touches a network you don't own.

A USB-C *charging* cable, even one with a wattage display, does not bridge
two Macs: only a Thunderbolt/USB4 cable creates the IP link. Check
`ifconfig bridge0` before planning around the cable.

## Downloads does not migrate

`~/Downloads` is a buffer, not a place. Triage it before the move: project
folders and personal documents go to `~/Documents/<Project>/` (which does
travel), installers and hash-identical duplicates go to the trash, sensitive
raw data stays on the old machine, and the old rest stays behind. Hash before
deleting a duplicate; same name and size are not enough. Keep a `src|dst` log
of every move so a mistake is reversible in one loop.

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
- **Migration Assistant appears on both machines** as soon as a fresh Mac
  reaches its setup wizard. Answer "Not Now": it copies all three layers as
  one opaque blob (September 2026 estimate: ~350 GB against 50 GB curated).
  It stays available later in Utilities if you ever change your mind.
- **A re-formatted machine keeps its hostname but not its host key.** `ssh`
  refuses with "REMOTE HOST IDENTIFICATION HAS CHANGED". Verify the new
  fingerprint out of band (`ssh-keyscan -t ed25519 host | ssh-keygen -lf -`),
  then `ssh-keygen -R host` and reconnect.
- **TCC-protected bundles make rsync return 23** (the Photos library, Apple's
  private plists under `~/Library/Preferences`). Exclude them: iCloud Photos
  rebuilds the library, and those plists must not travel anyway. Treat exit
  23/24 as "partial: inspect the log", not as a hard failure.
- **A symlink into a synced cloud folder turns `mv` into publishing.**
  `~/Documents/<Institution>` pointing at a shared drive means anything you
  "organize" into it is shared with the team seconds later. Resolve every
  destination with `pwd -P` and refuse anything under `CloudStorage`, Google
  Drive, OneDrive, Dropbox or iCloud. `dust` and `fd` hide symlinks; `ls -la`
  shows them.
- **Homebrew ≥ 7 ignores untrusted third-party taps silently.** A fresh
  machine has trusted nothing, so tap-qualified entries are skipped while the
  run looks successful. `setup.sh` 5.7.0+ taps and trusts every tap referenced
  by the manifests; do the same by hand for anything outside them
  (`brew trust --tap user/repo`).
- **A core formula can shadow the tool you meant.** homebrew/core `rig` is a
  fake-identity generator, not the R version manager. Read `brew info` before
  adding a bare name, and prefer the upstream's own installer when its tap
  does not load.
- **Keep the old machine intact** as a powered-off mirror for a while. It
  is the only rollback you need — and it costs nothing.

## Cross-OS boundary

The three-layer model holds for Linux↔macOS in both directions (POSIX +
rsync + the same profiles in this repo). Windows is deliberately a separate
path: no native rsync, different ACLs and shells — the Reproduce layer works
(`setup.ps1`), but the Sync layer needs another transport. Treat it as a
future extension, not a small variation.
