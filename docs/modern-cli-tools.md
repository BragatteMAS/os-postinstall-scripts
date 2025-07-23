# 🦀 Modern CLI Tools Guide

Transform your command line experience with blazing-fast Rust-powered tools that replace traditional Unix utilities.

## 📊 Tool Comparison

| Traditional | Modern | Key Benefits | Example |
|-------------|---------|--------------|---------|
| `cat` | **bat** | Syntax highlighting, line numbers, Git integration | `bat README.md` |
| `ls` | **eza** | Icons, colors, Git status, tree view | `eza -la --icons` |
| `find` | **fd** | Intuitive syntax, smart defaults, faster | `fd "*.rs"` |
| `grep` | **ripgrep** | 10-100x faster, respects .gitignore | `rg "TODO"` |
| `cd` | **zoxide** | Learns your habits, jump to any directory | `z proj` |
| `du` | **dust** | Visual disk usage, intuitive output | `dust -r` |
| `top` | **bottom** | Better UI, mouse support, more metrics | `btm` |
| `sed` | **sd** | Intuitive find & replace | `sd "old" "new" file.txt` |

## 🚀 Installation

### All Tools at Once
```bash
./install_rust_tools.sh
```

### Individual Tools
```bash
cargo install bat eza fd-find ripgrep zoxide dust bottom sd
```

## 📖 Tool Guides

### bat - A Better Cat

**Basic Usage:**
```bash
# View file with syntax highlighting
bat file.py

# Show line numbers
bat -n file.py

# Show non-printing characters
bat -A file.txt

# Compare files (like diff)
bat file1.txt file2.txt --diff
```

**Integration with other tools:**
```bash
# Use as pager for man
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# Pretty git diff
git diff | bat --language=diff

# Tail with highlighting
tail -f app.log | bat --paging=never -l log
```

### eza - A Better ls

**Basic Usage:**
```bash
# List with icons and git status
eza -la --icons --git

# Tree view
eza --tree --level=2

# Sort by size
eza -la --sort=size

# Long format with headers
eza -lah --header

# Show only directories
eza -D
```

**Aliases to add:**
```bash
alias ls='eza --icons'
alias ll='eza -la --icons --git'
alias tree='eza --tree --icons'
```

### fd - A Better Find

**Basic Usage:**
```bash
# Find files by name
fd README

# Find by extension
fd -e py           # Python files
fd -e js -e ts     # JavaScript and TypeScript

# Find in specific directory
fd pattern /path/to/search

# Find and execute
fd -e txt -x wc -l  # Count lines in all txt files

# Find hidden files too
fd -H pattern

# Case insensitive
fd -i "readme"
```

**Advanced patterns:**
```bash
# Exclude directories
fd pattern -E node_modules -E .git

# Find empty files
fd -t f -S 0

# Find files modified in last day
fd pattern --changed-within 1d
```

### ripgrep - A Better Grep

**Basic Usage:**
```bash
# Search for pattern
rg "TODO"

# Search specific file types
rg "function" -t py        # Python files only
rg "class" -t js -t ts     # JavaScript and TypeScript

# Show context
rg "error" -C 3            # 3 lines before and after

# Search with regex
rg "user_\d+"              # user_123, user_456, etc.

# Count matches
rg -c "TODO"

# List only filenames
rg -l "import React"
```

**Power features:**
```bash
# Replace text (dry run)
rg "old_function" --replace "new_function"

# Search in specific paths
rg "TODO" src/ tests/

# Ignore case
rg -i "error"

# Search in hidden files
rg --hidden "config"

# Pretty output with stats
rg "pattern" --stats
```

### zoxide - A Better cd

**Setup:**
```bash
# Add to ~/.bashrc or ~/.zshrc
eval "$(zoxide init bash)"  # or zsh
```

**Basic Usage:**
```bash
# Jump to most used directory matching "proj"
z proj

# Jump to exact match
z project-name

# Interactive selection
zi proj  # Shows menu if multiple matches

# Add current directory to database
zoxide add .

# See statistics
zoxide query -l
```

**Tips:**
- Use it naturally - it learns from your `cd` commands
- The more you use a directory, the higher it ranks
- Works great with partial matches

### dust - A Better du

**Basic Usage:**
```bash
# Show disk usage
dust

# Reverse order (biggest last)
dust -r

# Show more depth
dust -d 3

# Show full paths
dust -p

# Specific directory
dust ~/Documents
```

### bottom - A Better top

**Basic Usage:**
```bash
# Launch
btm

# With basic UI
btm -b

# Celsius for temps
btm -c
```

**Keyboard shortcuts:**
- `?` - Help
- `q` - Quit
- `Tab` - Switch widgets
- `/` - Search in process list
- `dd` - Kill process
- `c` - Sort by CPU
- `m` - Sort by Memory

### sd - A Better sed

**Basic Usage:**
```bash
# Simple replace
sd "old" "new" file.txt

# Replace in multiple files
sd "old" "new" *.txt

# Regex replace
sd "user_(\d+)" "id_$1" file.txt

# Case insensitive
sd -i "OLD" "new" file.txt
```

## 🎨 Shell Integration

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
# Modern CLI tools aliases
alias cat='bat'
alias ls='eza --icons'
alias ll='eza -la --icons --git'
alias find='fd'
alias grep='rg'
alias du='dust'
alias top='btm'
alias sed='sd'

# Additional useful aliases
alias la='eza -la --icons --git --header'
alias tree='eza --tree --icons --level=2'
alias ff='fd -t f'  # Find files
alias fdir='fd -t d'  # Find directories

# Initialize zoxide
eval "$(zoxide init bash)"  # or zsh
```

## 🎯 Practical Examples

### Find and Replace Across Project
```bash
# Find all Python files with "old_api"
fd -e py -x rg -l "old_api" {} | head -20

# Replace in all Python files
fd -e py -x sd "old_api" "new_api" {}
```

### Analyze Codebase
```bash
# Count lines of code by language
fd -e py -x wc -l {} | awk '{sum+=$1} END {print "Python:", sum}'
fd -e js -x wc -l {} | awk '{sum+=$1} END {print "JavaScript:", sum}'

# Find largest files
fd -t f -x du -h {} | sort -hr | head -10

# Find TODO comments with context
rg "TODO|FIXME" -t py -C 2
```

### Quick Navigation
```bash
# Jump between common directories
z docs
z src
z ~

# Find and cd to directory
cd $(fd -t d "migrations" | fzf)
```

### Log Analysis
```bash
# Search logs with highlighting
rg "ERROR" /var/log/app.log | bat -l log

# Follow logs with color
tail -f /var/log/app.log | bat --paging=never -l log
```

## 💡 Tips & Tricks

1. **Use shell aliases** - Make modern tools your default
2. **Learn the flags** - Each tool has powerful options
3. **Combine tools** - They work great together
4. **Read the docs** - `toolname --help` is your friend
5. **Practice** - The more you use them, the more natural they become

## 🔧 Configuration Files

Many of these tools support configuration:

- **bat**: `~/.config/bat/config`
- **ripgrep**: `~/.ripgreprc`
- **fd**: Uses `.fdignore` files
- **bottom**: `~/.config/bottom/bottom.toml`

## 📚 Resources

- [bat documentation](https://github.com/sharkdp/bat)
- [eza documentation](https://github.com/eza-community/eza)
- [fd documentation](https://github.com/sharkdp/fd)
- [ripgrep user guide](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md)
- [zoxide documentation](https://github.com/ajeetdsouza/zoxide)
- [dust documentation](https://github.com/bootandy/dust)
- [bottom documentation](https://github.com/ClementTsang/bottom)

---

These tools will transform your command line experience. Start with one or two, and gradually adopt more as you get comfortable!