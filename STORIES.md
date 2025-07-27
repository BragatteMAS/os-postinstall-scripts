# User Stories and Journey Mapping - OS Post-Install Scripts

## 🎯 Focal Questions for CLAUDE.md Modulation

### Critical Decisions that Filter CLAUDE.md:

| Question | Answer | Impact on CLAUDE.md | Activated Sections |
|----------|----------|---------------------|-----------------|
| **Need automated tests?** | ❌ No (manual only) | Manual test guides | No CI/CD, no test hooks |
| **Is it multi-platform?** | ✅ Yes (Linux, Windows, macOS) | Cross-platform patterns | Compatibility, pathlib, OS detection |
| **Has visual interface?** | ❌ No (CLI/TUI only) | Skip frontend patterns | Remove React/Next.js sections |
| **Uses compiled languages?** | ✅ Partial (Bash, PowerShell) | Shell scripting patterns | Bash/Shell best practices |
| **Automatic deploy?** | ✅ Yes (GitHub Actions) | CI/CD patterns | GitHub workflows, release automation |
| **Data analysis?** | ❌ No | Skip data science | Remove Python/R analytics |
| **Needs interactive docs?** | ✅ Yes | Documentation patterns | README, guides, examples |
| **Complex state management?** | ❌ No | Skip state management | Remove Redux/Context patterns |

### Filtering Result:
**Active CLAUDE.md Modules:** Shell scripting, Manual Testing Guides, Cross-platform, CI/CD (deploy only), Documentation, Intelligent Recommendations
**Inactive CLAUDE.md Modules:** Frontend (React/Next), Data Science (Python/R analytics), State Management, Automated Testing, Profile Systems

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
6. Manual test execution guides
7. Clear documentation of when/how to run tests
8. NO automatic test execution

**Technical Notes (PRP):**
- Implement as per ADR-006
- Focus on Testing Trophy distribution
- Start with security tests
- Priority: CRITICAL - Trust and transparency

---

## 📚 User Stories

### Epic 1: Developer Setting Up New Machine

#### Story 1.1: Quick Start Installation
**As a** developer new to a machine,  
**I want** to run a single command that sets up a minimal base environment,  
**So that** I can start coding in under 15 minutes.

**Acceptance Criteria:**
1. One-command minimal base installation
2. Essential tools only: modern shell (zsh/oh-my-zsh), CLI tools (bat, eza, fd, ripgrep), git, AI infrastructure, Rust toolchain, Polars (NOT pandas)
3. Process completes in < 15 minutes for minimal base
4. Option to add recommendations after (additional 15 minutes)
5. Clear progress indicators with time remaining
6. Parallel installation where safe

**Technical Notes (PRP):**
- Entry point: `setup.sh` or `main.sh`
- Modular script loading from install/
- Error handling and rollback capability
- Logging to track installation progress

#### Story 1.2: Intelligent Tool Recommendations
**As a** developer with existing projects,  
**I want** to provide my PRD/STORIES files for intelligent recommendations,  
**So that** I get contextual tool suggestions based on my actual needs.

**Acceptance Criteria:**
1. Option to upload or point to PRD.md/STORIES.md files
2. System parses files for technology keywords and patterns
3. Generates grouped recommendations (not profiles)
4. Shows why each tool is recommended
5. User can approve/modify recommendations
6. Falls back to minimal base if no files provided
7. Secure in-memory processing only

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

#### Story 1.6: PRD/STORIES Technology Detection
**As a** developer providing context files,  
**I want** the system to automatically detect my technology stack,  
**So that** recommendations are accurate and relevant.

**Acceptance Criteria:**
1. Detect programming languages mentioned (Python, JavaScript, Rust, etc.)
2. Identify frameworks (React, Django, Express, etc.)
3. Recognize build tools (npm, cargo, make, etc.)
4. Find database mentions (PostgreSQL, MongoDB, etc.)
5. Generate technology confidence scores
6. Handle ambiguous mentions gracefully
7. Extensible detection rules in YAML
8. Use Polars for data processing (NOT pandas)
9. Parse large files efficiently (<1 second)

**Technical Notes (PRP):**
- Keyword mapping database in configs/
- Fuzzy matching for variations
- Context-aware detection
- No external API calls
- Rust backend with Polars for 5-10x performance
- DuckDB for complex analytics queries

#### Story 1.7: Manual Test Execution
**As a** developer who completed installation,  
**I want** clear instructions for running tests manually,  
**So that** I can verify my setup when I choose.

**Acceptance Criteria:**
1. Test commands documented in README and TESTING.md
2. Separate commands for different test types
3. NO automatic execution during or after install
4. Expected output examples provided
5. Troubleshooting guide for failures
6. Platform-specific test variations
7. User explicitly runs tests on demand

**Technical Notes (PRP):**
- Test scripts in tests/manual/
- Clear "WHEN to test" guidelines
- Never hook into installation flow
- Emphasize user control

---

### Epic 2: Platform Parity and Optimization

#### Story 2.1: Mac/Linux Feature Parity
**As a** developer using both Mac and Linux,  
**I want** equivalent functionality on both platforms,  
**So that** my workflow remains consistent.

**Acceptance Criteria:**
1. Same CLI tools available (via Homebrew/apt)
2. Equivalent shell configurations
3. Similar performance (±20%)
4. Platform-specific optimizations documented
5. Feature comparison matrix maintained
6. Migration guide between platforms
7. 45% development effort each

**Technical Notes (PRP):**
- Core/adapter pattern implementation
- Homebrew vs apt abstraction layer
- Functional equivalence over identical tools

#### Story 2.2: Windows Basic Support
**As a** Windows developer needing essential tools,  
**I want** basic development programs installed via winget,  
**So that** I have fundamental capabilities.

**Acceptance Criteria:**
1. Winget installer for common tools only
2. NO automated testing on Windows
3. Clear limitations documented
4. Manual verification steps provided
5. 10% development effort maximum
6. Focus on: Git, VS Code, Node.js, Python
7. WSL2 recommendation prominent

**Technical Notes (PRP):**
- Minimal Windows-specific code
- Leverage winget manifests
- No complex scripting
- Safety over features

---

### Epic 3: IT Professional Mass Deployment

#### Story 3.1: Standardized Workstation Setup
**As an** IT administrator,  
**I want** to deploy consistent configurations across multiple machines,  
**So that** all team members have identical development environments.

**Acceptance Criteria:**
1. Configuration file support
2. Silent/unattended installation mode
3. Centralized configuration management
4. Deployment reporting
5. Rollback capabilities

#### Story 3.2: Compliance and Security
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

### Epic 4: Simplified User Experience

#### Story 4.1: Minimal Base Quick Install
**As a** developer wanting immediate productivity,  
**I want** essential tools installed in under 15 minutes,  
**So that** I can start working quickly.

**Acceptance Criteria:**
1. 15-minute installation target for minimal base
2. Only truly essential tools included
3. No prompts during minimal install
4. Clear "what's included" list shown upfront
5. Option to add recommendations later
6. Progress bar with time remaining
7. Parallel installation where safe

**Technical Notes (PRP):**
- Define "minimal base" precisely in docs
- Optimize download/install order
- Cache frequently used packages
- Background prep for recommendations

#### Story 4.2: Deprecate Profile System
**As a** developer confused by rigid profiles,  
**I want** the old profile system gracefully removed,  
**So that** I'm guided to the new intelligent approach.

**Acceptance Criteria:**
1. Old profile commands show deprecation notice
2. Migration path to new system clear
3. Existing profile configs still work (v3.x compatibility)
4. Documentation updated completely
5. No profile references in new code
6. User data preserved if upgrading
7. Clear benefits of new system explained

**Technical Notes (PRP):**
- Deprecation warnings in v3.2.0
- Full removal in v4.0.0
- Profile → Recommendation mapping
- Gentle user education approach

---

### Epic 5: BMAD Agent Integration

#### Story 5.1: Agent-Assisted Development Workflow
**As a** developer using BMAD Method,  
**I want** agents to help validate my installation choices,  
**So that** I follow best practices automatically.

**Acceptance Criteria:**
1. PM agent reviews PRD completeness
2. PO agent validates story consistency
3. QA agent suggests test strategies (manual only)
4. SM agent helps create implementation tasks
5. Agents provide recommendations only
6. User maintains final decision control
7. Agent rationale always visible

**Technical Notes (PRP):**
- Agents already in minimal base install
- Integration hooks in recommendation engine
- Agent suggestions clearly marked
- Educational, not prescriptive

---

### Epic 6: Linux Enthusiast / Distro Hopper

#### Story 6.1: Distribution Agnostic Scripts
**As a** Linux enthusiast who frequently changes distributions,  
**I want** scripts that work across different distros,  
**So that** I can quickly set up any new system.

**Acceptance Criteria:**
1. Auto-detect distribution and version
2. Package manager abstraction
3. Distro-specific optimizations
4. Desktop environment flexibility
5. Preserve user customizations

#### Story 6.2: Desktop Environment Setup
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
| Developer | Minimal base setup time | < 15 min | 🔄 25 min |
| Developer | Full setup with recommendations | < 30 min | ✅ 25 min |
| IT Admin | Deployment success rate | > 95% | 🔄 Measuring |
| Distro Hopper | Distro compatibility | 10+ distros | ✅ 12 distros |
| Cross-Platform Dev | Mac/Linux feature parity | > 90% | 🟡 20% |
| Windows Dev | Basic tool availability | 100% | 🔴 0% |
| All Users | Manual test documentation | 100% | 🟡 5% |

---

## 🎯 Implementation Priority

### Phase 0 (CRITICAL - Before v3.0.0)
1. 🚨 Story 0.1: Fix APT Lock Security Vulnerability
2. 🚨 Story 0.2: Implement Core/Adapters Architecture
3. 🚨 Story 0.3: Implement Real Testing Framework

### Phase 1 (v3.2.0 - August 2025)
1. 🔄 Minimal base + intelligent recommendations (Stories 1.1, 1.2, 1.6)
2. 🔄 Deprecate profile system (Story 4.2)
3. 🔄 Manual test documentation (Story 1.7)
4. 🔄 BMAD agent integration (Story 5.1)
5. 🔄 PRD/STORIES parsing engine (Story 1.6)

### Phase 2 (v3.3.0 - September 2025)
1. 📋 Mac/Linux feature parity (Story 2.1)
2. 📋 Windows basic support (Story 2.2)
3. 📋 Platform-specific optimizations
4. 📋 Core/adapter architecture implementation
5. 📋 30% manual test coverage

### Phase 3 (v4.0.0 - October 2025)
1. 📋 Complete profile system removal
2. 📋 Full core/adapter pattern
3. 📋 Parallel execution optimization
4. 📋 Enterprise deployment features
5. 📋 15-minute installation achieved

---

## 📝 Notes for CLAUDE.md Application

Based on the answers above, when working on this project:

1. **Shell script best practices** - ShellCheck compliance, error handling, parallel execution
2. **Skip frontend frameworks** - No React, Vue, or web UI code needed
3. **Focus on CLI/TUI patterns** - Command line interfaces, not graphical
4. **Platform optimization** - Mac/Linux 45% each, Windows 10% effort
5. **Manual testing only** - NO automated tests, clear documentation for manual execution
6. **Intelligent recommendations** - Parse PRD/STORIES for context, no rigid profiles
7. **Documentation is critical** - Clear examples, guides, and inline comments
8. **Security first** - Never expose credentials, always validate input, safe package handling
9. **Performance targets** - 15-minute minimal base, 30-minute full setup
10. **BMAD agents assist** - Suggest and educate, don't automate decisions

This modular approach ensures CLAUDE.md provides relevant guidance without overwhelming with irrelevant patterns.