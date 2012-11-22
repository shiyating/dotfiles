
# Test for an interactive shell.  There is no need to set anything
# past this point for scp and rcp, and it's important to refrain from
# outputting anything in those cases.
if [[ $- != *i* ]] ; then
	# Shell is non-interactive.  Be done now!
	return
fi

#-------------------------------------------------------------
# Bash won't get SIGWINCH if another process is in the foreground.
# Enable checkwinsize so that bash will check the terminal size when
# it regains control.  #65623
# http://cnswww.cns.cwru.edu/~chet/bash/FAQ (E11)
#-------------------------------------------------------------
shopt -s checkwinsize

#-------------------------------------------------------------
# import other scripts
# ~/.zer0prompt         : preload color prompt
# ~/.rvm/scripts/rvm    : Load RVM into a shell session *as a function*
#-------------------------------------------------------------
for file in \
    /etc/bashrc \
    ~/.bash_aliases ~/.git-prompt.sh \
    ~/.zer0prompt \
    ~/.rvm/scripts/rvm
do
    if [ -f $file ]; then
        . $file
    fi
done

#-------------------------------------------------------------
# Freebsd setting
#-------------------------------------------------------------
if [ `uname` = "FreeBSD" ];
then
    export PACKAGEROOT="ftp://ftp.tw.FreeBSD.org"
fi


#-------------------------------------------------------------
# Change language by terminal (local console OR ssh ?)
#-------------------------------------------------------------
if [ -z $SSH_TTY ]; then
    export LC_ALL=C LANG=C LANGUAGE=C
else
    export LC_ALL=zh_TW.UTF-8 LANG=zh_TW LANGUAGE=zh_TW
fi

#-------------------------------------------------------------
# Change the window title of X terminals 
#-------------------------------------------------------------
case ${TERM} in
	xterm*|rxvt*|Eterm|aterm|kterm|gnome*|interix)
		PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/~}\007"'
		;;
	screen)
		PROMPT_COMMAND='echo -ne "\033_${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/~}\033\\"'
		;;
esac


#-------------------------------------------------------------
# Set Default keybinding
#-------------------------------------------------------------
if [ -z "$INPUTRC" -a ! -f "$HOME/.inputrc" ] ; then
    INPUTRC=/etc/inputrc
fi


#-------------------------------------------------------------
# Set colorful PS1 only on colorful terminals.
# dircolors --print-database uses its own built-in database
# instead of using /etc/DIR_COLORS.  Try to use the external file
# first to take advantage of user additions.  Use internal bash
# globbing instead of external grep binary.
#-------------------------------------------------------------
use_color=false

safe_term=${TERM//[^[:alnum:]]/?}   # sanitize TERM
match_lhs=""
[[ -f ~/.dir_colors   ]] && match_lhs="${match_lhs}$(<~/.dir_colors)"
[[ -f /etc/DIR_COLORS ]] && match_lhs="${match_lhs}$(</etc/DIR_COLORS)"
[[ -z ${match_lhs}    ]] \
	&& type -P dircolors >/dev/null \
	&& match_lhs=$(dircolors --print-database)
[[ $'\n'${match_lhs} == *$'\n'"TERM "${safe_term}* ]] && use_color=true

if ${use_color} ; then
	# Enable colors for ls, etc.  Prefer ~/.dir_colors #64489
	if type -P dircolors >/dev/null ; then
		if [[ -f ~/.dir_colors ]] ; then
			eval $(dircolors -b ~/.dir_colors)
		elif [[ -f /etc/DIR_COLORS ]] ; then
			eval $(dircolors -b /etc/DIR_COLORS)
		fi
	fi

    zer0prompt

	alias ls='ls --color=auto'
	alias grep='grep --colour=auto'
else
	if [[ ${EUID} == 0 ]] ; then
		# show root@ when we don't have colors
		PS1='\u@\h \W \# '
	else
		PS1='\u@\h \w \$ '
	fi
fi


#-------------------------------------------------------------
# History
#-------------------------------------------------------------
# Enable history appending instead of overwriting.  #139609
shopt -s histappend

shopt -s cmdhist
PROMPT_COMMAND="history -a;history -c; history -r;$PROMPT_COMMAND"
TIMEFORMAT=$'\nreal %3R\tuser %3U\tsys %3S\tpcpu %P\n'
HISTIGNORE="&:ls:[bf]g:exit"
HOSTFILE=$HOME/.hosts    # Put list of remote hosts in ~/.hosts ...
HISTSIZE=10000
HISTFILESIZE=10000
HISTCONTROL=ignoreboth


#-------------------------------------------------------------
# tailoring 'less'
#-------------------------------------------------------------
alias more='less'
export EDITOR=vim
export PAGER=less
#export LESSCHARSET='latin1'
#export LESSOPEN='|/usr/bin/lesspipe.sh %s 2>&-'
   # Use this if lesspipe.sh exists
#export LESS='-i -S -w -N -z -4 -g -e -M -F -X -R -P%t?f%f \
export LESS='-i -z -4 -M -X -R'
export  LESSCHARDEF="8bcccbcc18b95.."
export  LESS_TERMCAP_mb='[1;31m'      # begin blinking
export  LESS_TERMCAP_md='[4;32m'      # begin bold
export  LESS_TERMCAP_me='[0m'         # end mode
export  LESS_TERMCAP_so='[0;31m'      # begin standout-mode - info box
export  LESS_TERMCAP_se='[0m'         # end standout-mode
export  LESS_TERMCAP_us='[0;33m'      # begin underline
export  LESS_TERMCAP_ue='[0m'         # end underline
export  LSCOLORS=ExGxFxdxCxDxDxBxBxExEx

#-------------------------------------------------------------
# File & string-related functions:
#-------------------------------------------------------------

# Find a file with a pattern in name:
function ff() { find . -type f -iname '*'$*'*' -ls ; }

# Find a file with pattern $1 in name and Execute $2 on it:
function fe()
{ find . -type f -iname '*'${1:-}'*' -exec ${2:-file} {} \;  ; }

# Find a pattern in a set of files and highlight them:
# (needs a recent version of egrep)
function fstr()
{
    OPTIND=1
    local case=""
    local usage="fstr: find string in files.
Usage: fstr [-i] \"pattern\" [\"filename pattern\"] "
    while getopts :it opt
    do
        case "$opt" in
        i) case="-i " ;;
        *) echo "$usage"; return;;
        esac
    done
    shift $(( $OPTIND - 1 ))
    if [ "$#" -lt 1 ]; then
        echo "$usage"
        return;
    fi
    find . -type f -name "${2:-*}" -print0 | \
    xargs -0 egrep --color=always -sn ${case} "$1" 2>&- | more

}

function cuttail() # cut last n lines in file, 10 by default
{
    nlines=${2:-10}
    sed -n -e :a -e "1,${nlines}!{P;N;D;};N;ba" $1
}

function lowercase()  # move filenames to lowercase
{
    for file ; do
        filename=${file##*/}
        case "$filename" in
        */*) dirname==${file%/*} ;;
        *) dirname=.;;
        esac
        nf=$(echo $filename | tr A-Z a-z)
        newname="${dirname}/${nf}"
        if [ "$nf" != "$filename" ]; then
            mv "$file" "$newname"
            echo "lowercase: $file --> $newname"
        else
            echo "lowercase: $file not changed."
        fi
    done
}


function swap()  # Swap 2 filenames around, if they exist
{                #(from Uzi's bashrc).
    local TMPFILE=tmp.$$

    [ $# -ne 2 ] && echo "swap: 2 arguments needed" && return 1
    [ ! -e $1 ] && echo "swap: $1 does not exist" && return 1
    [ ! -e $2 ] && echo "swap: $2 does not exist" && return 1

    mv "$1" $TMPFILE
    mv "$2" "$1"
    mv $TMPFILE "$2"
}

function extract()      # Handy Extract Program.
{
     if [ -f "$1" ] ; then
         case "$1" in
             *.tar.bz2)   tar xvjf "$1"     ;;
             *.tar.gz)    tar xvzf "$1"     ;;
             *.bz2)       bunzip2 "$1"      ;;
             *.rar)       unrar x "$1"      ;;
             *.gz)        gunzip "$1"       ;;
             *.tar)       tar xvf "$1"      ;;
             *.tbz2)      tar xvjf "$1"     ;;
             *.tgz)       tar xvzf "$1"     ;;
             *.zip)       unzip "$1"        ;;
             *.Z)         uncompress "$1"   ;;
             *.7z)        7z x "$1"         ;;
             *)           echo "'$1' cannot be extracted via >extract<" ;;
         esac
     else
         echo "'$1' is not a valid file"
     fi
}

#-------------------------------------------------------------
# Process/system related functions:
#-------------------------------------------------------------


function my_ps() { ps $@ -u $USER -o "pid,%cpu,%mem,bsdtime,command" ; }
function pp() { my_ps f | awk '!/awk/ && $0~var' var=${1:-".*"} ; }


function killps()                 # Kill by process name.
{
    local pid pname sig="-TERM"   # Default signal.
    if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
        echo "Usage: killps [-SIGNAL] pattern"
        return;
    fi
    if [ $# = 2 ]; then sig=$1 ; fi
    for pid in $(my_ps| awk '!/awk/ && $0~pat { print $1 }' pat=${!#} ) ; do
        pname=$(my_ps | awk '$1~var { print $5 }' var=$pid )
        if ask "Kill process $pid <$pname> with signal $sig?"
            then kill $sig $pid
        fi
    done
}


#-------------------------------------------------------------
# import completions
#-------------------------------------------------------------
for file in \
    /etc/bash_completion \
    /usr/local/etc/bash_completion \
    ~/.git-completion.sh \
    ~/.bash_completion
do
    if [ -f $file ]; then
        . $file
    fi
done

#-------------------------------------------------------------
# customize PATH
#-------------------------------------------------------------
for a in \
    ~/bin/ \
    /android-cts/tools \
    /android-sdk-linux_x86/tools
do
    if [ -d "$a" ] && [[ ":$PATH:" != *":$a:"* ]]; then
        PATH="$PATH:$a"
    fi
done



#-------------------------------------------------------------
# Try to keep environment pollution down, EPA loves us.
#-------------------------------------------------------------
unset use_color safe_term match_lhs zer0prompt

#-------------------------------------------------------------
# import local setting
#-------------------------------------------------------------
[ -e ~/.bashrc_local ] && . ~/.bashrc_local
