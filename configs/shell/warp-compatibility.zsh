#!/bin/zsh
# ==============================================================================
# Warp Terminal Compatibility Configuration
# Solves initialization conflicts with Warp Terminal
# Author: Bragatte, M.A.S
# ==============================================================================

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ WARP TERMINAL CONFLICT RESOLUTION                                         ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

## Detect if running in Warp Terminal
if [[ "$TERM_PROGRAM" == "WarpTerminal" ]]; then
    echo "🔧 Configurando compatibilidade com Warp Terminal..."

    ## Disable Warp's automatic initialization to prevent conflicts
    export WARP_DISABLE_AUTO_INIT=true
    export WARP_DISABLE_AUTO_TITLE=true
    export WARP_HONOR_PS1=1
    export WARP_USE_SSH_WRAPPER=0
    export WARP_DISABLE_COMPLETIONS=true

    ## Prevent Warp from executing its bootstrap code
    export WARP_BOOTSTRAPPED=1

    ## Set a proper session ID if not already set
    if [[ -z "$WARP_SESSION_ID" ]]; then
        export WARP_SESSION_ID="$(date +%s)$RANDOM"
    fi

    ## Disable Warp's built-in functions that conflict with our configuration
    unset -f warp_precmd 2>/dev/null || true
    unset -f warp_preexec 2>/dev/null || true
    unset -f warp_update_prompt_vars 2>/dev/null || true

    ## Clear any existing Warp-related variables that might cause issues
    unset WARP_BOOTSTRAP_VAR 2>/dev/null || true
    unset WARP_INITIAL_WORKING_DIR 2>/dev/null || true

    echo "✅ Warp Terminal configurado para compatibilidade"
fi

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ ALTERNATIVE: MINIMAL WARP CONFIGURATION                                  ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

## If you want to use Warp's native features instead of our custom configuration,
## uncomment the following lines and comment out the section above:

# if [[ "$TERM_PROGRAM" == "WarpTerminal" ]]; then
#     echo "🔧 Usando configuração nativa do Warp Terminal..."
#
#     ## Let Warp handle its own initialization
#     export WARP_HONOR_PS1=0
#     export WARP_DISABLE_AUTO_INIT=false
#     export WARP_DISABLE_AUTO_TITLE=false
#
#     ## Enable Warp's native features
#     export WARP_USE_SSH_WRAPPER=1
#     export WARP_DISABLE_COMPLETIONS=false
#
#     echo "✅ Usando recursos nativos do Warp Terminal"
# fi

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ TROUBLESHOOTING FUNCTIONS                                                 ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

## Function to check Warp Terminal status
warp_status() {
    echo "🔍 Status do Warp Terminal:"
    echo "   TERM_PROGRAM: $TERM_PROGRAM"
    echo "   WARP_SESSION_ID: $WARP_SESSION_ID"
    echo "   WARP_DISABLE_AUTO_INIT: $WARP_DISABLE_AUTO_INIT"
    echo "   WARP_HONOR_PS1: $WARP_HONOR_PS1"
    echo "   WARP_DISABLE_AUTO_TITLE: $WARP_DISABLE_AUTO_TITLE"
    echo "   WARP_USE_SSH_WRAPPER: $WARP_USE_SSH_WRAPPER"
    echo "   WARP_DISABLE_COMPLETIONS: $WARP_DISABLE_COMPLETIONS"
}

## Function to reset Warp Terminal configuration
warp_reset() {
    echo "🔄 Resetando configuração do Warp Terminal..."
    unset WARP_DISABLE_AUTO_INIT
    unset WARP_DISABLE_AUTO_TITLE
    unset WARP_HONOR_PS1
    unset WARP_USE_SSH_WRAPPER
    unset WARP_DISABLE_COMPLETIONS
    unset WARP_SESSION_ID
    unset WARP_BOOTSTRAPPED
    echo "✅ Configuração resetada"
}

## Function to enable Warp's native features
warp_enable_native() {
    echo "🔧 Habilitando recursos nativos do Warp..."
    export WARP_DISABLE_AUTO_INIT=false
    export WARP_DISABLE_AUTO_TITLE=false
    export WARP_HONOR_PS1=0
    export WARP_USE_SSH_WRAPPER=1
    export WARP_DISABLE_COMPLETIONS=false
    echo "✅ Recursos nativos habilitados"
}

## Function to disable Warp's native features
warp_disable_native() {
    echo "🔧 Desabilitando recursos nativos do Warp..."
    export WARP_DISABLE_AUTO_INIT=true
    export WARP_DISABLE_AUTO_TITLE=true
    export WARP_HONOR_PS1=1
    export WARP_USE_SSH_WRAPPER=0
    export WARP_DISABLE_COMPLETIONS=true
    echo "✅ Recursos nativos desabilitados"
}

## Aliases for easy access
alias warp-status='warp_status'
alias warp-reset='warp_reset'
alias warp-enable='warp_enable_native'
alias warp-disable='warp_disable_native'