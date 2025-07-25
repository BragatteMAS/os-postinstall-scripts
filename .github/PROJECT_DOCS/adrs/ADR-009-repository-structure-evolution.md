# ADR-009: Repository Structure Evolution Strategy

## Status

🟨 Proposed

## Context

The current repository structure has grown organically since its inception as Ubuntu-specific scripts. While functional, several improvements could enhance maintainability and clarity:

1. **Naming Clarity**: `utils/` could be more descriptive (industry standard is `lib/`)
2. **Script Organization**: Installation scripts scattered across root and OS directories
3. **Future Growth**: Need clear guidelines for where new components go
4. **Industry Standards**: Balance between following conventions and practical needs

However, any changes must consider:
- Existing users with scripts/workflows depending on current paths
- CI/CD pipelines expecting specific structure
- Documentation referencing current paths
- The cost of breaking changes vs. benefits

## Decision

We will implement a **gradual, backward-compatible evolution** of the repository structure over three minor versions (v2.6.0, v2.7.0) before any breaking changes in v3.0.0.

### Phase 1 - v2.6.0 (Preparation)
1. Create new directory structure alongside existing
2. Use symbolic links for backward compatibility
3. Add deprecation warnings to old paths
4. Update new code to use new structure

### Phase 2 - v2.7.0 (Migration)
1. Migrate ~50% of scripts to use new paths
2. Maintain all symlinks
3. Update documentation with both paths
4. Gather community feedback

### Phase 3 - v3.0.0 (Consolidation)
1. Remove deprecated symlinks
2. Complete migration
3. Clean up old structure
4. Major version bump signals breaking change

### Proposed Structure Changes

```
Current                    →  Future (v3.0.0)
utils/                     →  lib/
linux/scripts/install_*    →  installers/linux/
windows/*.ps1              →  installers/windows/
macos/*.sh                 →  installers/macos/
```

### What Stays the Same
- `profiles/` - Works well as-is
- `.github/` - Modern, well-organized
- `tests/` - Standard location
- `docs/` - Standard location
- Root entry points (`setup.sh`, etc.)

## Consequences

### Positive
- Clearer naming (`lib/` is industry standard)
- Better organization of installation scripts
- Easier to find components
- More predictable for new contributors
- Aligns better with standard practices

### Negative
- Requires migration effort
- Risk of breaking user workflows
- Documentation needs updates
- Temporary complexity with symlinks
- Maintenance overhead during transition

### Mitigation
- Extensive testing at each phase
- Clear communication in CHANGELOG
- Migration scripts for users
- Extended support for old structure
- Symlinks ensure zero downtime

## Implementation Plan

### v2.6.0 Tasks
```bash
# 1. Create new structure
mkdir -p lib
mkdir -p installers/{linux,windows,macos}

# 2. Create symlinks
ln -s utils lib/utils  # Inside lib/
ln -s ../utils lib    # Alternative approach

# 3. Add deprecation notices
echo "# DEPRECATED: This directory will move to lib/ in v3.0.0" > utils/DEPRECATION_NOTICE.md

# 4. Update new scripts to use lib/
```

### Testing Requirements
1. All existing tests must pass
2. Test both old and new paths
3. Verify symlinks work on all OS
4. CI/CD continues to function
5. Installation profiles work correctly

## Alternatives Considered

1. **Big Bang Migration** - Too risky, would break users
2. **Never Change** - Misses opportunity to improve
3. **Only Documentation** - Doesn't address core issues
4. **Complete Restructure** - Too disruptive for value

## References

- [ARCHITECTURE.md](../ARCHITECTURE.md) - Overall structure guidelines
- [PATH_DEPENDENCIES.md](../PATH_DEPENDENCIES.md) - Current dependencies
- Issue #XXX - Community discussion (to be created)

## Decision Makers

- @BragatteMAS - Project maintainer
- Community feedback via issue discussion

## Timeline

- v2.6.0: Q1 2025 - Preparation phase
- v2.7.0: Q2 2025 - Migration phase  
- v3.0.0: Q3 2025 - Consolidation (earliest)

---

> **Note**: This ADR is PROPOSED. Community feedback is essential before proceeding.