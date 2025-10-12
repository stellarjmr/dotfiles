export CLICOLOR=1
export LS_COLORS='di=34:ln=36:so=32:pi=33:ex=31:bd=1;34:cd=1;34:su=37:sg=30:tw=34:ow=34'
alias ls='ls --color=auto'
export PS1='\[\e[32m\]\u@\h\[\e[m\] \[\e[36m\]\w\[\e[m\] \$ '

alias squ="squeue -u $USER"
alias sq="squeue -u $USER -t RUNNING -o '%.10i %.25j %.60Z %.10M %.8T' | column -t"
