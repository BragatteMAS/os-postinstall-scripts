#!/bin/zsh
# ==============================================================================
# Module: Git Aliases
# Description: Git shortcuts and productivity aliases
# ==============================================================================

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║ GIT ALIASES                                                                ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

## Basic git commands
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gcam='git commit -a -m'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gl='git pull'
alias gf='git fetch'
alias gfo='git fetch origin'

## Branch management
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gbD='git branch -D'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gcp='git cherry-pick'

## Diff and log
alias gd='git diff'
alias gds='git diff --staged'
alias glg='git log --graph --pretty=format:"%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(bold cyan)— %an%C(reset)%C(bold yellow)%d%C(reset)" --abbrev-commit'
alias glga='glg --all'
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'

## Stash
alias gst='git stash'
alias gstp='git stash pop'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gsta='git stash apply'

## Remote
alias gr='git remote'
alias grv='git remote -v'
alias gra='git remote add'
alias grr='git remote remove'

## Reset and clean
alias grh='git reset HEAD'
alias grhh='git reset HEAD --hard'
alias gclean='git clean -fd'

## Rebase
alias grb='git rebase'
alias grbi='git rebase -i'
alias grbc='git rebase --continue'
alias grba='git rebase --abort'

## Merge
alias gm='git merge'
alias gma='git merge --abort'
alias gmc='git merge --continue'

## Tags
alias gt='git tag'
alias gta='git tag -a'
alias gtd='git tag -d'
alias gtl='git tag -l'

## Show
alias gsh='git show'
alias gshn='git show --name-only'

## Useful git functions
alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify -m "--wip-- [skip ci]"'
alias gunwip='git log -n 1 | grep -q -c "\-\-wip\-\-" && git reset HEAD~1'
alias gundo='git reset --soft HEAD~1'

## GitHub/GitLab specific
alias gpr='git pull-request'
alias gmr='git merge-request'

## Git flow shortcuts
alias gfl='git flow'
alias gflf='git flow feature'
alias gflh='git flow hotfix'
alias gflr='git flow release'

## Conventional commits helpers
alias gfeat='git commit -m "feat: "'
alias gfix='git commit -m "fix: "'
alias gdocs='git commit -m "docs: "'
alias gstyle='git commit -m "style: "'
alias grefactor='git commit -m "refactor: "'
alias gtest='git commit -m "test: "'
alias gchore='git commit -m "chore: "'