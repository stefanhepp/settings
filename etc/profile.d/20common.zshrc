#
# Author: Stefan Hepp
#
# Zsh useful common settings
# 

# load default keybindings
bindkey -e

# some completion extensions
setopt correctall
setopt extendedglob

# use mmv to rename multiple files
autoload -U zmv
alias mmv='noglob zmv -W' 

