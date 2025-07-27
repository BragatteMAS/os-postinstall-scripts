# STORIES.md Update Tasks - Sharded from PRD v2.0.0

> **Generated:** 2025-01-27 | **Source:** PRD.md | **Target:** STORIES.md

## 🔧 Task List for STORIES.md Updates

### Task Group 1: Profile System Replacement

**From PRD Section**: Migration Strategy - Phase 1
**PRD Quote**: "Replace 5-profile system with minimal base + intelligent recommendations"

**Required STORIES Updates**:

1. **Task 1.1**: Delete current Story 1.2 profile selection
   - Remove: "Preset profiles: Web Dev, Data Science, DevOps, Mobile, Embedded"
   - Remove: Profile-related acceptance criteria
   
2. **Task 1.2**: Create new Story 1.2 "Intelligent Recommendations"
   - Add: User uploads/points to PRD.md and STORIES.md
   - Add: System parses for technology keywords
   - Add: Contextual tool suggestions generated
   - Add: User approves/modifies recommendations

3. **Task 1.3**: Define minimal base components
   - Modern shell (zsh, oh-my-zsh, starship)
   - CLI tools (bat, eza, fd, ripgrep, zoxide)
   - Version control (git, gh cli)
   - AI infrastructure (MCPs, BMAD agents)

### Task Group 2: Testing Philosophy Alignment

**From PRD Section**: Success Metrics - Quality
**PRD Quote**: "ALL tests are on-demand only (never automatic)"

**Required STORIES Updates**:

4. **Task 2.1**: Update Story 0.3 test framework
   - Change: "CI/CD running all tests" → "Manual test execution guides"
   - Add: "Tests ONLY run via explicit user command"
   - Add: "No test hooks in installation process"

5. **Task 2.2**: Add new test execution story
   - Title: "Manual Test Execution"
   - Define: Test commands structure
   - Define: When to run tests
   - Define: How to interpret results

### Task Group 3: Performance Targets

**From PRD Section**: Success Metrics - Performance
**PRD Quote**: "Minimal base installation: 15 minutes (from 25)"

**Required STORIES Updates**:

6. **Task 3.1**: Split Story 1.1 installation times
   - Update: "< 30 minutes" → "< 15 minutes for minimal base"
   - Add: "< 30 minutes for full setup with recommendations"

7. **Task 3.2**: Create minimal base installation story
   - Define what's included in 15-minute install
   - Separate from recommendation phase

### Task Group 4: Intelligent Features

**From PRD Section**: Functional Requirements - Intelligent Installation
**PRD Quote**: "PRD/STORIES parsing for technology detection"

**Required STORIES Updates**:

8. **Task 4.1**: Create "Project Analysis" epic
   - Story: "PRD/STORIES Upload"
   - Story: "Technology Detection"
   - Story: "Recommendation Generation"
   - Story: "User Approval Flow"

9. **Task 4.2**: Add parsing acceptance criteria
   - Detect: Programming languages mentioned
   - Detect: Frameworks and tools
   - Detect: Deployment targets
   - Map to: Available installation modules

### Task Group 5: Platform Strategy

**From PRD Section**: Success Metrics - Platform Support
**PRD Quote**: "Linux: 45% effort, macOS: 45% effort, Windows: 10% effort"

**Required STORIES Updates**:

10. **Task 5.1**: Create platform-specific epic
    - Mac story: "Achieve Mac/Linux Feature Parity"
    - Windows story: "Basic Program Installation"
    - Linux story: "Maintain Excellence"

11. **Task 5.2**: Add platform constraints
    - Mac: Focus on Homebrew optimization
    - Windows: Winget only, no automation
    - Linux: Continue current approach

### Task Group 6: BMAD Integration

**From PRD Section**: Migration Strategy - BMAD Agents
**PRD Quote**: "Implement BMAD agent workflow (PM→PO→QA→SM)"

**Required STORIES Updates**:

12. **Task 6.1**: Create BMAD workflow story
    - PM validates requirements
    - PO ensures consistency
    - QA defines test strategy
    - SM creates implementation stories

## 📋 Execution Priority

1. **Critical** (Do First): Tasks 2.1, 2.2, 4.1, 4.2
2. **High** (Do Second): Tasks 1.1, 1.2, 1.3, 6.1
3. **Medium** (Do Third): Tasks 3.1, 3.2, 5.1, 5.2

## ✅ Validation Checklist

- [ ] Each PRD promise has corresponding story
- [ ] No conflicts in philosophy
- [ ] Performance metrics aligned
- [ ] Platform priorities clear
- [ ] Test approach consistent

---

*Use this task list to systematically update STORIES.md*