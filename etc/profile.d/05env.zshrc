shell_color=$'%{\e[0;36m%}'
shell_nocolor=$'%{\e[0m%}'

PS1="%5(~,${shell_color}[%~]${shell_nocolor}
%n@%m:%3~,%n@%m:%~)%(!,#,$) "
RPS1="%(?,,[%B%?%b])[%*]"

export PS1 RPS1
