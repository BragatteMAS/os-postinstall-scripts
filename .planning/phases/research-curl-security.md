# Research: curl|sh Security Mitigations

**Researched:** 2026-02-19
**Domain:** Supply-chain security for shell installer scripts
**Confidence:** HIGH (verified against upstream repos, official docs, and issue trackers)
**Triggered by:** v3.0 Review Panel -- 2 specialists (Linux, Architect) flagged curl|sh as HIGH severity

---

## Summary

The project has 7 instances of `curl|sh` across 5 tools: rustup, cargo-binstall, fnm, uv, and ollama (plus zoxide and starship in terminal-setup.sh). Two specialist reviewers flagged this as a supply-chain risk. After researching the actual security posture of each upstream installer and the real-world threat landscape, the conclusion is:

**None of these upstream installers verify checksums or signatures.** They all rely solely on HTTPS transport security. This is the industry norm for developer tool installers, not an oversight unique to this project.

**Primary recommendation:** Document the risk in an ADR (ADR-009), implement a lightweight `download-then-inspect-then-execute` wrapper for the 5 core installers, and accept HTTPS-only as the trust model. Full SHA256 verification is impractical because most upstreams do not publish stable checksums for their install scripts.

---

## Q1: What Are the Actual Risks of curl|sh?

### Risk Matrix

| Risk | Severity | Likelihood | Notes |
|------|----------|------------|-------|
| **MITM attack** | CRITICAL | LOW | All 5 URLs use HTTPS. rustup enforces `--proto '=https' --tlsv1.2`. Requires TLS compromise or CA breach |
| **Compromised upstream server** | CRITICAL | LOW | Requires compromising GitHub/Vercel/Astral/Ollama infrastructure. High-profile targets with security teams |
| **Partial download execution** | HIGH | MEDIUM | Network interruption mid-download can execute truncated script. Only ollama wraps in main() function |
| **Script content change** | MEDIUM | MEDIUM | Upstream can change script at any time. No pinned version for fnm, uv, ollama scripts |
| **DNS hijacking** | HIGH | LOW | Redirects to malicious script. HTTPS certificate validation prevents this unless CA is compromised |
| **Supply-chain compromise** | CRITICAL | LOW-MEDIUM | Shai-Hulud 2.0 (2025) showed developer toolchain attacks are real and increasing. 297 supply-chain attacks in 2025, up 93% from 2024 |

### Partial Download Problem (Most Practical Risk)

When `curl ... | sh` is interrupted mid-download, the shell may execute a truncated script. Example: if a line like `rm -rf /tmp/build_` gets cut to `rm -rf /`, the result is catastrophic. This is the most likely risk to materialize in practice.

**Current protection status per tool:**

| Tool | Function-wrapped? | Partial download safe? |
|------|-------------------|----------------------|
| rustup | NO | NO -- downloads binary, executes immediately |
| cargo-binstall | NO | NO -- pipes directly to bash |
| fnm | YES (set -e) | PARTIAL -- set -e helps but isn't complete protection |
| uv | Unknown | Unknown -- script not fully audited |
| ollama | YES (main() wrapper) | YES -- explicitly wraps in main function with comment about partial download protection |

---

## Q2: What Mitigations Exist?

### Mitigation Spectrum (from minimal to maximal)

| Level | Mitigation | Complexity | Protection | KISS-compatible? |
|-------|-----------|------------|------------|-----------------|
| 0 | Do nothing (current state) | None | HTTPS only | YES |
| 1 | **Document in ADR** | Minimal | Awareness | YES |
| 2 | **download-then-execute** | Low (~20 lines) | Partial download, inspection | YES |
| 3 | Pin URLs to specific versions | Low-Medium | Content drift | Mostly |
| 4 | SHA256 verify install scripts | Medium (~40 lines) | Tampered scripts | NO -- checksums not published by upstreams |
| 5 | GPG signature verification | High | Full chain of trust | NO -- requires gpg, keyring management |

### Level 2: download-then-execute (Recommended)

```bash
# safe_curl_sh - Download to temp file, then execute
# Prevents partial download execution
safe_curl_sh() {
    local url="$1"
    shift
    local tmp
    tmp=$(mktemp)
    trap 'rm -f "$tmp"' RETURN

    if ! curl -fsSL "$url" -o "$tmp"; then
        log_error "Failed to download: $url"
        return 1
    fi

    # File is complete -- execute it
    bash "$tmp" "$@"
}
```

**What this solves:**
- Partial download -- file must fully download before execution
- Inspection -- in debug mode, could log file size/hash before executing
- Error handling -- curl failure stops execution entirely

**What this does NOT solve:**
- Compromised upstream (malicious complete script)
- Content drift (script changes between runs)

### Level 3: Pinned URLs (Optional Enhancement)

Some tools support version-pinned installer URLs:

| Tool | Pinnable? | Pinned URL Pattern |
|------|-----------|-------------------|
| rustup | NO | `sh.rustup.rs` always serves latest |
| cargo-binstall | NO | Points to `main` branch |
| fnm | NO | `fnm.vercel.app/install` always serves latest |
| uv | YES | `https://astral.sh/uv/0.6.0/install.sh` (version in URL) |
| ollama | NO | `ollama.com/install.sh` always serves latest |

Only uv supports pinned versions. Not worth a universal pattern for one tool.

### Level 4: SHA256 Verification (Impractical)

**Why this doesn't work for install scripts:**

| Tool | Publishes script checksum? | Binary checksums? |
|------|---------------------------|-------------------|
| rustup | NO | NO (GPG signature effort abandoned -- issue #2028 closed as "not planned") |
| cargo-binstall | NO | YES (verifies crate checksums internally after install) |
| fnm | NO | NO |
| uv | NO (issue #13074 open, deprioritized by maintainers) | YES (SHA256 in GitHub releases, attestations via sigstore) |
| ollama | NO | YES (checksums added to releases in PR #3028, March 2024) |

The install scripts themselves are dynamic -- served from CDNs or GitHub raw. Their content can change without version bumps. Hardcoding SHA256 hashes would require manual updates on every upstream change, which is unsustainable.

---

## Q3: How Do These Specific Tools Handle Security?

### rustup (sh.rustup.rs)

- **TLS enforcement:** `--proto '=https' --tlsv1.2` with cipher suite detection (OpenSSL, GnuTLS, LibreSSL, BoringSSL)
- **Download method:** Downloads `rustup-init` binary to temp dir, sets executable, runs it
- **Checksum/signature:** NONE. GPG verification was planned (issue #2028) but closed as "not planned"
- **Partial download protection:** NO function wrapping
- **Trust model:** HTTPS transport + Rust infrastructure reputation
- **Source:** [rustup-init.sh on GitHub](https://github.com/rust-lang/rustup/blob/master/rustup-init.sh)

### cargo-binstall (install-from-binstall-release.sh)

- **TLS enforcement:** `--proto '=https' --tlsv1.2`
- **Download method:** Downloads binary from GitHub releases
- **Post-install security:** cargo-binstall itself verifies crate checksums via crates.io
- **Partial download protection:** NO
- **Source:** [GitHub repo](https://github.com/cargo-bins/cargo-binstall)

### fnm (fnm.vercel.app/install)

- **TLS enforcement:** Standard HTTPS (no extra flags)
- **Download method:** Downloads binary zip from GitHub releases, unzips, moves to install dir
- **Checksum/signature:** NONE
- **Partial download protection:** `set -e` (partial)
- **Note:** macOS install is deprecated in favor of Homebrew
- **Source:** [GitHub repo](https://github.com/Schniz/fnm)

### uv (astral.sh/uv/install.sh)

- **TLS enforcement:** Standard HTTPS
- **Download method:** Downloads binary from GitHub releases
- **Checksum/signature:** Script has verification logic but checksums are not injected (issue #13074 open)
- **Binary attestations:** GitHub Artifact Attestations via sigstore (for releases, not install script)
- **Partial download protection:** Unknown
- **Note:** Supports version-pinned URLs (`astral.sh/uv/0.6.0/install.sh`)
- **Source:** [Official docs](https://docs.astral.sh/uv/getting-started/installation/)

### ollama (ollama.com/install.sh)

- **TLS enforcement:** Standard HTTPS
- **Download method:** Downloads binary, tries `.tar.zst` first then `.tgz` fallback
- **Checksum/signature:** NONE for install script. Binary checksums available in releases (since March 2024)
- **Partial download protection:** YES -- explicitly wraps all code in `main()` function
- **Requires sudo:** YES (for systemd service, binary placement)
- **Source:** [scripts/install.sh on GitHub](https://github.com/ollama/ollama/blob/main/scripts/install.sh)

---

## Q4: Minimal Viable Mitigation (KISS-Compatible)

### Recommended: Two-Step Approach

**Step 1 (immediate, zero code): ADR-009**

Document the conscious decision to trust upstream HTTPS installers. This satisfies the review panel finding and creates an auditable record.

**Step 2 (low effort, ~25 lines): download-then-execute helper**

Add a `safe_curl_sh()` function to a shared utility (e.g., `src/core/network.sh` or inline in existing modules):

```bash
# safe_curl_sh -- Download installer to temp file before executing.
# Prevents partial download execution (the most practical curl|sh risk).
# Does NOT verify checksums (upstreams don't publish them for scripts).
#
# Usage: safe_curl_sh "https://example.com/install.sh" [-- args to pass]
safe_curl_sh() {
    local url="$1"
    shift

    local tmp
    tmp=$(mktemp "${TMPDIR:-/tmp}/installer-XXXXXX.sh")

    # Download completely before executing
    if ! curl -fsSL "$url" -o "$tmp"; then
        rm -f "$tmp"
        return 1
    fi

    # Execute the complete script
    local rc=0
    bash "$tmp" "$@" || rc=$?

    rm -f "$tmp"
    return "$rc"
}
```

**Migration per file:**

| File | Current | After |
|------|---------|-------|
| `src/platforms/linux/install/cargo.sh:55` | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh -s -- -y` | `safe_curl_sh "https://sh.rustup.rs" -- -y` with `--proto` flags |
| `src/platforms/linux/install/cargo.sh:127` | `curl -L --proto '=https' --tlsv1.2 -sSf URL \| bash` | `safe_curl_sh "URL"` |
| `src/install/fnm.sh:52` | `curl -fsSL https://fnm.vercel.app/install \| bash -s -- --skip-shell` | `safe_curl_sh "URL" -- --skip-shell` |
| `src/install/uv.sh:52` | `curl -LsSf https://astral.sh/uv/install.sh \| sh` | `safe_curl_sh "URL"` |
| `src/install/ai-tools.sh:114` | `curl -fsSL https://ollama.com/install.sh \| sh` | `safe_curl_sh "URL"` |

**Note:** rustup already uses `--proto '=https' --tlsv1.2`. The helper should preserve these flags. Consider adding curl flag pass-through or always enforcing HTTPS+TLS1.2.

### What NOT to Build

| Don't Build | Why |
|-------------|-----|
| Checksum verification for install scripts | Upstreams don't publish stable checksums for scripts |
| GPG signature verification | Requires gpg binary, keyring management, key rotation handling |
| Script content caching/diffing | Complex, maintenance burden, scripts change legitimately |
| Custom binary download + verify | Each tool has different binary formats, platforms, architectures |

---

## Q5: Is an ADR Acceptable as a First Step?

**YES. This is the correct first step.** Reasons:

1. **The review panel asked for "document or implement."** An ADR is the documented "document" option.
2. **The project already has 8 ADRs** -- this fits the established pattern.
3. **Every upstream installer relies on HTTPS-only** -- the project isn't doing anything the tools themselves don't do.
4. **thoughtbot/laptop (8.5K stars) uses curl|sh for Homebrew** with no checksum verification and no ADR. This project's documentation would exceed industry norms.
5. **The ADR creates an explicit decision record** that reviewers can reference instead of re-raising the same finding.

### ADR-009 Skeleton

```
Title: ADR-009: curl|sh Trust Model for External Installers
Status: Accepted
Context: 5 tools installed via curl|sh. Reviewers flagged supply-chain risk.
Decision:
  - Trust HTTPS transport security (industry standard)
  - Use download-then-execute pattern (prevents partial download)
  - Do NOT implement checksum/GPG verification (upstreams don't support it)
  - Re-evaluate annually or if supply-chain incident affects these tools
Consequences:
  - Positive: Explicit risk acknowledgment, partial download protection
  - Negative: Remains vulnerable to compromised upstream
```

---

## Q6: How Do Similar Projects Handle This?

### thoughtbot/laptop (8,549 stars)

- Uses `curl|sh` for Homebrew installer
- **No checksum verification**
- **No GPG verification**
- **No download-then-execute pattern**
- Relies entirely on HTTPS + trust in Homebrew
- Script is intentionally short and human-readable for review
- Recommends "review before running"

### holman/dotfiles (7,664 stars)

- Uses Homebrew (installed via curl|sh)
- No additional verification

### mathiasbynens/dotfiles (31,231 stars)

- Homebrew via curl|sh
- No verification

### Industry pattern

**No major dotfiles/setup project implements checksum verification for installer scripts.** The universal trust model is: HTTPS + upstream reputation. Some recommend "review the script first" but none enforce it programmatically.

---

## Common Pitfalls

### Pitfall 1: Over-engineering security theater

**What goes wrong:** Adding SHA256 verification that checks against a hash file hosted on the same server as the script. If the server is compromised, the hash is too.
**How to avoid:** Don't implement checksums unless they come from an independent source.

### Pitfall 2: Breaking the DRY_RUN contract

**What goes wrong:** The `safe_curl_sh` helper must respect DRY_RUN. If the guard is placed outside the helper, every call site needs it. If inside, the helper needs the DRY_RUN context.
**How to avoid:** Keep DRY_RUN guard in the caller (existing pattern), not in the helper.

### Pitfall 3: Forgetting curl flags

**What goes wrong:** rustup uses `--proto '=https' --tlsv1.2` for TLS enforcement. A generic helper might drop these.
**How to avoid:** Either always enforce these flags in the helper, or allow flag pass-through.

### Pitfall 4: temp file cleanup on failure

**What goes wrong:** If the script is interrupted between download and cleanup, temp files accumulate.
**How to avoid:** Use `trap 'rm -f "$tmp"' RETURN` or `trap ... EXIT` for cleanup.

---

## Sources

### Primary (HIGH confidence)
- [rustup-init.sh source](https://raw.githubusercontent.com/rust-lang/rustup/master/rustup-init.sh) -- verified no checksum/signature verification
- [rustup GPG tracking issue #2028](https://github.com/rust-lang/rustup/issues/2028) -- closed as "not planned"
- [uv checksum issue #13074](https://github.com/astral-sh/uv/issues/13074) -- open, deprioritized
- [uv official install docs](https://docs.astral.sh/uv/getting-started/installation/) -- recommends "inspect before use"
- [ollama install.sh source](https://github.com/ollama/ollama/blob/main/scripts/install.sh) -- verified main() function wrapping
- [ollama checksum issue #1313](https://github.com/ollama/ollama/issues/1313) -- binary checksums added March 2024
- [fnm GitHub repo](https://github.com/Schniz/fnm) -- verified no checksum in install script
- [cargo-binstall repo](https://github.com/cargo-bins/cargo-binstall) -- verified post-install crate checksum verification

### Secondary (MEDIUM confidence)
- [thoughtbot/laptop](https://github.com/thoughtbot/laptop) -- verified curl|sh usage with no verification
- [arp242.net "Curl to shell isn't so bad"](https://www.arp242.net/curl-to-sh.html) -- balanced argument on trust model
- [checksum.sh](https://checksum.sh/) -- alternative tool for script verification (not recommended for this project)
- [Chef: 5 Ways to Deal With curl|bash](https://www.chef.io/blog/5-ways-to-deal-with-the-install-sh-curl-pipe-bash-problem) -- industry mitigation patterns

### Tertiary (supply-chain landscape context)
- [Shai-Hulud 2.0 Microsoft Security Blog](https://www.microsoft.com/en-us/security/blog/2025/12/09/shai-hulud-2-0-guidance-for-detecting-investigating-and-defending-against-the-supply-chain-attack/) -- real-world supply-chain attack compromising developer tools
- [StepSecurity 2025 Review](https://www.stepsecurity.io/blog/2025-in-review-the-evolution-of-supply-chain-security-whats-next) -- supply-chain attacks nearly doubled in 2025

---

## Metadata

**Confidence breakdown:**
- Risk assessment: HIGH -- verified against each upstream's actual security posture
- Mitigation options: HIGH -- tested patterns from multiple sources
- Upstream security status: HIGH -- checked actual issue trackers and source code
- Industry comparison: MEDIUM -- checked top 3 projects but not exhaustive

**Research date:** 2026-02-19
**Valid until:** 2026-05-19 (re-check if any upstream adds checksum support)
