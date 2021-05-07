# ~/.zshrc: executed by the command interpreter for non-script shells.

. ~/.shrc

HISTSIZE=5000 # session history size
SAVEHIST=1000 # saved history
HISTFILE=~/.zshistory # history file

alias devup="nocorrect devup"
alias make="nocorrect make"

SSH_ASKPASS=ksshaskpass
export SSH_ASKPASS

if [ "`ssh-add -l | grep github`" = "" ]; then
    ssh-add ~/.ssh/github_id_rsa </dev/null 2>/dev/null
fi
