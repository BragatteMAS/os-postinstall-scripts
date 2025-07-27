# Implementation Tasks for v3.2.0 Stories

> **Sprint:** v3.2.0 - Intelligent Recommendations  
> **Created by:** Mike (BMAD SM Agent)  
> **Date:** 2025-01-27  
> **Purpose:** Detailed technical tasks for each user story

## 📋 Story Implementation Breakdown

### Story 1.6: PRD/STORIES Technology Detection (13 points)

#### Task 1.6.1: Create Document Parser Foundation
**Estimate:** 4 hours  
**Dependencies:** None  
**Technical Details:**
```bash
# Create utils/document-parser.sh
#!/usr/bin/env bash
set -euo pipefail

# Functions needed:
# - parse_markdown_file()
# - extract_technology_mentions()
# - calculate_confidence_scores()
# - generate_recommendations()
```

**Acceptance Criteria:**
- [ ] Handles missing files gracefully
- [ ] Supports both PRD.md and STORIES.md
- [ ] Returns structured data (JSON or associative array)
- [ ] Includes debug mode for troubleshooting

#### Task 1.6.2: Technology Keyword Database
**Estimate:** 3 hours  
**Dependencies:** None  
**Location:** `configs/tech-keywords.yaml`

```yaml
# Example structure
languages:
  python:
    keywords: ["python", "pip", "django", "flask", "pandas", "numpy"]
    confidence_boost: ["import", "def", "__init__", "requirements.txt"]
    tools: ["python3", "pip", "pyenv", "poetry", "uv"]
    
  javascript:
    keywords: ["javascript", "node", "npm", "react", "vue", "angular"]
    confidence_boost: ["package.json", "const", "let", "var", "=>"]
    tools: ["nodejs", "npm", "yarn", "pnpm", "nvm"]
    
frameworks:
  web:
    react: ["react", "jsx", "useState", "useEffect", "component"]
    django: ["django", "models.py", "views.py", "urls.py", "migrations"]
    
databases:
  sql:
    postgresql: ["postgres", "postgresql", "psql", "pg_"]
    mysql: ["mysql", "mariadb", "mysqli"]
  nosql:
    mongodb: ["mongo", "mongodb", "mongoose", "collection"]
```

#### Task 1.6.3: Fuzzy Matching Implementation
**Estimate:** 6 hours  
**Dependencies:** Task 1.6.1  
**Technical Approach:**
- Use grep with -i flag for case-insensitive
- Implement Levenshtein distance for typos
- Consider context (surrounding words)
- Weight by location (headings > body text)

#### Task 1.6.4: Confidence Scoring Algorithm
**Estimate:** 4 hours  
**Dependencies:** Tasks 1.6.2, 1.6.3  
**Scoring Factors:**
- Keyword frequency (normalized)
- Context relevance (in code blocks = higher)
- Explicit mentions vs. implicit
- Co-occurrence patterns

#### Task 1.6.5: Recommendation Generator
**Estimate:** 6 hours  
**Dependencies:** All above tasks  
**Output Format:**
```bash
# Recommended tools based on your project:
## High Confidence (90%+)
- Python development environment (uv, pyenv)
- PostgreSQL database tools
- Docker for containerization

## Medium Confidence (60-89%)
- React development tools (if frontend detected)
- API testing tools (Postman, HTTPie)

## Low Confidence (30-59%)
- Data science tools (Jupyter, pandas) - mentioned but not primary
```

#### Task 1.6.6: Manual Test Suite
**Estimate:** 4 hours  
**Dependencies:** All implementation complete  
**Test Scenarios:**
```bash
# tests/manual/test-document-parser.sh
# Test cases:
# 1. Python data science project
# 2. Full-stack JavaScript project  
# 3. DevOps infrastructure project
# 4. Mixed technology project
# 5. Minimal/unclear project
# 6. Missing files scenario
```

---

### Story 1.7: Manual Test Execution (3 points)

#### Task 1.7.1: Create Manual Test Structure
**Estimate:** 2 hours  
**Location:** `tests/manual/`
```
tests/manual/
├── README.md                    # Master test guide
├── test-minimal-base.sh        # Test minimal installation
├── test-recommendation-engine.sh # Test PRD parsing
├── test-profile-migration.sh   # Test deprecation flow
├── test-bmad-integration.sh    # Test agent integration
└── expected-outputs/           # Reference outputs
    ├── minimal-base.txt
    ├── parser-python.txt
    └── parser-fullstack.txt
```

#### Task 1.7.2: Document Test Execution
**Estimate:** 1 hour  
**Content for TESTING.md:**
```markdown
## Manual Test Execution

### When to Run Tests
- NEVER automatically during installation
- After making changes to core scripts
- Before creating a pull request
- When debugging user issues

### How to Run Tests
```bash
# Run all manual tests (takes ~10 minutes)
./tests/manual/run-all-tests.sh

# Run specific test suite
./tests/manual/test-minimal-base.sh

# Run with verbose output
DEBUG=1 ./tests/manual/test-recommendation-engine.sh
```

### Interpreting Results
Each test outputs:
- ✅ PASS: Expected behavior confirmed
- ❌ FAIL: Unexpected result (with details)
- ⚠️ WARN: Non-critical issue detected
- 📋 INFO: Relevant information
```

---

### Story 4.2: Deprecate Profile System (5 points)

#### Task 4.2.1: Add Deprecation Warnings
**Estimate:** 2 hours  
**Files to Update:**
- `scripts/setup/with-profile.sh`
- `scripts/utils/profile-loader.sh`
- `configs/profiles/README.md`

**Warning Format:**
```bash
echo "⚠️  DEPRECATION WARNING: Profile system is deprecated in v3.2.0"
echo "    The rigid profile system will be removed in v4.0.0"
echo "    "
echo "    🎯 New approach: Minimal base + intelligent recommendations"
echo "    📄 Provide your PRD.md/STORIES.md for personalized suggestions"
echo "    "
echo "    Migration guide: docs/PROFILE_MIGRATION.md"
echo "    "
echo "    Press Enter to continue with legacy profile (not recommended)"
echo "    Or press Ctrl+C to use the new intelligent system"
read -r
```

#### Task 4.2.2: Create Migration Guide
**Estimate:** 3 hours  
**Location:** `docs/PROFILE_MIGRATION.md`
**Content Structure:**
1. Why we're deprecating profiles
2. Benefits of the new system
3. Migration paths for each profile
4. How to preserve customizations
5. FAQ

#### Task 4.2.3: Profile to Recommendation Mapping
**Estimate:** 4 hours  
**Implementation:**
```bash
# utils/profile-to-recommendations.sh
map_profile_to_recommendations() {
    local profile=$1
    case $profile in
        "developer-standard")
            echo "Detected legacy 'developer-standard' profile"
            echo "Recommended minimal base includes all your essentials"
            echo "Additional recommendations based on your projects..."
            ;;
        "data-scientist")
            echo "Detected legacy 'data-scientist' profile"
            echo "Analyzing your notebooks and scripts for better recommendations..."
            # Trigger PRD analysis for Python/R tools
            ;;
    esac
}
```

---

### Story 5.1: Agent-Assisted Development Workflow (8 points)

#### Task 5.1.1: BMAD Integration Layer
**Estimate:** 4 hours  
**Location:** `utils/bmad-integration.sh`
**Core Functions:**
```bash
# Check PRD completeness with PM agent
check_prd_completeness() {
    echo "🤖 PM Agent: Reviewing PRD completeness..."
    # Check for required sections
    # Validate objectives clarity
    # Ensure success metrics defined
}

# Validate stories with PO agent
validate_story_consistency() {
    echo "🤖 PO Agent: Validating story consistency..."
    # Check acceptance criteria
    # Verify user journey mapping
    # Ensure focal questions answered
}

# Get test suggestions from QA agent
suggest_test_strategies() {
    echo "🤖 QA Agent: Suggesting manual test strategies..."
    echo "    Remember: All tests are manual and on-demand"
    # Suggest test scenarios
    # Provide test data examples
    # Recommend edge cases
}

# Task breakdown with SM agent
create_implementation_tasks() {
    echo "🤖 SM Agent: Breaking down into tasks..."
    # Estimate story points
    # Identify dependencies
    # Suggest task order
}
```

#### Task 5.1.2: Agent UI Integration
**Estimate:** 4 hours  
**Approach:**
- Use whiptail/dialog for agent suggestions
- Clear "Agent Suggestion" prefix
- Always show rationale
- Provide override options

#### Task 5.1.3: Agent Override Mechanism
**Estimate:** 2 hours  
**Implementation:**
```bash
# Every agent suggestion includes:
show_agent_suggestion() {
    local agent=$1
    local suggestion=$2
    local rationale=$3
    
    whiptail --title "$agent Suggestion" \
             --yesno "$suggestion\n\nRationale: $rationale\n\nAccept this suggestion?" \
             15 60
    
    if [ $? -eq 0 ]; then
        apply_suggestion "$suggestion"
    else
        log "User rejected $agent suggestion"
        get_user_alternative
    fi
}
```

---

### Story 2.1: Mac/Linux Feature Parity Planning (5 points)

#### Task 2.1.1: Platform Audit Script
**Estimate:** 4 hours  
**Location:** `tools/dev/platform-feature-audit.sh`
**Output:** Feature comparison matrix in Markdown

#### Task 2.1.2: Core/Adapter Pattern Design
**Estimate:** 4 hours  
**Architecture Documentation:**
```
core/
├── interfaces/
│   ├── package-manager.sh    # Abstract interface
│   ├── shell-config.sh       # Shell setup interface
│   └── tool-installer.sh     # Tool installation interface
└── adapters/
    ├── apt/                  # Debian/Ubuntu adapter
    ├── homebrew/            # macOS adapter
    ├── dnf/                 # Fedora adapter
    └── winget/              # Windows adapter
```

---

### Story 2.2: Windows Basic Support Planning (3 points)

#### Task 2.2.1: Winget Capability Assessment
**Estimate:** 2 hours  
**Research Areas:**
- Available packages
- Installation reliability
- Unattended mode support
- Error handling

#### Task 2.2.2: Windows Tool Subset Definition
**Estimate:** 2 hours  
**Basic Tools List:**
```yaml
windows_basic_tools:
  essential:
    - git
    - vscode
    - nodejs
    - python
    - docker-desktop
  optional:
    - postman
    - dbeaver
    - putty
    - wsl
```

#### Task 2.2.3: Windows Limitations Documentation
**Estimate:** 2 hours  
**Key Points:**
- No automated testing
- Basic tool installation only
- WSL2 strongly recommended
- Manual verification required

## 🏗️ Implementation Order

### Week 1 Priority Path:
1. **Day 1:** Technical spikes (parsing, parallel safety)
2. **Day 2:** Story 1.1 - Tasks 1-3 (minimal base foundation)
3. **Day 3:** Story 1.6 - Tasks 1-3 (parser core)
4. **Day 4:** Story 1.6 - Tasks 4-6 (scoring and recommendations)
5. **Day 5:** Story 1.1 - Tasks 4-6 (progress UI and tests)

### Week 2 Priority Path:
6. **Day 6:** Story 4.2 - All tasks (deprecation)
7. **Day 7:** Story 5.1 - Tasks 1-2 (BMAD integration)
8. **Day 8:** Story 5.1 - Task 3 + Story 1.7 (agent override + manual tests)
9. **Day 9:** Stories 2.1 & 2.2 (platform planning)
10. **Day 10:** Integration testing + sprint review prep

## 📝 Technical Decisions Log

### Decision 1: Parser Language
**Options Considered:**
- Pure Bash (grep/sed/awk)
- Python helper script
- Hybrid approach

**Decision:** Start with Bash, fallback to Python if needed
**Rationale:** Maintains consistency, avoids dependencies

### Decision 2: Parallel Installation
**Safe to Parallelize:**
- Language installations (Python, Node, Rust)
- Development tools (different categories)
- Configuration file creation

**Must Serialize:**
- Package manager operations
- System updates
- Shell configuration

### Decision 3: Deprecation Timeline
**v3.2.0:** Warnings only, full compatibility
**v3.x:** Reduced functionality, migration prompts
**v4.0.0:** Complete removal

## 🚀 Quick Start for Developers

```bash
# 1. Check out v3.2.0 branch
git checkout -b feature/v3.2.0-intelligent-recommendations

# 2. Start with minimal base story
cd scripts/setup
cp main.sh setup-minimal.sh

# 3. Run technical spike scripts
./tools/dev/test-parallel-safety.sh
./tools/dev/test-parser-performance.sh

# 4. Implement according to task order above

# 5. Test manually (NEVER automatically)
./tests/manual/test-minimal-base.sh
```

---

> **Remember:** Every implementation decision should support our sprint goal: "Simplify the user experience with intelligent, context-aware recommendations instead of rigid profiles."