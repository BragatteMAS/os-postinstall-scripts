#!/bin/zsh
# ==============================================================================
# Module: Environment Variables
# Description: Main environment variables configuration
# ==============================================================================

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ MAIN ENVIRONMENT VARIABLES                                                 ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

## Language and encoding
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

## Editor preferences
export EDITOR=${EDITOR:-vim}
export VISUAL=$EDITOR

## GPG TTY for signing
export GPG_TTY=$(tty)