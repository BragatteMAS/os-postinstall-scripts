# Updated ai-setup function for .github structure
ai-setup() {
    echo "🤖 Setting up AI tools in .github/AI_TOOLKIT..."
    
    # Check if in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "⚠️  Warning: Not in a git repository. Initialize with 'git init' first? (recommended)"
        echo -n "Continue anyway? (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "❌ Setup cancelled"
            return 1
        fi
    fi
    
    # Create .github structure
    mkdir -p .github/{AI_TOOLKIT,PROJECT_DOCS,METHODS}
    mkdir -p .github/AI_TOOLKIT/{agents,commands,templates,workflows,config}
    
    # Install BMAD Method to temp location
    local temp_dir=$(mktemp -d)
    (
        cd "$temp_dir"
        if command -v pnpm &> /dev/null; then
            pnpm dlx bmad-method@latest install --full --ide cursor
        else
            npx bmad-method@latest install --full --ide cursor
        fi
    )
    
    # Move to .github/AI_TOOLKIT
    if [[ -d "$temp_dir/.bmad-core" ]]; then
        mv "$temp_dir/.bmad-core"/* .github/AI_TOOLKIT/ 2>/dev/null || true
    fi
    
    # Clean up
    rm -rf "$temp_dir"
    
    # Link CLAUDE.md
    if [[ -f "$HOME/CLAUDE.md" ]]; then
        ln -sf "$HOME/CLAUDE.md" .github/METHODS/CLAUDE.md
    fi
    
    # Create .gitattributes if needed
    if ! grep -q ".github/AI_TOOLKIT" .gitattributes 2>/dev/null; then
        echo ".github/AI_TOOLKIT/** linguist-generated=true" >> .gitattributes
        echo ".github/AI_TOOLKIT/** -diff" >> .gitattributes
    fi
    
    echo "✅ AI tools installed in .github/AI_TOOLKIT!"
    echo "💡 Use 'git log -- ':!.github'' to see only product commits"
}

# Product-focused git aliases
alias glogp="git log --oneline -- ':!.github'"
alias gdiffp="git diff -- ':!.github'"
alias gstatusp="git status -- ':!.github'"
alias gaddp="git add -- ':!.github'"
alias gcfeat="git commit -m 'feat: '"
alias gcfix="git commit -m 'fix: '"
alias gcchore="git commit -m 'chore(.github): '"
