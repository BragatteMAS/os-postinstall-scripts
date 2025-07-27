# Sprint Plan - OS Post-Install Scripts v3.2.0

> **Sprint Master:** Mike (BMAD SM Agent)  
> **Sprint Duration:** 2 weeks (August 1-14, 2025)  
> **Sprint Goal:** Replace profile system with minimal base + intelligent recommendations  
> **Team Velocity:** 40 story points (estimated based on v3.1.0 performance)

## 🎯 Sprint Goal

Transform the rigid 5-profile system into an intelligent, context-aware recommendation engine that provides a minimal base installation in under 15 minutes, followed by smart suggestions based on PRD/STORIES analysis.

## 📊 Sprint Overview

### Key Metrics
- **Total Story Points:** 38
- **High Priority Stories:** 6 (24 points)
- **Medium Priority Stories:** 4 (14 points)
- **Technical Spikes:** 2
- **Sprint Buffer:** 2 points (5%)

### Success Criteria
- [ ] Minimal base installs in < 15 minutes
- [ ] PRD/STORIES parser functional
- [ ] Profile deprecation warnings in place
- [ ] 30% manual test coverage achieved
- [ ] BMAD agents integrated into workflow
- [ ] All tests remain manual/on-demand

## 📋 Sprint Backlog

### Epic 1: Developer Setting Up New Machine

#### 🔴 Story 1.1: Quick Start Installation (8 points)
**Priority:** HIGH  
**Assignee:** Core Team  
**Definition of Done:**
- [ ] One-command minimal base installation functional
- [ ] Essential tools defined and documented (zsh, CLI tools, git, AI)
- [ ] Installation completes in < 15 minutes
- [ ] Progress indicators implemented with time remaining
- [ ] Parallel installation implemented where safe
- [ ] Manual test script created in tests/manual/

**Implementation Tasks:**
1. Define minimal base tool list in configs/minimal-base.yaml (2h)
2. Create setup-minimal.sh entry point (4h)
3. Implement parallel installation logic (6h)
4. Add progress tracking with whiptail/dialog (4h)
5. Create manual test suite for verification (2h)
6. Document in README and quick-start guide (2h)

**Dependencies:** None  
**Risks:** Parallel installation may cause lock conflicts

---

#### 🔴 Story 1.6: PRD/STORIES Technology Detection (13 points)
**Priority:** HIGH  
**Assignee:** Core Team  
**Definition of Done:**
- [ ] Parser detects programming languages accurately
- [ ] Framework identification working (React, Django, etc.)
- [ ] Build tool detection functional
- [ ] Database technology recognition
- [ ] Confidence scoring implemented
- [ ] YAML-based detection rules created
- [ ] Manual test coverage complete

**Implementation Tasks:**
1. Create utils/document-parser.sh (8h)
2. Develop keyword mapping in configs/tech-keywords.yaml (4h)
3. Implement fuzzy matching algorithm (6h)
4. Add confidence scoring system (4h)
5. Create recommendation generator (6h)
6. Build manual test suite with sample PRDs (4h)
7. Document parser usage and extension (2h)

**Technical Spike Required:** Research text parsing in Bash/Python
**Dependencies:** None  
**Risks:** Complex parsing logic may need Python helper

---

#### 🟡 Story 1.7: Manual Test Execution (3 points)
**Priority:** MEDIUM  
**Assignee:** QA Focus  
**Definition of Done:**
- [ ] Test commands documented in README
- [ ] TESTING.md updated with manual procedures
- [ ] Separate commands for test types
- [ ] NO automatic execution hooks
- [ ] Expected output examples provided
- [ ] Platform-specific variations documented

**Implementation Tasks:**
1. Create tests/manual/README.md with instructions (2h)
2. Update TESTING.md with manual test philosophy (1h)
3. Create example test outputs (2h)
4. Add troubleshooting guide (1h)

**Dependencies:** Story 1.1 completion  
**Risks:** None

---

### Epic 4: Simplified User Experience

#### 🔴 Story 4.2: Deprecate Profile System (5 points)
**Priority:** HIGH  
**Assignee:** Core Team  
**Definition of Done:**
- [ ] Deprecation warnings implemented
- [ ] Migration guide created
- [ ] v3.x compatibility maintained
- [ ] Documentation updated
- [ ] User data preservation verified
- [ ] Benefits clearly communicated

**Implementation Tasks:**
1. Add deprecation notices to setup-with-profile.sh (2h)
2. Create MIGRATION.md guide (3h)
3. Implement profile → recommendation mapping (4h)
4. Update all documentation (2h)
5. Create backward compatibility layer (3h)

**Dependencies:** Story 1.6 (for recommendation mapping)  
**Risks:** User resistance to change

---

### Epic 5: BMAD Agent Integration

#### 🔴 Story 5.1: Agent-Assisted Development Workflow (8 points)
**Priority:** HIGH  
**Assignee:** AI Integration Team  
**Definition of Done:**
- [ ] PM agent reviews PRD completeness
- [ ] PO agent validates story consistency
- [ ] QA agent suggests manual test strategies
- [ ] SM agent helps create tasks
- [ ] Agent suggestions clearly marked
- [ ] User control maintained

**Implementation Tasks:**
1. Create utils/bmad-integration.sh (4h)
2. Implement agent hooks in recommendation engine (6h)
3. Add agent suggestion UI (4h)
4. Create agent override mechanism (2h)
5. Document agent interactions (2h)

**Dependencies:** BMAD v4.32.0 installed (already complete)  
**Risks:** Over-reliance on agent suggestions

---

### Epic 2: Platform Parity and Optimization

#### 🟡 Story 2.1: Mac/Linux Feature Parity Planning (5 points)
**Priority:** MEDIUM  
**Assignee:** Platform Team  
**Definition of Done:**
- [ ] Feature comparison matrix created
- [ ] Homebrew/apt abstraction designed
- [ ] Migration guide outlined
- [ ] Platform-specific optimizations identified
- [ ] Implementation plan for v3.3.0

**Implementation Tasks:**
1. Audit current Mac/Linux differences (4h)
2. Create feature parity matrix (2h)
3. Design core/adapter pattern (4h)
4. Document platform roadmap (2h)

**Technical Spike Required:** Homebrew vs apt feature analysis
**Dependencies:** None  
**Risks:** Scope for v3.3.0, not v3.2.0

---

#### 🟢 Story 2.2: Windows Basic Support Planning (3 points)
**Priority:** LOW  
**Assignee:** Platform Team  
**Definition of Done:**
- [ ] Winget capabilities assessed
- [ ] Basic tool list defined
- [ ] Limitations documented
- [ ] WSL2 recommendation added

**Implementation Tasks:**
1. Research winget manifests (2h)
2. Define Windows tool subset (2h)
3. Create Windows limitations doc (2h)

**Dependencies:** None  
**Risks:** Minimal - planning only for v3.3.0

---

### Technical Spikes

#### 🔵 Spike 1: Text Parsing Performance
**Duration:** 1 day  
**Goal:** Determine optimal approach for PRD/STORIES parsing
**Options to Evaluate:**
- Pure Bash with grep/sed/awk
- Python helper script
- Hybrid approach

#### 🔵 Spike 2: Parallel Installation Safety
**Duration:** 0.5 days  
**Goal:** Identify safe parallelization opportunities
**Areas to Test:**
- Package manager locks
- Dependency chains
- Resource constraints

## 📅 Sprint Schedule

### Week 1 (August 1-7)
- **Day 1-2:** Technical spikes + Story 1.1 start
- **Day 3-4:** Story 1.6 (PRD parser) development
- **Day 5:** Story 1.1 completion + manual tests

### Week 2 (August 8-14)
- **Day 6-7:** Story 4.2 (deprecation) + 5.1 start
- **Day 8-9:** Story 5.1 (BMAD integration) completion
- **Day 10:** Stories 1.7, 2.1, 2.2 + sprint review prep

## 🚧 Impediments and Risks

### Identified Impediments
1. **Single developer bandwidth** - Mitigation: Clear priorities, automated tooling
2. **Complex parsing logic** - Mitigation: Technical spike, consider Python helper
3. **User adoption resistance** - Mitigation: Clear benefits communication, gentle migration

### Risk Matrix
| Risk | Impact | Probability | Mitigation |
|------|---------|------------|------------|
| Parsing complexity | High | Medium | Python fallback ready |
| 15-min target missed | Medium | Low | Parallel execution |
| Profile user backlash | Medium | Medium | Compatibility layer |
| Manual test confusion | Low | Medium | Clear documentation |

## 📊 Definition of Done (Sprint Level)

### Code Complete
- [ ] All implementation tasks completed
- [ ] Code follows project standards (shellcheck clean)
- [ ] Comments added (## style for shell)
- [ ] No hardcoded values

### Testing Complete
- [ ] Manual test scripts created
- [ ] Test documentation updated
- [ ] NO automated test execution
- [ ] Platform variations documented

### Documentation Complete
- [ ] README.md updated
- [ ] CHANGELOG.md entry added
- [ ] Migration guide created
- [ ] User guides updated

### Review Complete
- [ ] Code review by BMAD agents
- [ ] Sprint demo prepared
- [ ] Retrospective items collected

## 🎯 Sprint Ceremonies

### Sprint Planning (Completed)
- This document represents planning output
- All stories estimated using Fibonacci
- Capacity planned at 90% (buffer included)

### Daily Standups
- Format: What I did, What I'll do, Blockers
- Focus on sprint goal progress
- Update STATUS.md daily

### Sprint Review (August 14)
- Demo minimal base installation
- Show PRD/STORIES parser in action
- Present deprecation approach
- Gather stakeholder feedback

### Sprint Retrospective (August 14)
- What went well?
- What could improve?
- Action items for v3.3.0

## 📈 Tracking and Metrics

### Burndown Tracking
- Update daily in STATUS.md
- Track by story points
- Monitor 15-minute target

### Quality Metrics
- Manual test coverage: Target 30%
- Installation time: Target < 15 min
- Parser accuracy: Target > 85%

### Success Indicators
- ✅ Minimal base < 15 minutes
- ✅ Intelligent recommendations working
- ✅ Smooth profile migration path
- ✅ BMAD agents providing value
- ✅ All tests remain manual

## 🔄 Next Sprint Preview (v3.3.0)

Based on v3.2.0 outcomes, v3.3.0 will focus on:
1. **Platform Parity** - Mac/Linux 45% each, Windows 10%
2. **Core/Adapter Implementation** - Clean architecture
3. **Performance Optimization** - Caching, parallel execution
4. **Test Coverage Expansion** - 50% manual coverage target

---

> **Note:** This sprint plan follows BMAD Method principles while maintaining flexibility for the single-developer reality. All dates are targets, not commitments. Manual testing philosophy is maintained throughout.

> **Remember:** "Simplification Over Features" - Every decision should make the system easier to use, not more complex.