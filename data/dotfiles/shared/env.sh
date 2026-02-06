# Environment variables
# Sourced by both zsh and bash

# Editor preference (respect existing if set)
export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-$EDITOR}"

# Pager
export PAGER="${PAGER:-less}"

# Locale
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

# Less options
# -R: Allow ANSI color escape sequences
# -F: Quit if entire file fits on first screen
# -X: Don't clear screen on exit
# -i: Case-insensitive search
export LESS="-RFXi"

# Colorize man pages
export LESS_TERMCAP_mb=$'\e[1;32m'      # begin blink
export LESS_TERMCAP_md=$'\e[1;32m'      # begin bold
export LESS_TERMCAP_me=$'\e[0m'         # end mode
export LESS_TERMCAP_so=$'\e[01;33m'     # begin standout
export LESS_TERMCAP_se=$'\e[0m'         # end standout
export LESS_TERMCAP_us=$'\e[1;4;31m'    # begin underline
export LESS_TERMCAP_ue=$'\e[0m'         # end underline
