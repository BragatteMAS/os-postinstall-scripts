#!/bin/zsh
# ==============================================================================
# Module: Oh My Zsh Configuration
# Description: Oh My Zsh framework setup and plugins
# ==============================================================================

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ OH MY ZSH CONFIGURATION                                                    ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

## Only load if Oh My Zsh is installed
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    ## Path to your oh-my-zsh installation
    export ZSH="$HOME/.oh-my-zsh"

    ## Theme configuration
    ZSH_THEME="robbyrussell"  ## Default, will be overridden by Powerlevel10k if available

    ## Plugin configuration
    plugins=(
        git                     ## Git aliases and functions
        docker                  ## Docker completion and aliases
        docker-compose          ## Docker-compose completion
        kubectl                 ## Kubernetes completion and aliases
        helm                    ## Helm completion
        terraform               ## Terraform completion
        aws                     ## AWS CLI completion
        gcloud                  ## Google Cloud completion
        azure                   ## Azure CLI completion
        python                  ## Python aliases
        pip                     ## pip completion
        virtualenv              ## Virtualenv support
        node                    ## Node.js aliases
        npm                     ## npm completion
        yarn                    ## Yarn completion
        rust                    ## Rust completion
        golang                  ## Go completion
        ruby                    ## Ruby aliases
        rails                   ## Rails aliases
        composer                ## PHP Composer
        laravel                 ## Laravel artisan
        symfony                 ## Symfony console
        dotnet                  ## .NET Core CLI
        flutter                 ## Flutter CLI
        react-native            ## React Native CLI
        vagrant                 ## Vagrant completion
        ansible                 ## Ansible completion
        systemd                 ## Systemd aliases
        ubuntu                  ## Ubuntu specific
        archlinux               ## Arch specific
        brew                    ## Homebrew (macOS)
        macos                   ## macOS utilities
        vscode                  ## VS Code integration
        sublime                 ## Sublime Text
        tmux                    ## tmux aliases
        screen                  ## GNU Screen
        fzf                     ## Fuzzy finder
        z                       ## Directory jumping
        zsh-autosuggestions     ## Fish-like suggestions
        zsh-syntax-highlighting ## Fish-like syntax
        colored-man-pages       ## Colorful man pages
        command-not-found       ## Suggest packages
        common-aliases          ## Common aliases
        copyfile                ## Copy file contents
        copypath                ## Copy current path
        extract                 ## Extract archives
        history                 ## History aliases
        jsontools               ## JSON utilities
        urltools                ## URL encoding
        web-search              ## Search from terminal
        sudo                    ## ESC ESC for sudo
        dirhistory              ## Directory navigation
        per-directory-history   ## Separate history
    )

    ## Oh My Zsh settings
    CASE_SENSITIVE="false"
    HYPHEN_INSENSITIVE="true"
    DISABLE_AUTO_UPDATE="true"
    DISABLE_UPDATE_PROMPT="true"
    ENABLE_CORRECTION="false"
    COMPLETION_WAITING_DOTS="true"
    DISABLE_UNTRACKED_FILES_DIRTY="true"
    HIST_STAMPS="yyyy-mm-dd"

    ## Load Oh My Zsh
    source $ZSH/oh-my-zsh.sh

    ## Install missing plugins
    install_omz_plugins() {
        local ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
        
        ## zsh-autosuggestions
        if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
            echo "Installing zsh-autosuggestions..."
            git clone https://github.com/zsh-users/zsh-autosuggestions \
                ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
        fi
        
        ## zsh-syntax-highlighting
        if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
            echo "Installing zsh-syntax-highlighting..."
            git clone https://github.com/zsh-users/zsh-syntax-highlighting \
                ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting
        fi
    }

    ## Auto-install plugins if not present
    if [[ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]] || \
       [[ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]]; then
        install_omz_plugins
    fi
fi