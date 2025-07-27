#!/bin/zsh
# ==============================================================================
# Module: Conda/Mamba Configuration
# Description: Python environment management with Conda and Mamba
# ==============================================================================

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ CONDA/MAMBA INITIALIZATION                                                 ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

## Conda initialization
init_conda() {
    local conda_paths=(
        "$HOME/anaconda3"
        "$HOME/miniconda3"
        "$HOME/miniforge3"
        "$HOME/mambaforge"
        "/opt/anaconda3"
        "/opt/miniconda3"
        "/opt/homebrew/anaconda3"
        "/usr/local/anaconda3"
    )
    
    for conda_path in "${conda_paths[@]}"; do
        if [[ -d "$conda_path" ]]; then
            # >>> conda initialize >>>
            __conda_setup="$("$conda_path/bin/conda" 'shell.zsh' 'hook' 2> /dev/null)"
            if [ $? -eq 0 ]; then
                eval "$__conda_setup"
            else
                if [ -f "$conda_path/etc/profile.d/conda.sh" ]; then
                    . "$conda_path/etc/profile.d/conda.sh"
                else
                    export PATH="$conda_path/bin:$PATH"
                fi
            fi
            unset __conda_setup
            # <<< conda initialize <<<
            
            export CONDA_HOME="$conda_path"
            break
        fi
    done
}

## Initialize conda
init_conda

## Conda aliases
if command -v conda &> /dev/null; then
    alias ca='conda activate'
    alias cda='conda deactivate'
    alias cl='conda list'
    alias ce='conda env list'
    alias cc='conda create'
    alias ci='conda install'
    alias cu='conda update'
    alias cr='conda remove'
    
    ## Conda environment functions
    
    # Create new environment with common packages
    conda-create() {
        local env_name="${1:-myenv}"
        local python_version="${2:-3.11}"
        
        echo "Creating conda environment: $env_name with Python $python_version"
        conda create -n "$env_name" python="$python_version" pip ipython jupyter numpy pandas matplotlib scikit-learn -y
    }
    
    # Export environment
    conda-export() {
        local env_name="${1:-base}"
        conda env export -n "$env_name" > "environment_${env_name}.yml"
        echo "Environment exported to: environment_${env_name}.yml"
    }
    
    # Clean conda cache
    conda-clean() {
        conda clean --all -y
        echo "Conda cache cleaned!"
    }
fi

## Mamba (faster conda alternative)
if command -v mamba &> /dev/null; then
    alias ma='mamba activate'
    alias mda='mamba deactivate'
    alias ml='mamba list'
    alias me='mamba env list'
    alias mc='mamba create'
    alias mi='mamba install'
    alias mu='mamba update'
    alias mr='mamba remove'
    
    # Override conda aliases to use mamba
    alias conda='mamba'
fi

## Auto-activate conda environment based on .conda-env file
conda_auto_env() {
    if [[ -f ".conda-env" ]]; then
        local env_name=$(cat .conda-env)
        if [[ "$CONDA_DEFAULT_ENV" != "$env_name" ]]; then
            conda activate "$env_name"
        fi
    elif [[ "$CONDA_DEFAULT_ENV" != "base" ]] && [[ -n "$CONDA_DEFAULT_ENV" ]]; then
        conda deactivate
    fi
}

## Add to directory change hooks if using zsh
if [[ -n "$ZSH_VERSION" ]]; then
    autoload -U add-zsh-hook
    add-zsh-hook chpwd conda_auto_env
fi