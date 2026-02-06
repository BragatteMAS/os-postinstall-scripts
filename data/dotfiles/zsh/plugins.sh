# zsh plugin loading
# NOTE: zsh-syntax-highlighting MUST be sourced LAST (per RESEARCH.md pitfall)

ZSH_PLUGINS_DIR="${HOME}/.zsh"

# -----------------------------------------------------------------------------
# zsh-autosuggestions (first)
# Install: git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
# -----------------------------------------------------------------------------
if [[ -f "${ZSH_PLUGINS_DIR}/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "${ZSH_PLUGINS_DIR}/zsh-autosuggestions/zsh-autosuggestions.zsh"
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
fi

# -----------------------------------------------------------------------------
# zsh-completions (adds more completions)
# Install: git clone https://github.com/zsh-users/zsh-completions ~/.zsh/zsh-completions
# -----------------------------------------------------------------------------
if [[ -d "${ZSH_PLUGINS_DIR}/zsh-completions/src" ]]; then
    fpath=("${ZSH_PLUGINS_DIR}/zsh-completions/src" $fpath)
fi

# -----------------------------------------------------------------------------
# zsh-syntax-highlighting (MUST BE LAST)
# Install: git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting
# -----------------------------------------------------------------------------
if [[ -f "${ZSH_PLUGINS_DIR}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "${ZSH_PLUGINS_DIR}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
