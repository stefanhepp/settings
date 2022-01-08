# ~/.zshrc: executed by the command interpreter for non-script shells.

if [ -f ~/.shrc ]; then
    . ~/.shrc
fi 

HISTSIZE=5000 # session history size
SAVEHIST=1000 # saved history
HISTFILE=~/.zshistory # history file

alias devup="nocorrect devup"
alias make="nocorrect make"

SSH_ASKPASS=ksshaskpass
export SSH_ASKPASS

# Add ssh keys to ssh-agent, but only if we have ssh-agent with kwallet running
if [ -f "$SSH_AUTH_SOCK" -a ! -z "$DISPLAY" ]; then
    # Just update keys every time on interactive login
    #   if [ "`ssh-add -l`" = "" ]; then
    # Make sure we use ksshaskpass, take TTY away from ssh-add by redirecting stdin/stdout
    ssh-add ~/.ssh/github_id_ed25519 </dev/null 2>/dev/null
fi
