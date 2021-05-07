shell_blue=$'%{\e[0;34m%}'
shell_green=$'%{\e[0;32m%}'
shell_path=$'%{\e[0;36m%}'
shell_nocolor=$'%{\e[0m%}'

shell_user="${shell_green}%n@%m${shell_nocolor}"

PS1="%5(~,${shell_blue}[%~]${shell_nocolor}
${shell_user}:${shell_path}%3~${shell_nocolor},${shell_user}:${shell_path}%~${shell_nocolor})%(!,#,$) "
RPS1="%(?,,[%B%?%b])[%*]"

export PS1 RPS1
