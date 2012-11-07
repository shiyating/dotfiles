#===============================================================
#
# ALIASES AND FUNCTIONS
#
# Arguably, some functions defined here are quite big.
# If you want to make this file smaller, these functions can
# be converted into scripts and removed from here.
#
# Many functions were taken (almost) straight from the bash-2.04
# examples.
#
#===============================================================

#-------------------
# Personnal Aliases
#-------------------

alias aa='vim ~/.bashrc && source ~/.bashrc'
alias as='vim ~/.bash_aliases && source ~/.bashrc'
alias an='source ~/.bashrc'
alias zz='vim ~/.vimrc'
alias ze='vim ~/.zer0prompt && . ~/.bashrc'

function adddot() 
{
    if [ "${1#.}" != "$1" ]; then 
        DF=${PWD/~/home/jcppkkk/Dropbox/dotfiles}
        echo mkdir -vp $DF
        echo mv -v $1 $DF/${1#.}
        echo ln -sv $DF/${1#.} $1
    else
        echo $1 is not dot file
    fi 
}

alias rm='rm -ri'
alias cp='cp -ri'
alias mv='mv -i'
# -> Prevents accidentally clobbering files.
alias mkdir='mkdir -p'

alias h='history'
alias j='jobs -l'
alias which='type -a'
alias ..='cd ..'
alias path='echo -e ${PATH//:/\\n}'
alias libpath='echo -e ${LD_LIBRARY_PATH//:/\\n}'

alias du='du -kh'       # Makes a more readable output.
alias df='df -kTh'

#-------------------------------------------------------------
# The 'ls' family (this assumes you use a recent GNU ls)
#-------------------------------------------------------------
if [ "$OS" == "Linux" ]; then
    #alias ls='LC_ALL=C ls -Ah -F --color=auto'
    #alias l="LC_ALL=C ls -l"
    alias ls='ls -h -F --color=auto'
    alias l="ls -l"
    alias ll="ls -l"
else
    alias ls='ls -AhG'
    alias l="ls -l"
    alias ll="ls -l"
fi
alias la='ls -a'          # show hidden files
alias lla='ls -la'          # show hidden files
alias lx='ls -lXB'         # sort by extension
alias lk='ls -lSr'         # sort by size, biggest last
alias lc='ls -ltcr'        # sort by and show change time, most recent last
alias lu='ls -ltur'        # sort by and show access time, most recent last
alias lt='ls -ltr'         # sort by date, most recent last
alias lm='ls -l |more'    # pipe through 'more'
alias lr='ls -lR'          # recursive ls
alias tree='tree -Csu'     # nice alternative to 'recursive ls'

# If your version of 'ls' doesn't support --group-directories-first try this:
# function ll(){ ls -l "$@"| egrep "^d" ; ls -lXB "$@" 2>&-| \
#                egrep -v "^d|total "; }

