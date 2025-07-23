# 📊 Versioning Guide - Simple & Clear

## 🎯 Our Versioning Strategy (Simplified)

We use **Semantic Versioning**: `MAJOR.MINOR.PATCH`

### When to Change Each Number:

#### MAJOR (X.0.0) - Breaking Changes
**When:** Changes that break existing usage
- Removing features
- Changing command syntax
- Requiring different OS version
- Major architectural changes

**Examples:**
- `2.0.0` → `3.0.0`: Complete rewrite or platform change
- `2.0.0` → `3.0.0`: Dropping support for Ubuntu 20.04

#### MINOR (0.X.0) - New Features
**When:** Adding new capabilities without breaking existing ones
- New installation profiles
- New tools added
- New command options
- New platform support

**Examples:**
- `2.3.0` → `2.4.0`: Added profile system
- `2.4.0` → `2.5.0`: Added Windows support

#### PATCH (0.0.X) - Bug Fixes
**When:** Fixing problems without adding features
- Security fixes
- Bug corrections
- Documentation updates
- Performance improvements

**Examples:**
- `2.3.0` → `2.3.1`: Fixed APT lock vulnerability
- `2.3.1` → `2.3.2`: Fixed macOS compatibility

### Pre-release Versions

**Format:** `VERSION-alpha.N` or `VERSION-beta.N`

- **alpha**: Still developing, may have bugs
- **beta**: Feature complete, testing for bugs
- **No suffix**: Stable release

**Examples:**
- `2.3.1-alpha.1`: First attempt at security fixes
- `2.3.1-alpha.4`: Fourth iteration, almost ready
- `2.3.1`: Stable release with all fixes

## 📋 Simple Decision Tree

```
Is it breaking existing usage?
  YES → Increment MAJOR (3.0.0)
  NO → Continue ↓

Are you adding new features?
  YES → Increment MINOR (2.4.0)
  NO → Continue ↓

Are you fixing bugs?
  YES → Increment PATCH (2.3.1)
```

## 🏷️ Version Tags vs Branches

### Use Tags For:
- **Releases**: `v2.3.0`, `v2.3.1`
- **Milestones**: `v2.3.1-alpha.4`
- **Stable points**: Any version users should use

### Use Branches For:
- **Active development**: `feature/profiles`
- **Bug fixes**: `fix/apt-security`
- **Experiments**: `experiment/rust-rewrite`

**Rule:** Users install from tags, developers work in branches.

## 📅 Release Cycle

1. **Development** in feature branch
2. **Alpha** releases for testing (`-alpha.N`)
3. **Beta** when feature complete (`-beta.N`)
4. **Release Candidate** if needed (`-rc.N`)
5. **Stable Release** (no suffix)

## 🎯 Current Version Explained

**v2.3.1-alpha.4** means:
- `2`: Second major version (after 1.0 rewrite)
- `3`: Third feature set added (profiles)
- `1`: First patch to 2.3.0 (security fix)
- `alpha.4`: Fourth test version, not yet stable

## ⚡ Quick Examples

### What Version for These Changes?

1. **Fixed typo in README** → `2.3.1` to `2.3.2` (PATCH)
2. **Added macOS support** → `2.3.0` to `2.4.0` (MINOR)
3. **Rewrote in Rust** → `2.0.0` to `3.0.0` (MAJOR)
4. **Fixed security bug** → `2.3.0` to `2.3.1` (PATCH)
5. **Added 5 new profiles** → `2.3.0` to `2.4.0` (MINOR)
6. **Removed Python 2 support** → `2.0.0` to `3.0.0` (MAJOR)

## 🔄 Migration from Current System

Current versions in the wild:
- `0.5` → Rename to `0.5.0`
- `2.0.0` → Keep as is
- `2.3.1-alpha4` → Already correct!

## 📝 Commit Message Format

```bash
# For version bumps:
git commit -m "chore: bump version to 2.3.1"
git tag -a v2.3.1 -m "Security fixes for APT operations"

# For features:
git commit -m "feat: add data scientist profile"
# This will be in next MINOR release

# For fixes:
git commit -m "fix: correct APT lock timeout"
# This will be in next PATCH release
```

## 🚀 ROADMAP Integration

Your ROADMAP milestones should align with versions:

```markdown
## ROADMAP

### v2.4.0 - Profile Enhancement (MINOR)
- [ ] Custom profile creator
- [ ] Profile inheritance
- [ ] Online profile repository

### v2.5.0 - Architecture Improvement (MINOR)
- [ ] Core/Adapters pattern
- [ ] Plugin system
- [ ] API for extensions

### v3.0.0 - Next Generation (MAJOR)
- [ ] Rust rewrite
- [ ] Breaking: New CLI syntax
- [ ] Breaking: Drop Ubuntu 20.04
```

## ❓ FAQ

**Q: When do we remove the -alpha suffix?**
A: When all tests pass and it's ready for users.

**Q: Can we skip versions?**
A: No, go sequentially: 2.3.1 → 2.3.2 → 2.4.0

**Q: What about date-based versions?**
A: We use semantic versioning, not dates. Dates go in CHANGELOG.

**Q: Do we need all those alphas?**
A: Only if testing in public. Internal work doesn't need versions.

---

**Remember:** Version numbers tell users what to expect. Be predictable!