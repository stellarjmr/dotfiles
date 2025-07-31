export PATH=/opt/homebrew/bin:$PATH
export PATH="/usr/bin:$PATH"
export EDITOR=nvim
if [[ "$TERM_PROGRAM" == "ghostty" ]]; then
    export TERM=xterm-256color
fi
export XDG_CONFIG_HOME="$HOME/.config"
export STARSHIP_CONFIG=~/.config/starship/starship.toml

# terminal
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced
export LS_COLORS='di=36:ln=35:so=32:pi=33:ex=31:bd=34:cd=34:su=37:sg=30:tw=34:ow=34'

autoload -Uz colors && colors
#PROMPT='%F{green}%n@%m%f %F{cyan}%~%f %# '
PROMPT='%F{green}%n%f %F{cyan}%~%f %# '
alias ls='gls --color=auto'

# alias for neovim
alias vim=nvim

# alias for tmux
alias tn='tmux new-session -s'
alias ta='tmux attach-session -t'
alias tl='tmux list-sessions'
alias td='tmux detach-client'
alias tk='tmux kill-session -t'

# alis for macOS applications
alias code='open -a "Visual Studio Code"' # open file or folder in VSCode e.g. code ~/.zshrc
alias word='open -a "Microsoft Word"'
alias excel='open -a "Microsoft Excel"'
alias ppt='open -a "Microsoft PowerPoint"'
alias pdf='open -a "Preview"'
alias vi='open -a "OVITO"'
alias ve='open -a "VESTA"'

# fastfetch
alias ff='fastfetch'

# yazi
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/administrator/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    CONDA_CHANGEPS1=false \eval "$__conda_setup"
else
    if [ -f "/Users/administrator/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/administrator/miniconda3/etc/profile.d/conda.sh"
        CONDA_CHANGEPS1=false conda activate base
    else
        export PATH="/Users/administrator/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
conda activate ovito

# zsh plugins
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
eval "$(starship init zsh)"
