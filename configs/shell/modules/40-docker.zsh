#!/bin/zsh
# ==============================================================================
# Module: Docker Configuration
# Description: Docker and Docker Compose aliases and functions
# ==============================================================================

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ DOCKER CONFIGURATION                                                       ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

if command -v docker &> /dev/null; then
    ## Docker aliases
    alias d='docker'
    alias dp='docker ps'
    alias dpa='docker ps -a'
    alias di='docker images'
    alias dex='docker exec -it'
    alias dl='docker logs'
    alias dlf='docker logs -f'
    alias dstop='docker stop'
    alias dstart='docker start'
    alias drm='docker rm'
    alias drmi='docker rmi'
    alias dprune='docker system prune -a'
    alias dvol='docker volume ls'
    alias dnet='docker network ls'

    ## Docker Compose aliases
    if command -v docker-compose &> /dev/null || docker compose version &> /dev/null 2>&1; then
        # Detect if using docker-compose or docker compose
        if docker compose version &> /dev/null 2>&1; then
            alias dc='docker compose'
        else
            alias dc='docker-compose'
        fi
        
        alias dcu='dc up'
        alias dcud='dc up -d'
        alias dcd='dc down'
        alias dcl='dc logs'
        alias dclf='dc logs -f'
        alias dcp='dc ps'
        alias dcr='dc restart'
        alias dcb='dc build'
        alias dce='dc exec'
    fi

    ## Docker functions
    
    # Remove all containers
    docker-clean() {
        echo "Stopping all containers..."
        docker stop $(docker ps -aq) 2>/dev/null
        echo "Removing all containers..."
        docker rm $(docker ps -aq) 2>/dev/null
        echo "Done!"
    }

    # Remove all images
    docker-clean-images() {
        echo "Removing all images..."
        docker rmi $(docker images -q) -f 2>/dev/null
        echo "Done!"
    }

    # Docker shell into container
    dsh() {
        local container="${1:-}"
        if [[ -z "$container" ]]; then
            echo "Usage: dsh <container>"
            return 1
        fi
        docker exec -it "$container" /bin/bash || docker exec -it "$container" /bin/sh
    }

    # Docker stats with better format
    dstats() {
        docker stats --format "table {{.Container}}\t{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    }

    # Show docker disk usage
    ddf() {
        docker system df
    }

    # Search Docker Hub
    dhub() {
        if [[ -z "$1" ]]; then
            echo "Usage: dhub <search-term>"
            return 1
        fi
        docker search "$1" --limit 25
    }

    # Get container IP
    dip() {
        if [[ -z "$1" ]]; then
            echo "Usage: dip <container>"
            return 1
        fi
        docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$1"
    }

    ## Podman aliases (if using podman as docker alternative)
    if command -v podman &> /dev/null; then
        alias pd='podman'
        alias pdp='podman ps'
        alias pdi='podman images'
        # ... similar aliases for podman
    fi
fi