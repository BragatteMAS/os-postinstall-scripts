# M5 Migration Runbook

> One-page operational checklist for migrating from M1 (current Mac) to M5
> (new Mac). Complement to `.migration/M5-MIGRATION-PLAN.md` (the strategy).
> This file: the **commands**, in order, with success criteria.
>
> Keep this open in a second window on the M1 while working on the M5.

---

## 0. Pre-conditions on **M1** (do *before* opening the M5 box)

- [ ] `atuin sync` ran on M1 (history would be lost otherwise)
      ```
      atuin sync
      ```
- [ ] Tarball of secrets/configs to Bitwarden vault (NOT 1Password):
      `~/.claude`, `~/.ssh`, `~/.gnupg`, GPG private keys, MCP configs
- [ ] Time Machine final backup completed (last sanity net)
- [ ] M5: stable network, **≥10 GiB free on /** (preflight will gate this)
- [ ] M5: iCloud Drive **OFF** until after §4 smoke test

---

## 1. Bootstrap (M5, ~5 min)

Open Terminal on a fresh user account. Skip Migration Assistant
(`Caminho D` strategy — tarball wins on collision).

```sh
xcode-select --install   # accept the prompt; wait for it to finish
mkdir -p ~/Documents/GitHub && cd ~/Documents/GitHub
git clone https://github.com/BragatteMAS/os-postinstall-scripts.git
cd os-postinstall-scripts
```

> **Stop here** if `git clone` fails — fix network/credentials before
> proceeding. Don't try to work around it.

---

## 2. Preflight (M5, ~2 min)

Two read-only validations, in this order:

```sh
bash tools/preflight-brew-names.sh
```

**Expected last line:** `[OK] All package names resolve.`

If it shows `[FAIL]` for any name → **STOP**. The cask/formula was
renamed or removed since the last commit. Open an issue, don't continue.

---

## 3. Install (M5, ~30 min for `full` profile)

```sh
bash setup.sh full
```

**Watch the live output for:**

| Line | Meaning |
|---|---|
| `[skip] X (already installed)` | Idempotent — fine, brew already has X |
| `[INFO] Summary (file.txt): N installed, M skipped, K failed` | End of each wave — failures should be 0 |
| `[ERROR] Failed to install: X (<reason>)` | Brew classified the failure; check the log |
| `[WARN] Completed with N failure(s)` (final summary) | Read failure list before closing the terminal |

**If failures appear**, look at the diagnostic log path printed in the
final summary (`Diagnostic log: /tmp/os-postinstall-XXXXXX/brew-install.log`)
and **copy it elsewhere immediately** — it lives inside `$TEMP_DIR`,
which is removed on script exit:

```sh
cp /tmp/os-postinstall-*/brew-install.log ~/m5-install-stderr.log
```

---

## 4. Terminal blueprint (M5, ~3 min — separate from setup.sh)

`setup.sh` installs packages; the terminal **look and behavior**
(Starship preset, MAS Oceanic theme, aliases bundle, zsh plugins) is
a separate one-script flow. Since v5.1.4 `setup.sh` prompts for it at
the end — but you can also run it standalone whenever:

```sh
bash terminal-setup.sh --interactive   # wizard — pick components
# or:
bash terminal-setup.sh                 # install everything
```

Use `--dry-run` to preview before applying.

---

## 5. Post-install verification (M5, ~5 min)

- [ ] Open a **new** terminal window (so dotfiles re-source)
- [ ] `which starship zoxide atuin` — all three should resolve
- [ ] `h tools` — should list installed CLI tools with one-line descriptions
- [ ] `gh auth status` — should show your GitHub login (or `gh auth login`)
- [ ] `mise --version` — confirm tool-version orchestrator is alive
- [ ] Spot-check casks that were missing on M1 actually opened:
      `open -a "Visual Studio Code"`, `open -a "DBeaver"`, `open -a "Rectangle"`

If any check fails, see §6 Recovery.

---

## 6. Recovery cookbook (only if §3 or §5 fails)

| Symptom | Probable cause | Recovery |
|---|---|---|
| `Failed to install: X (app exists at /Applications)` | App was put there manually before brew (e.g. drag-and-drop from a DMG) | `brew install --cask --force X` — overwrites and registers with brew |
| `Failed to install: X (cask name not found)` | Cask renamed since release; tap missing | `brew search X` to find current name; update `data/packages/brew-cask-*.txt` |
| `Failed to install: X (network error)` | Transient | Re-run `setup.sh full` — idempotent, will retry only the missing items |
| `bun installation failed` | `oven-sh/bun` tap unreachable | `brew tap oven-sh/bun` manually, then re-run |
| Wizard skipped — went straight to default | non-TTY (script piped through ssh/curl) | Pass profile explicitly: `bash setup.sh full` |
| Disk space warning aborted | < 10 GiB free | Free space, re-run. Idempotent — only the missing items install |

For anything not covered above: copy the saved `~/m5-install-stderr.log`
plus the terminal scrollback into a GitHub issue with platform, profile,
and the failing line.

---

## 7. Post-migration (M5, when stable)

- [ ] Restore tarball from Bitwarden vault
- [ ] Re-run `atuin sync` to pull history forward
- [ ] Turn iCloud Drive back ON
- [ ] Update memory state: M5 migration completed YYYY-MM-DD

---

**Total expected time** (active): ~45 min. Walk away during §3 install.
