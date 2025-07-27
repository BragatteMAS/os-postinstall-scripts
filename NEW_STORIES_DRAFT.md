# New Stories Draft - Based on PRD v2.0.0 Promises

> **Created:** 2025-01-27 | **Purpose:** Fill gaps in STORIES.md

## 🆕 Epic 2: Intelligent Installation System

### Story 2.1: Project Context Upload
**As a** developer setting up a new machine,  
**I want** to provide my project's PRD and STORIES files,  
**So that** the system can understand my specific needs.

**Acceptance Criteria:**
1. Option to upload or point to PRD.md/STORIES.md files
2. Support for multiple project contexts
3. File validation (must be valid Markdown)
4. Preview of detected information
5. Ability to proceed without files (minimal base only)
6. Secure handling (no files stored permanently)

**Technical Notes (PRP):**
- Parse files in memory only
- Extract technology keywords using regex
- Build context map for recommendations
- No external API calls

### Story 2.2: Technology Detection Engine
**As a** developer with existing projects,  
**I want** the system to detect my technology stack automatically,  
**So that** I get relevant tool recommendations.

**Acceptance Criteria:**
1. Detect programming languages (Python, JavaScript, Rust, etc.)
2. Identify frameworks (React, Django, Express, etc.)
3. Recognize build tools (npm, cargo, make, etc.)
4. Find database mentions (PostgreSQL, MongoDB, etc.)
5. Identify deployment targets (Docker, Kubernetes, etc.)
6. Generate technology confidence scores
7. Handle ambiguous mentions gracefully

**Technical Notes (PRP):**
- Keyword mapping database in YAML
- Fuzzy matching for variations
- Context-aware detection (avoid false positives)
- Extensible detection rules

### Story 2.3: Intelligent Recommendation Generation
**As a** developer reviewing detected technologies,  
**I want** to see grouped tool recommendations with explanations,  
**So that** I understand why each tool is suggested.

**Acceptance Criteria:**
1. Tools grouped by purpose (not profiles)
2. Clear explanation for each recommendation
3. Dependencies highlighted
4. Installation time estimates
5. Disk space requirements shown
6. Conflict warnings if applicable
7. "Essential" vs "Recommended" vs "Optional" tags

**Technical Notes (PRP):**
- Recommendation engine using PRD context
- Tool metadata includes rationale
- Dynamic grouping based on stack
- User education focus

### Story 2.4: Manual Test Execution Guide
**As a** developer who completed installation,  
**I want** clear instructions for running tests manually,  
**So that** I can verify my setup when I choose.

**Acceptance Criteria:**
1. Test commands documented in README
2. Separate commands for different test types
3. NO automatic execution during install
4. Expected output examples provided
5. Troubleshooting guide for failures
6. Time estimates for test suites
7. Platform-specific test variations

**Technical Notes (PRP):**
- Test runner scripts in tests/manual/
- Clear "WHEN to test" guidelines
- "WHAT to test" checklists
- Never hook into installation flow

## 🆕 Epic 3: Platform Parity Initiative

### Story 3.1: Mac/Linux Feature Parity
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
- Core/adapter pattern critical here
- Homebrew vs apt abstraction layer
- Platform detection automatic
- Functional equivalence over identical tools

### Story 3.2: Windows Basic Support
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

## 🆕 Epic 4: Simplified User Experience

### Story 4.1: Minimal Base Quick Install
**As a** developer wanting immediate productivity,  
**I want** essential tools installed in under 15 minutes,  
**So that** I can start working quickly.

**Acceptance Criteria:**
1. 15-minute installation target
2. Only truly essential tools
3. No prompts during minimal install
4. Clear "what's included" list
5. Option to add more later
6. Progress bar with time remaining
7. Parallel installation where safe

**Technical Notes (PRP):**
- Define "minimal base" precisely
- Optimize download/install order
- Cache frequently used packages
- Background recommendations prep

### Story 4.2: Deprecate Profile System
**As a** developer confused by rigid profiles,  
**I want** the old profile system gracefully removed,  
**So that** I'm guided to the new intelligent approach.

**Acceptance Criteria:**
1. Old profile commands show deprecation notice
2. Migration path to new system clear
3. Existing profile configs still work (compatibility)
4. Documentation updated completely
5. No profile references in new code
6. User data preserved if upgrading
7. Clear benefits of new system explained

**Technical Notes (PRP):**
- Deprecation warnings in v3.2.0
- Full removal in v4.0.0
- Profile → Recommendation mapping
- Gentle user education

## 🆕 Epic 5: BMAD Agent Integration

### Story 5.1: Agent-Assisted Development Workflow
**As a** developer using BMAD Method,  
**I want** agents to help validate my installation choices,  
**So that** I follow best practices automatically.

**Acceptance Criteria:**
1. PM agent reviews PRD completeness
2. PO agent validates story consistency
3. QA agent suggests test strategies
4. SM agent helps create tasks
5. Agents provide recommendations only
6. User maintains final decision control
7. Agent rationale always visible

**Technical Notes (PRP):**
- Agents already installed in minimal base
- Integration hooks in recommendation engine
- Agent suggestions clearly marked
- Educational, not prescriptive

---

## 📋 Integration Notes

These stories should be integrated into STORIES.md following the existing structure:
1. Add Epic 2 after current Epic 1
2. Insert test stories into Epic 0
3. Platform stories become Epic 3
4. Update version references to v3.2.0
5. Maintain existing story numbering where possible

*These drafts ensure PRD v2.0.0 promises have concrete implementation paths*