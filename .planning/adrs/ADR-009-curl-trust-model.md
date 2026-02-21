# ADR-009: curl|sh Trust Model - HTTPS-Only, Download-Then-Execute

**Status:** Accepted
**Date:** 2026-02-21
**Phase:** 16

## Context

The project uses `curl URL | sh` to install several tools that do not publish packages in system package managers: rustup (Rust toolchain), cargo-binstall, fnm (Node version manager), uv (Python package manager), and ollama (local AI models). This is a widely discussed security pattern.

The primary risk is **partial download execution**: if the connection drops mid-transfer, bash may execute a truncated script. Secondary risks (MITM, supply chain compromise) are mitigated by HTTPS transport security and are accepted as industry-standard practice.

## Decision

1. **Download-then-execute:** All curl|sh call sites use `safe_curl_sh()` which downloads to a temp file before executing. This eliminates partial download risk.

2. **HTTPS-only:** All URLs use HTTPS. No HTTP fallback.

3. **No checksum verification:** None of the upstream projects (rustup, cargo-binstall, fnm, uv, ollama) publish stable checksums for their install scripts. Scripts change with every release. Implementing verification the upstreams do not support would be security theater.

4. **No GPG verification:** Would require shipping and maintaining a GPG keyring. Key rotation, revocation, and binary distribution add complexity with minimal security gain for install scripts that run once.

## Call Sites

| Tool | URL | Installer |
|------|-----|-----------|
| rustup | https://sh.rustup.rs | cargo.sh |
| cargo-binstall | https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | cargo.sh |
| fnm | https://fnm.vercel.app/install | fnm.sh |
| uv | https://astral.sh/uv/install.sh | uv.sh |
| ollama | https://ollama.com/install.sh | ai-tools.sh |

## Alternatives Considered

### Checksum verification
- **Pros:** Detects script tampering
- **Cons:** No upstream publishes stable checksums. Scripts change on every release. Would require maintaining a checksum database that drifts immediately.

### GPG signature verification
- **Pros:** Cryptographic proof of origin
- **Cons:** Requires gpg binary, keyring management, key rotation handling. Only rustup offers GPG signatures (for the toolchain, not the install script).

### Vendor each installer script
- **Pros:** Full control over what executes
- **Cons:** Scripts are 200-500 lines each. They change frequently. Vendoring 5 scripts means maintaining 5 forks. Platform-specific logic makes this impractical.

### System package managers only
- **Pros:** Avoids curl|sh entirely
- **Cons:** rustup, cargo-binstall, and fnm are not available in apt/brew. uv's apt package lags significantly behind releases.

## Consequences

- **Positive:** No partial download execution. Explicit, documented risk acknowledgment. Matches industry practice (homebrew, rustup, nvm, asdf all use this pattern).
- **Negative:** Still trusts upstream HTTPS endpoints. A compromised upstream could serve a malicious script. This risk is accepted as inherent to the tool ecosystem.

## References

- [thoughtbot/laptop](https://github.com/thoughtbot/laptop) -- curl|sh with no verification
- [rustup.rs](https://rustup.rs/) -- official installation method is curl|sh
- [Homebrew](https://brew.sh/) -- installs via curl|bash
- [nvm](https://github.com/nvm-sh/nvm) -- installs via curl|bash
