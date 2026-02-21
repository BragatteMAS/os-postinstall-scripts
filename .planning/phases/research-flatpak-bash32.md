# Bugfix Research: Flatpak App IDs + Bash 3.2 on macOS

**Researched:** 2026-02-19
**Domain:** Flatpak package management, Bash version compatibility
**Confidence:** HIGH

---

## Topic 1: Flatpak App IDs

### Problem

Flatpak requires full reverse-DNS application IDs (e.g., `com.slack.Slack`). Short names like `slack` will fail silently with `flatpak install`. The project has two files with broken entries.

### `flatpak search` for Programmatic Lookup

Yes, `flatpak search <term>` queries Flathub and returns matching app IDs. Output includes columns: Name, Description, Application ID, Version, Branch, Remotes. This is the recommended way to discover IDs:

```bash
flatpak search slack
# Output includes: com.slack.Slack
```

This could be used in a validation script or documented as a way for users to find correct IDs.

### data/packages/flatpak.txt -- Audit

| Current Entry | Valid? | Correct Full ID | Notes |
|---|---|---|---|
| `flatseal` | NO | `com.github.tchx84.Flatseal` | Short name |
| `filezilla` | NO | `org.filezillaproject.Filezilla` | Short name |
| `org.gnome.Boxes` | YES | `org.gnome.Boxes` | Already correct |
| `vim.vim` | NO | `org.vim.Vim` | Wrong casing/format |
| `pavucontrol` | NO | `org.pulseaudio.pavucontrol` | Short name |
| `obsproject.Studio` | NO | `com.obsproject.Studio` | Missing `com.` prefix |
| `org.blender.Blender` | YES | `org.blender.Blender` | Already correct |
| `org.videolan.VLC` | YES | `org.videolan.VLC` | Already correct |
| `zoom` | NO | `us.zoom.Zoom` | Short name |
| `slack` | NO | `com.slack.Slack` | Short name |
| `skype` | NO | `com.skype.Client` | Short name; NOTE: archived on Flathub as of 2025-07 |
| `dropbox` | NO | `com.dropbox.Client` | Short name |
| `masterpdf` | NO | `net.codeindustry.MasterPDFEditor` | Short name |
| `com.wps.Office` | YES* | `com.wps.Office` | Verify still on Flathub |
| `calibre` | NO | `com.calibre_ebook.calibre` | Short name |
| `ankiweb` | NO | `net.ankiweb.Anki` | Short name |
| `geogebra` | NO | `org.geogebra.GeoGebra` | Short name |
| `openboard` | NO | `ch.openboard.OpenBoard` | Short name |
| `blanket` | NO | `com.rafaelmardojai.Blanket` | Short name |
| `organizer` | NO | `org.librehunt.Organizer` | Short name |
| `meld` | NO | `org.gnome.meld` | Short name |
| `gitkraken` | NO | `com.axosoft.GitKraken` | Short name |
| `jamovi` | NO | `org.jamovi.jamovi` | Short name |
| `Epiphany` | NO | `org.gnome.Epiphany` | Short name, wrong casing |

**Summary:** 4 correct, 20 broken. 80% failure rate.

### data/packages/flatpak-post.txt -- Audit

| Current Entry | Valid? | Correct Full ID | Notes |
|---|---|---|---|
| `com.bitwarden.desktop` | YES | `com.bitwarden.desktop` | Correct |
| `flatseal` | NO | `com.github.tchx84.Flatseal` | Short name |
| `filezilla` | NO | `org.filezillaproject.Filezilla` | Short name |
| `gpuviewer` | NO | `io.github.arunsivaramanneo.GPUViewer` | Short name |
| `OnionShare` | NO | `org.onionshare.OnionShare` | Missing domain prefix |
| `org.gnome.Boxes` | YES | `org.gnome.Boxes` | Correct |
| `de.haeckerfelix.Fragments` | YES | `de.haeckerfelix.Fragments` | Correct |
| `fr.romainvigier.MetadataCleaner` | YES | `fr.romainvigier.MetadataCleaner` | Correct |
| `pavucontrol` | NO | `org.pulseaudio.pavucontrol` | Short name |
| `com.spotify.Client` | YES | `com.spotify.Client` | Correct |
| `org.audacityteam.Audacity` | YES | `org.audacityteam.Audacity` | Correct |
| `io.github.seadve.Mousai` | YES | `io.github.seadve.Mousai` | Correct |
| `com.uploadedlobster.peek` | YES | `com.uploadedlobster.peek` | Correct |
| `org.inkscape.Inkscape` | YES | `org.inkscape.Inkscape` | Correct |
| `org.kde.kdenlive` | YES | `org.kde.kdenlive` | Correct |
| `obsproject.Studio` | NO | `com.obsproject.Studio` | Missing `com.` prefix |
| `org.videolan.VLC` | YES | `org.videolan.VLC` | Correct |
| `org.blender.Blender` | YES | `org.blender.Blender` | Correct |
| `com.valvesoftware.Steam` | YES | `com.valvesoftware.Steam` | Correct |
| `zoom` | NO | `us.zoom.Zoom` | Short name |
| `slack` | NO | `com.slack.Slack` | Short name |
| `org.telegram.desktop` | YES | `org.telegram.desktop` | Correct |
| `com.discordapp.Discord` | YES | `com.discordapp.Discord` | Correct |
| `com.google.Chrome` | YES | `com.google.Chrome` | Correct |
| `org.chromium.Chromium` | YES | `org.chromium.Chromium` | Correct |
| `io.gitlab.librewolf-community` | YES | `io.gitlab.librewolf-community` | Correct |
| `dropbox` | NO | `com.dropbox.Client` | Short name |
| `nz.mega.MEGAsync` | YES | `nz.mega.MEGAsync` | Correct |
| `org.kde.okular` | YES | `org.kde.okular` | Correct |
| `calibre` | NO | `com.calibre_ebook.calibre` | Short name |
| `openboard` | NO | `ch.openboard.OpenBoard` | Short name |
| `com.github.johnfactotum.Foliate` | YES | `com.github.johnfactotum.Foliate` | Correct |
| `fontfinder` | NO | `io.github.mmstick.FontFinder` | Short name |
| `org.gustavoperedo.FontDownloader` | YES | `org.gustavoperedo.FontDownloader` | Correct |
| `io.github.lainsce.Colorway` | YES | `io.github.lainsce.Colorway` | Correct |
| `io.github.lainsce.Emulsion` | YES | `io.github.lainsce.Emulsion` | Correct |
| `com.visualstudio.code` | YES | `com.visualstudio.code` | Correct |
| `rest.insomnia.Insomnia` | YES | `rest.insomnia.Insomnia` | Correct |
| `meld` | NO | `org.gnome.meld` | Short name |
| `com.toggl.TogglDesktop` | REMOVED | -- | App removed from Flathub (discontinued) |
| `com.gitlab.cunidev.Workflow` | YES* | `com.gitlab.cunidev.Workflow` | Verify still on Flathub |
| `org.texstudio.TeXstudio` | YES | `org.texstudio.TeXstudio` | Correct |
| `blanket` | NO | `com.rafaelmardojai.Blanket` | Short name |
| `organizer` | NO | `org.librehunt.Organizer` | Short name |
| `md.obsidian.Obsidian` | YES | `md.obsidian.Obsidian` | Correct |
| `org.zotero.Zotero` | YES | `org.zotero.Zotero` | Correct |
| `org.pymol.PyMOL` | YES | `org.pymol.PyMOL` | Correct |
| `org.jaspstats.JASP` | YES | `org.jaspstats.JASP` | Correct |
| `geogebra` | NO | `org.geogebra.GeoGebra` | Short name |

**Summary:** 30 correct, 16 broken, 1 removed. ~33% failure rate.

### Additional Warnings

- **com.skype.Client**: Repository archived on Flathub (July 2025). Consider removing.
- **com.toggl.TogglDesktop**: Returns 404 on Flathub. Discontinued. Must remove.
- **com.wps.Office**: Verify current availability; WPS Office has had Flathub availability issues.
- **com.gitlab.cunidev.Workflow**: Verify current availability.

### Recommendation

Replace all short names with full IDs. Add a comment header reminding contributors to use `flatpak search <name>` to find correct IDs. Remove discontinued entries.

---

## Topic 2: Bash 3.2 on macOS

### Problem

`verify_bash_version()` in `src/core/platform.sh` (line 115-136) returns 1 when `BASH_VERSINFO[0] < 4`. macOS ships with Bash 3.2.57 (due to GPLv3 licensing). First-time users on macOS cannot run `setup.sh` because Homebrew (which provides Bash 5.x) is not yet installed -- that is exactly what the script is supposed to install.

This is a **chicken-and-egg problem**: the script that installs Homebrew cannot run because it requires a tool that Homebrew installs.

### The verify_bash_version() Implementation

```bash
verify_bash_version() {
    local major="${BASH_VERSINFO[0]:-0}"
    if [[ "$major" -lt 4 ]]; then
        log_error "Bash version $DETECTED_BASH is too old. Version 4.0+ is required."
        # ... prints upgrade instructions including "brew install bash"
        return 1
    fi
    return 0
}
```

Called from `verify_all()` (line 314), which is called from `setup.sh` `main()` (line 165). A return of 1 causes `setup.sh` to exit before dispatching to any platform handler.

### Does the Project Actually Need Bash 4+?

**No.** After thorough analysis of all shell scripts in `src/`:

| Feature | Bash Version Required | Used in Project? |
|---|---|---|
| `declare -A` (associative arrays) | 4.0+ | **NO** |
| `mapfile` / `readarray` | 4.0+ | **NO** |
| `${var,,}` / `${var^^}` (case) | 4.0+ | **NO** |
| `coproc` | 4.0+ | **NO** |
| `|&` (pipe stderr) | 4.0+ | **NO** |
| `&>>` (append both) | 4.0+ | **NO** |
| `**` globstar | 4.0+ | **NO** |
| `BASH_SOURCE` | 3.0+ | Yes -- widely used, OK |
| `BASH_VERSINFO` | 2.0+ | Yes -- OK |
| `[[ ]]` | 2.05+ | Yes -- OK |
| `declare -a` (indexed arrays) | 2.0+ | Yes -- OK |
| `+=` (array append) | 3.1+ | Yes -- OK |
| `set -o pipefail` | 3.0+ | Yes -- OK |
| `${var:offset:length}` (substring) | 3.0+ | Yes -- one instance in platform.sh, OK |
| `export -f` (function export) | 3.0+ | Yes -- widely used, OK |
| `read -r` | 2.0+ | Yes -- OK |

**Conclusion: The entire codebase is Bash 3.2 compatible.** The version check is overly conservative.

### Recommended Fix

**Option A (Recommended): Warn instead of block on macOS.**

Change `verify_bash_version()` to emit a warning on macOS but allow execution to continue:

```bash
verify_bash_version() {
    local major="${BASH_VERSINFO[0]:-0}"

    if [[ "$major" -lt 4 ]]; then
        if [[ "$DETECTED_OS" == "macos" ]]; then
            log_warn "Bash $DETECTED_BASH detected. Homebrew will install Bash 5.x."
            log_warn "After setup, add /opt/homebrew/bin/bash to /etc/shells and run: chsh -s /opt/homebrew/bin/bash"
            return 0  # Allow execution to continue
        fi
        log_error "Bash version $DETECTED_BASH is too old. Version 4.0+ is required."
        echo ""
        echo "Upgrade instructions:"
        echo "  sudo apt update && sudo apt install bash"
        return 1
    fi

    return 0
}
```

**Why this is the right fix:**
1. The project does not use any Bash 4+ features, so Bash 3.2 is functionally sufficient.
2. macOS users NEED this script to run first (to install Homebrew, which provides Bash 5.x).
3. Linux distros typically ship Bash 5.x, so the hard check on Linux is fine as a safety net.
4. The warning educates users to upgrade after setup completes.

**Option B: Remove version check entirely.**

Since no Bash 4+ features are used, the check serves no functional purpose. However, keeping it as a warning is more defensive -- if future contributors add Bash 4+ features, the warning surfaces.

**Option C: Bootstrap Homebrew before version check.**

Too complex. The version check runs inside `verify_all()` which runs early in `main()`. Moving Homebrew bootstrap earlier would require restructuring the entire startup flow.

### Future-Proofing

If Bash 4+ features are ever added (e.g., associative arrays), the macOS path should either:
1. Bootstrap Homebrew and re-exec under Bash 5, or
2. Provide Bash 3.2 fallback implementations

But currently this is not needed.

---

## Sources

### PRIMARY (HIGH confidence)
- `src/core/platform.sh` -- direct code inspection of verify_bash_version()
- `src/core/packages.sh`, `src/core/errors.sh`, `src/core/logging.sh` -- feature usage audit
- All `src/**/*.sh` files -- grep for Bash 4+ features (none found)
- [Flathub - com.github.tchx84.Flatseal](https://flathub.org/en/apps/com.github.tchx84.Flatseal)
- [Flathub - org.filezillaproject.Filezilla](https://github.com/flathub/org.filezillaproject.Filezilla)
- [Flathub - com.slack.Slack](https://flathub.org/en/apps/com.slack.Slack)
- [Flathub - us.zoom.Zoom](https://flathub.org/en/apps/us.zoom.Zoom)
- [Flathub - com.dropbox.Client](https://flathub.org/en/apps/com.dropbox.Client)
- [Flathub - com.calibre_ebook.calibre](https://flathub.org/en/apps/com.calibre_ebook.calibre)
- [Flathub - org.gnome.meld](https://flathub.org/apps/details/org.gnome.meld)
- [Flathub - com.rafaelmardojai.Blanket](https://flathub.org/en/apps/com.rafaelmardojai.Blanket)
- [Flathub - com.axosoft.GitKraken](https://flathub.org/en/apps/com.axosoft.GitKraken)
- [Flathub - org.pulseaudio.pavucontrol](https://github.com/flathub/org.pulseaudio.pavucontrol)
- [Flathub - org.vim.Vim](https://flathub.org/en/apps/org.vim.Vim)
- [Flathub - org.geogebra.GeoGebra](https://github.com/flathub/org.geogebra.GeoGebra)
- [Flathub - ch.openboard.OpenBoard](https://flathub.org/en/apps/ch.openboard.OpenBoard)
- [Flathub - org.jamovi.jamovi](https://github.com/flathub/org.jamovi.jamovi)
- [Flathub - net.ankiweb.Anki](https://flathub.org/en/apps/net.ankiweb.Anki)
- [Flathub - com.obsproject.Studio](https://flathub.org/en/apps/com.obsproject.Studio)
- [Flathub - net.codeindustry.MasterPDFEditor](https://github.com/flathub/net.code_industry.MasterPDFEditor)
- [Flathub - com.skype.Client (archived)](https://github.com/flathub/com.skype.Client)
- [Flathub - org.onionshare.OnionShare](https://github.com/flathub/org.onionshare.OnionShare)
- [Flathub - org.gnome.Epiphany](https://github.com/flathub/org.gnome.Epiphany)
- [Flathub - org.librehunt.Organizer](https://github.com/flathub/org.librehunt.Organizer)
- [Flathub - io.github.arunsivaramanneo.GPUViewer](https://github.com/flathub/io.github.arunsivaramanneo.GPUViewer)
- [Flathub - io.github.mmstick.FontFinder](https://github.com/flathub/io.github.mmstick.FontFinder)
- [Flathub - com.visualstudio.code](https://flathub.org/en/apps/com.visualstudio.code)
- [Flathub - rest.insomnia.Insomnia](https://flathub.org/en/apps/rest.insomnia.Insomnia)
- [Flathub - com.toggl.TogglDesktop (404/removed)](https://flathub.org/en/apps/com.toggl.TogglDesktop)
- [Flathub - org.jaspstats.JASP](https://github.com/flathub/org.jaspstats.JASP)
- [Flathub - org.pymol.PyMOL](https://flathub.org/en/apps/org.pymol.PyMOL)
- [Flathub - io.gitlab.librewolf-community](https://flathub.org/en/apps/io.gitlab.librewolf-community)

### SECONDARY (MEDIUM confidence)
- Bash version feature matrix from GNU Bash manual and accumulated shell programming knowledge
- Flathub GitHub repositories for app ID verification
