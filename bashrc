platform=$(uname);

isWindows() {
    [[ $platform == 'MINGW32_NT-6.1' ]];
}
if isWindows; then
    export TERM='cygwin'
fi


#-------
# Prompt
#-------

red="\033[1;31m";
norm="\033[0;39m";
cyan="\033[1;36m";
if [ "$PS1" ]; then
    if [[ $UID -eq 0 ]]; then
      PS1="\[$red\]\u@\h:\w\\[\033[0;39m\]\n# "
    else
      PS1="\[$cyan\]\u@\h:\w\\[\033[0;39m\]\n\$ "
    fi
    export PROMPT_COMMAND="echo -n \[\$(date +%H:%M:%S)\]"
fi

#============================================================
#
#  ALIASES AND FUNCTIONS
#
#  Arguably, some functions defined here are quite big.
#  If you want to make this file smaller, these functions can
#+ be converted into scripts and removed from here.
#
#============================================================

#-------------------
# Personnal Aliases
#-------------------

export RI="--format ansi --width 70"

alias dzinstall='dzil install --install-command "cpanm ."'

# TODO: work for Linux, Mac and Windows
alias java6='export JAVA_HOME="C:\Program Files (x86)\Java\jdk1.6.0_35"'
alias java7='export JAVA_HOME="C:\Program Files (x86)\Java\jdk1.7.0_07"'

# TODO: get Downloads from env, for Windows and Mac
alias mycal="gcal ~/Downloads/*ics && rm ~/Downloads/*ics"

#-------------------------------------------------------------
# Make the following commands run in background automatically:
#-------------------------------------------------------------

if isWindows; then
  function subl {
    /c/Program\ Files/Sublime\ Text\ 3/sublime_text.exe $1 &
  }
fi

if isWindows; then
  function vi {
    "/c/Program Files (x86)/Vim/vim72/gvim.exe" $1 &
  }
fi

#-------------------------------------------------------------
# File & strings related functions:
#-------------------------------------------------------------

function swap()
{ # Swap 2 filenames around, if they exist (from Uzi's bashrc).
    local TMPFILE=tmp.$$

    [ $# -ne 2 ] && echo "swap: 2 arguments needed" && return 1
    [ ! -e $1 ] && echo "swap: $1 does not exist" && return 1
    [ ! -e $2 ] && echo "swap: $2 does not exist" && return 1

    mv "$1" $TMPFILE
    mv "$2" "$1"
    mv $TMPFILE "$2"
}

#----------------
# Local overrides
#----------------

local_overrides=~/.bashrc_local
( test -r $local_overrides && . $local_overrides )
