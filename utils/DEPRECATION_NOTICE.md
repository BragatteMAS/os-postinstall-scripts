# ⚠️ DEPRECATION NOTICE

**This directory (`utils/`) will be moved to `lib/` in v3.0.0**

## Timeline
- v2.6.0 (Current): Symlinks created, both paths work
- v2.7.0: Migration in progress, update your scripts
- v3.0.0: `utils/` will be removed, use `lib/` only

## Migration Guide

### Old way:
```bash
source "${SCRIPT_DIR}/utils/logging.sh"
```

### New way (recommended):
```bash
source "${SCRIPT_DIR}/lib/logging.sh"
```

### Temporary compatibility (works now):
```bash
# This will work during transition
source "${SCRIPT_DIR}/lib/utils/logging.sh"
```

## Affected Files
- logging.sh
- package-manager-safety.sh  
- profile-loader.sh

---
*Last updated: 2025-07-25*