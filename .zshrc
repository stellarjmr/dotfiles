export PATH=/opt/homebrew/bin:$PATH
export PATH="/usr/bin:$PATH"
export EDITOR=nvim
if [[ "$TERM_PROGRAM" == "ghostty" ]] || [[ "$TERM" == "xterm-kitty" ]]; then
  export TERM=xterm-256color
fi
export SIOYEK_CONFIG_HOME=~/.config/sioyek
export XDG_CONFIG_HOME="$HOME/.config"
# deepmd
export PATH=/Users/administrator/dproot/bin:$PATH
# gemini cli
export GOOGLE_CLOUD_PROJECT="omega-bearing-464801-p9"
export STARSHIP_CONFIG=~/.config/starship/starship.toml

# terminal
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced
export LS_COLORS='di=36:ln=35:so=32:pi=33:ex=31:bd=34:cd=34:su=37:sg=30:tw=34:ow=34'

autoload -Uz colors && colors
#PROMPT='%F{green}%n@%m%f %F{cyan}%~%f %# '
PROMPT='%F{green}%n%f %F{cyan}%~%f %# '
alias ls='gls --color=auto'

# fzf
# morhetz/gruvbox
export FZF_DEFAULT_OPTS='--color=bg+:#3c3836,bg:#32302f,spinner:#fb4934,hl:#928374,fg:#ebdbb2,header:#928374,info:#8ec07c,pointer:#fb4934,marker:#fb4934,fg+:#ebdbb2,prompt:#fb4934,hl+:#fb4934'

# alias for lazygit
alias lg='lazygit'

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
alias em='osascript -e "tell app \"Finder\" to empty trash"'

# fastfetch
alias ff='fastfetch'

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

# functions
# yazi
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# fzf
function f() {
  fzf --style full \
      --border --padding 1,2 \
      --border-label ' FZF File ' --input-label ' Input ' --header-label ' File Type ' \
      --preview 'fzf-preview.sh {}' \
      --bind 'result:transform-list-label:
          if [[ -z $FZF_QUERY ]]; then
            echo " $FZF_MATCH_COUNT items "
          else
            echo " $FZF_MATCH_COUNT matches for [$FZF_QUERY] "
          fi
          ' \
      --bind 'focus:transform-preview-label:[[ -n {} ]] && printf " Previewing [%s] " {}' \
      --bind 'focus:+transform-header:file --brief {} || echo "No file selected"' \
      --bind 'ctrl-r:change-list-label( Reloading the list )+reload(sleep 2; git ls-files)' \
      --color 'border:#aaaaaa,label:#cccccc' \
      --color 'preview-border:#9999cc,preview-label:#ccccff' \
      --color 'list-border:#669966,list-label:#99cc99' \
      --color 'input-border:#996666,input-label:#ffcccc' \
      --color 'header-border:#6699cc,header-label:#99ccff' \
      "$@"
}

function g() {
  RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case "
  INITIAL_QUERY="${*:-}"
  fzf --ansi --disabled --query "$INITIAL_QUERY" \
      --bind "start:reload:$RG_PREFIX {q}" \
      --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
      --delimiter : \
      --preview 'bat --color=always {1} --highlight-line {2}' \
      --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
      --bind 'enter:become(nvim {1} +{2})'
}
