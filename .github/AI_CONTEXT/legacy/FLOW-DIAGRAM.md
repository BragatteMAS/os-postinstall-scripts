# Documentation Flow Diagram

## Interactive Mermaid Diagram

```mermaid
flowchart TB
    Start([🚀 Start]) --> FirstTime{First Time?}
    
    FirstTime -->|Yes| Setup[📦 make setup<br/>Initial Configuration]
    FirstTime -->|No| MainMenu[📋 Choose Documentation Type]
    
    Setup --> MainMenu
    
    MainMenu --> AI[🤖 AI Context]
    MainMenu --> Deps[📦 Dependencies]
    MainMenu --> Change[📝 Changelog]
    MainMenu --> IP[🛡️ IP/Patent]
    MainMenu --> Monitor[🔍 Monitor]
    MainMenu --> All[📊 All Docs]
    
    %% AI Context Branch
    AI --> AIChoice{Choose Method}
    AIChoice --> AI1[Interactive<br/>npx create-ai-context]
    AIChoice --> AI2[Auto-Detect<br/>smart-ai-detector.sh]
    AIChoice --> AI3[From Git<br/>auto-generate-from-git.sh]
    AIChoice --> AI4[Minimal<br/>minimal-setup.sh]
    
    AI1 --> AITool{Select AI Tool}
    AI2 --> AITool
    AI3 --> AIResult[📁 .ai/ Created]
    AI4 --> AIResult
    
    AITool --> Claude[Claude.md]
    AITool --> Copilot[.github/<br/>copilot-instructions.md]
    AITool --> Cursor[.cursorrules]
    AITool --> ChatGPT[OPENAI_CODEX.md]
    AITool --> Gemini[GEMINI_CONTEXT.md]
    AITool --> Generic[AI_ASSISTANT.md]
    
    Claude --> AIResult
    Copilot --> AIResult
    Cursor --> AIResult
    ChatGPT --> AIResult
    Gemini --> AIResult
    Generic --> AIResult
    
    %% Dependencies Branch
    Deps --> Req[make requirements]
    Req --> DetectLang{Detect Languages}
    
    DetectLang --> Python[🐍 Python<br/>requirements.txt]
    DetectLang --> NodeJS[📦 Node.js<br/>package.json]
    DetectLang --> Rust[🦀 Rust<br/>Cargo.toml]
    DetectLang --> Go[🐹 Go<br/>go.mod]
    DetectLang --> Ruby[💎 Ruby<br/>Gemfile]
    DetectLang --> PHP[🐘 PHP<br/>composer.json]
    
    Python --> ReqResult[📁 requirements/]
    NodeJS --> ReqResult
    Rust --> ReqResult
    Go --> ReqResult
    Ruby --> ReqResult
    PHP --> ReqResult
    
    ReqResult --> License[make licenses]
    License --> LicenseAnalysis[⚖️ Analyze Licenses]
    LicenseAnalysis --> LicResult[📁 licenses/]
    
    %% Changelog Branch
    Change --> ChLog[make changelog]
    ChLog --> Template[Read CHANGELOG.template.md]
    Template --> Dates[Insert Dynamic Dates]
    Dates --> ChResult[📄 CHANGELOG.md]
    
    %% IP Documentation Branch
    IP --> IPDocs[make ip-docs]
    IPDocs --> Gather[Gather All Docs]
    Gather --> Package[Create Package]
    Package --> IPResult[📦 ip-documentation-*.tar.gz]
    
    %% Monitor Branch
    Monitor --> MonDeps[make monitor-deps]
    MonDeps --> CheckChanges[Check Changes]
    CheckChanges --> Security[Security Scan]
    Security --> MonResult[📁 .dependency-monitor/]
    
    %% All Docs Branch
    All --> AllDocs[make all-docs]
    AllDocs --> Req
    AllDocs --> ChLog
    AllDocs --> IPDocs
    
    %% Final Results
    AIResult --> Success[✅ AI Context Ready]
    ReqResult --> Success2[✅ Dependencies Tracked]
    LicResult --> Success3[✅ Licenses Documented]
    ChResult --> Success4[✅ Changelog Updated]
    IPResult --> Success5[✅ IP Package Ready]
    MonResult --> Success6[✅ Monitoring Active]
    
    style Start fill:#e1f5e1
    style Success fill:#c8e6c9
    style Success2 fill:#c8e6c9
    style Success3 fill:#c8e6c9
    style Success4 fill:#c8e6c9
    style Success5 fill:#c8e6c9
    style Success6 fill:#c8e6c9
    style AI fill:#e3f2fd
    style Deps fill:#fff3e0
    style Change fill:#f3e5f5
    style IP fill:#ffebee
    style Monitor fill:#e0f2f1
    style All fill:#fce4ec
```

## Simplified ASCII Flow

```
                    ┌─────────────┐
                    │   START     │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │ First Time? │
                    └──┬───────┬──┘
                       │       │
                    NO │       │ YES
                       │       │
                       │  ┌────▼─────┐
                       │  │   make   │
                       │  │  setup   │
                       │  └────┬─────┘
                       │       │
                    ┌──▼───────▼──┐
                    │   Choose:   │
                    └──────┬──────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   ┌────▼────┐      ┌──────▼──────┐    ┌─────▼─────┐
   │   AI    │      │ Dependencies │    │ IP/Patent │
   │ Context │      │  & Licenses  │    │   Docs    │
   └────┬────┘      └──────┬──────┘    └─────┬─────┘
        │                  │                  │
        ▼                  ▼                  ▼
   Select Tool:       make requirements   make ip-docs
   • Claude          make licenses
   • Copilot         make monitor-deps
   • Cursor
   • ChatGPT
   • Gemini
```

## Quick Reference Card

### 🎯 By Goal

| I want to... | Run this... | Get this... |
|--------------|-------------|-------------|
| Help AI understand my code | `npx create-ai-context` | `.ai/` folder with context |
| Track what I'm using | `make requirements` | `requirements/` folder |
| Check license compliance | `make licenses` | `licenses/` folder with analysis |
| Monitor for changes | `make monitor-deps` | Alerts and reports |
| Update version history | `make changelog` | Updated CHANGELOG.md |
| Prepare for patent filing | `make ip-docs` | Complete IP package |
| Do everything at once | `make all-docs` | All documentation |

### 🤖 By AI Tool

| Using... | Creates... | Where... |
|----------|------------|----------|
| Claude | CLAUDE.md | `.ai/` |
| GitHub Copilot | copilot-instructions.md | `.github/` |
| Cursor | .cursorrules | Project root |
| ChatGPT/GPT-4 | OPENAI_CODEX.md | `.ai/` |
| Gemini | GEMINI_CONTEXT.md | `.ai/` |
| Something else | AI_ASSISTANT.md | `.ai/` |

### 💻 By Language

| Language | Looks for... | Analyzes with... |
|----------|--------------|------------------|
| Python | requirements.txt, Pipfile, setup.py | pip-licenses |
| Node.js | package.json, package-lock.json | license-checker |
| Rust | Cargo.toml, Cargo.lock | cargo-license |
| Go | go.mod, go.sum | go-licenses |
| Ruby | Gemfile, Gemfile.lock | bundle-licenses |
| PHP | composer.json, composer.lock | composer licenses |
| Java | pom.xml, build.gradle | maven/gradle plugins |