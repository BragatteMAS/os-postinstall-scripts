# User Stories and Journey Mapping - OS Post-Install Scripts

## 🎯 Perguntas Focais para Modulação do CLAUDE.md

### Decisões Críticas que Filtram o CLAUDE.md:

| Pergunta | Resposta | Impacto no CLAUDE.md | Seções Ativadas |
|----------|----------|---------------------|-----------------|
| **Precisa de testes automatizados?** | ✅ Sim | Testing Trophy ativado | Testing patterns, /tests, TESTING.md |
| **É multi-plataforma?** | ✅ Sim (Linux, Windows, macOS) | Cross-platform patterns | Compatibilidade, pathlib, OS detection |
| **Tem interface visual?** | ❌ Não (CLI/TUI apenas) | Skip frontend patterns | Remove React/Next.js sections |
| **Usa linguagens compiladas?** | ✅ Parcial (Bash, PowerShell) | Shell scripting patterns | Bash/Shell best practices |
| **Deploy automático?** | ✅ Sim (GitHub Actions) | CI/CD patterns | GitHub workflows, automated testing |
| **Análise de dados?** | ❌ Não | Skip data science | Remove Python/R analytics |
| **Precisa de docs interativos?** | ✅ Sim | Documentation patterns | README, guides, examples |
| **Gestão de estado complexo?** | ❌ Não | Skip state management | Remove Redux/Context patterns |

### Resultado da Filtragem:
**Módulos CLAUDE.md Ativos:** Shell scripting, Testing Trophy, Cross-platform, CI/CD, Documentation
**Módulos CLAUDE.md Inativos:** Frontend (React/Next), Data Science (Python/R analytics), State Management

---

## 🚨 Epic 0: Critical Security and Architecture Fixes (URGENT)

### Story 0.1: Fix APT Lock Security Vulnerability
**As a** system administrator,  
**I want** safe handling of package manager locks,  
**So that** system integrity is never compromised.

**Acceptance Criteria:**
1. NO force removal of lock files
2. Wait mechanism with timeout (max 5 minutes)
3. Clear error messages when locks persist
4. Audit logging of all package operations
5. Input validation for package names
6. All scripts updated to use safe wrappers

**Technical Notes (PRP):**
- Implement as per ADR-005
- Create utils/package-manager-safety.sh
- Add security tests
- Priority: CRITICAL - Block v3.0.0

### Story 0.2: Implement Core/Adapters Architecture
**As a** developer contributing to the project,  
**I want** a clean architecture with proper abstractions,  
**So that** I can easily add platform support without duplication.

**Acceptance Criteria:**
1. core/interfaces/ with all contracts defined
2. adapters/ for each package manager
3. All scripts use adapters (no direct calls)
4. Full test coverage for adapters
5. Documentation of architecture
6. Migration guide for contributors

**Technical Notes (PRP):**
- Implement as per ADR-007
- Start with APT adapter
- Maintain backward compatibility during migration
- Priority: CRITICAL - Technical debt

### Story 0.3: Implement Real Testing Framework
**As a** quality engineer,  
**I want** real tests with measurable coverage,  
**So that** we can trust our quality metrics.

**Acceptance Criteria:**
1. bats-core framework installed and configured
2. Remove false "100% coverage" claims
3. Initial 10 integration tests for critical paths
4. 5 security-focused tests
5. Coverage reporting with kcov
6. CI/CD running all tests
7. README badge with real coverage

**Technical Notes (PRP):**
- Implement as per ADR-006
- Focus on Testing Trophy distribution
- Start with security tests
- Priority: CRITICAL - Trust and transparency

---

## 📚 User Stories

### Epic 1: Developer Setting Up New Machine

#### Story 1.1: Quick Start Installation
**As a** developer new to a Linux machine,  
**I want** to run a single command that sets up my entire development environment,  
**So that** I can start coding immediately without manual configuration.

**Acceptance Criteria:**
1. One-command installation process
2. All essential dev tools installed (Git, Docker, Node.js, Python, etc.)
3. Shell configured with productivity features
4. Process completes in < 30 minutes
5. Clear progress indicators throughout

**Technical Notes (PRP):**
- Entry point: `setup.sh` or `main.sh`
- Modular script loading from install/
- Error handling and rollback capability
- Logging to track installation progress

#### Story 1.2: Custom Tool Selection
**As a** specialized developer (e.g., Rust developer),  
**I want** to select specific tools and skip others,  
**So that** I only install what I need for my workflow.

**Acceptance Criteria:**
1. Interactive TUI menu with arrow key navigation
2. Preset profiles: Web Dev, Data Science, DevOps, Mobile, Embedded
3. Custom profile saved to ~/.config/os-postinstall/profiles/
4. Skip detection completes in < 10 seconds
5. Dependency graph resolution with conflict warnings
6. Installation time estimate before confirmation
7. Dry-run mode to preview changes

**Technical Notes (PRP):**
- Use whiptail or dialog for TUI
- Profile format: YAML or JSON
- Cache installed packages list

#### Story 1.3: Failed Installation Recovery
**As a** developer whose installation was interrupted,  
**I want** to resume or rollback the installation safely,  
**So that** I don't end up with a broken system.

**Acceptance Criteria:**
1. Installation state saved every 5 minutes
2. Resume from last checkpoint option
3. Full rollback capability
4. Clear error messages with recovery steps
5. Logs preserved for debugging
6. Automatic cleanup of partial installs

**Technical Notes (PRP):**
- State file in ~/.config/os-postinstall/state.json
- Transaction log with timestamps
- Implement as per Epic 0 architecture

#### Story 1.4: Offline/Air-gapped Installation
**As a** developer in a restricted network environment,  
**I want** to install tools from local cache/mirrors,  
**So that** I can set up my environment without internet access.

**Acceptance Criteria:**
1. Option to pre-download packages
2. Local mirror configuration
3. Offline mode detection
4. Clear documentation for air-gapped setup
5. Package integrity verification
6. Size estimation for offline bundle

**Technical Notes (PRP):**
- Create download-offline.sh script
- Support apt-mirror, snap offline
- Checksum verification mandatory

#### Story 1.5: Configuration Migration
**As a** developer with existing dotfiles and configs,  
**I want** to preserve my customizations during setup,  
**So that** I maintain my productivity settings.

**Acceptance Criteria:**
1. Dotfile backup before changes
2. Option to skip config overwrites
3. Merge strategy for existing configs
4. Config diff preview
5. Rollback to previous configs
6. Support for common dotfile managers

**Technical Notes (PRP):**
- Detect existing .bashrc, .zshrc, .gitconfig
- Create timestamped backups
- Interactive merge conflicts

---

### Epic 2: IT Professional Mass Deployment

#### Story 2.1: Standardized Workstation Setup
**As an** IT administrator,  
**I want** to deploy consistent configurations across multiple machines,  
**So that** all team members have identical development environments.

**Acceptance Criteria:**
1. Configuration file support
2. Silent/unattended installation mode
3. Centralized configuration management
4. Deployment reporting
5. Rollback capabilities

#### Story 2.2: Compliance and Security
**As a** security-conscious IT professional,  
**I want** installation scripts that follow security best practices,  
**So that** deployed systems are secure by default.

**Acceptance Criteria:**
1. No hardcoded credentials
2. Secure credential management
3. Audit logging
4. Permission management
5. Security tool installation options

---

### Epic 3: Cross-Platform Developer

#### Story 3.1: Unified Experience Across OS
**As a** developer working on multiple platforms,  
**I want** consistent tooling regardless of OS,  
**So that** I can maintain productivity when switching between machines.

**Acceptance Criteria:**
1. Similar commands work on Linux/macOS/Windows
2. Equivalent tools installed per platform
3. Configuration sync capabilities
4. Platform-specific optimizations
5. Clear platform differences documented

#### Story 3.2: WSL Integration
**As a** Windows developer using WSL,  
**I want** seamless integration between Windows and Linux environments,  
**So that** I can leverage both ecosystems effectively.

**Acceptance Criteria:**
1. WSL detection and optimization
2. Windows Terminal configuration
3. Cross-environment tool access
4. Shared configuration files
5. Performance optimizations

---

### Epic 4: Linux Enthusiast / Distro Hopper

#### Story 4.1: Distribution Agnostic Scripts
**As a** Linux enthusiast who frequently changes distributions,  
**I want** scripts that work across different distros,  
**So that** I can quickly set up any new system.

**Acceptance Criteria:**
1. Auto-detect distribution and version
2. Package manager abstraction
3. Distro-specific optimizations
4. Desktop environment flexibility
5. Preserve user customizations

#### Story 4.2: Desktop Environment Setup
**As a** user who likes to experiment with different DEs,  
**I want** to easily install and configure various desktop environments,  
**So that** I can choose the best one for my needs.

**Acceptance Criteria:**
1. Support major DEs (GNOME, KDE, XFCE, etc.)
2. DE-specific optimizations
3. Theme and customization options
4. Performance tuning
5. Easy switching between DEs

---

## 🔄 User Journey Maps

### Journey 1: First-Time Developer Setup
```
Start → Clone Repo → Run setup.sh → Choose Profile → Watch Progress → Verify Installation → Start Coding
  ↓         ↓           ↓              ↓                ↓                  ↓                  ↓
[2min]   [30sec]     [1min]         [2min]          [25min]            [2min]            [Success!]
```

**Pain Points Addressed:**
- ❌ Hours of manual installation → ✅ Automated in minutes
- ❌ Missing dependencies → ✅ Automatic resolution
- ❌ Configuration errors → ✅ Validated setup
- ❌ Inconsistent environments → ✅ Standardized configs

### Journey 2: IT Mass Deployment
```
Plan → Create Config → Test on Single Machine → Deploy to Fleet → Monitor → Report
  ↓         ↓                    ↓                    ↓             ↓         ↓
[1hr]    [30min]             [30min]              [2hrs]        [Ongoing]  [Done]
```

**Value Delivered:**
- 🎯 Consistency across all machines
- 🎯 Reduced setup time by 95%
- 🎯 Compliance by default
- 🎯 Easy maintenance and updates

---

## 📊 Success Metrics by User Type

| User Type | Primary Metric | Target | Current |
|-----------|---------------|--------|---------|
| Developer | Setup time | < 30 min | ✅ 25 min |
| IT Admin | Deployment success rate | > 95% | 🔄 Measuring |
| Distro Hopper | Distro compatibility | 10+ distros | ✅ 12 distros |
| Cross-Platform Dev | Feature parity | > 90% | 🟡 70% |

---

## 🎯 Implementation Priority

### Phase 0 (CRITICAL - Before v3.0.0)
1. 🚨 Story 0.1: Fix APT Lock Security Vulnerability
2. 🚨 Story 0.2: Implement Core/Adapters Architecture
3. 🚨 Story 0.3: Implement Real Testing Framework

### Phase 1 (Current Sprint - After Critical Fixes)
1. ✅ Core modular architecture
2. ✅ Linux platform support
3. ✅ Documentation and CLAUDE.md integration
4. 🔄 Enhanced developer stories (1.3, 1.4, 1.5)

### Phase 2 (Next Sprint)
1. 📋 Enhanced Windows support
2. 📋 macOS feature parity
3. 📋 Configuration management system
4. 📋 Profile system

### Phase 3 (Future)
1. 📋 Cloud configuration sync
2. 📋 Enterprise features
3. 📋 GUI configuration tool
4. 📋 Mobile companion app

---

## 📝 Notes for CLAUDE.md Application

Based on the answers above, when working on this project:

1. **Always include shell script best practices** - ShellCheck compliance, error handling
2. **Skip frontend frameworks** - No React, Vue, or web UI code needed
3. **Focus on CLI/TUI patterns** - Command line interfaces, not graphical
4. **Emphasize cross-platform compatibility** - Test on Linux, macOS, Windows
5. **Include Testing Trophy approach** - But adapted for shell scripts
6. **Documentation is critical** - Clear examples, guides, and inline comments
7. **Security first** - Never expose credentials, always validate input
8. **Performance matters** - Scripts should be fast and efficient

This modular approach ensures CLAUDE.md provides relevant guidance without overwhelming with irrelevant patterns.