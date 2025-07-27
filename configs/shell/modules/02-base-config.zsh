#!/bin/zsh
# ==============================================================================
# Module: Base Configuration
# Description: Initial settings and performance optimizations
# ==============================================================================

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ INITIAL CONFIGURATION AND PERFORMANCE                                      ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

## History configuration
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

## Performance options
setopt HIST_IGNORE_DUPS     ## Ignore duplicate commands
setopt HIST_FIND_NO_DUPS    ## Don't show duplicates in search
setopt SHARE_HISTORY        ## Share history between sessions
setopt EXTENDED_HISTORY     ## Save timestamp of commands
setopt INC_APPEND_HISTORY   ## Write immediately, not on exit

## Disable automatic update check for Oh My Zsh (performance)
DISABLE_AUTO_UPDATE="true"