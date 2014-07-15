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

hostname=''
if isWindows; then
  hostname=`hostname`
else
  hostname=`hostname -s`
fi

red="\033[1;31m";
norm="\033[0;39m";
cyan="\033[1;36m";
if [ "$PS1" ]; then
  PROMPT_COMMAND='PS1="\e[37m[\[\$(date +%H:%M:%S)\]]\\[\033[0;33m\][\!]\`if [[ $? = "0" ]]; then echo "\\[\\033[32m\\]"; else echo "\\[\\033[31m\\]"; fi\`[\u@\h: \w]\n\$\[\033[0m\] "; echo -ne "\033]0;$hostname:`pwd`\007"'
fi

[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2)" scp sftp ssh

#============================================================
#
#  ALIASES AND FUNCTIONS
#
#  Arguably, some functions defined here are quite big.
#  If you want to make this file smaller, these functions can
#+ be converted into scripts and removed from here.
#
#============================================================

#--------
# Exports
#--------

export PATH=$PATH:~/bin

# Make vim the default editor
export EDITOR="vim"
# Don’t clear the screen after quitting a manual page
export MANPAGER="less -X"

# Larger bash history (allow 32³ entries; default is 500)
export HISTSIZE=32768
export HISTFILESIZE=$HISTSIZE
export HISTCONTROL=ignoredups

# timestamps for bash history. www.debian-administration.org/users/rossen/weblog/1
# saved for later analysis
HISTTIMEFORMAT='%F %T '
export HISTTIMEFORMAT

# Make some commands not show up in history
export HISTIGNORE="-:pwd;exit:date:* --help"

export RI="--format ansi --width 70"

#-------------------
# Personnal Aliases
#-------------------

alias sudob='sudo -E bash'

alias dzinstall='dzil install --install-command "cpanm ."'

# TODO: work for Linux, Mac and Windows
alias java6='export JAVA_HOME="C:\Program Files (x86)\Java\jdk1.6.0_35"'
alias java7='export JAVA_HOME="C:\Program Files (x86)\Java\jdk1.7.0_07"'

# TODO: get Downloads from env, for Windows and Mac
alias mycal="gcal ~/Downloads/*ics && rm ~/Downloads/*ics"

alias sum="xargs | tr ' ' '+' | bc" ## Usage: echo 1 2 3 | sum

function psgrep() { ps axuf | grep -v grep | grep "$@" -i --color=auto; }

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

# Create a new directory and enter it
function md() {
  mkdir -p "$@" && cd "$@"
}

# find shorthand
function f() {
    find . -name "$1"
}

# Copy w/ progress
cp_p () {
  rsync -WavP --human-readable --progress $1 $2
}

# Extract archives - use: extract <file>
# Based on http://dotfiles.org/~pseup/.bashrc
function extract() {
  if [ -f "$1" ] ; then
    local filename=$(basename "$1")
    local foldername="${filename%%.*}"
    local fullpath=`perl -e 'use Cwd "abs_path";print abs_path(shift)' "$1"`
    local didfolderexist=false
    if [ -d "$foldername" ]; then
      didfolderexist=true
      read -p "$foldername already exists, do you want to overwrite it? (y/n) " -n 1
      echo
    fi
    mkdir -p "$foldername" && cd "$foldername"
    case $1 in
      *.tar.bz2) tar xjf "$fullpath" ;;
      *.tar.gz) tar xzf "$fullpath" ;;
      *.tar.xz) tar Jxvf "$fullpath" ;;
      *.tar.Z) tar xzf "$fullpath" ;;
      *.tar) tar xf "$fullpath" ;;
      *.taz) tar xzf "$fullpath" ;;
      *.tb2) tar xjf "$fullpath" ;;
      *.tbz) tar xjf "$fullpath" ;;
      *.tbz2) tar xjf "$fullpath" ;;
      *.tgz) tar xzf "$fullpath" ;;
      *.txz) tar Jxvf "$fullpath" ;;
      *.zip) unzip "$fullpath" ;;
      *) echo "'$1' cannot be extracted via extract()" && cd .. && ! $didfolderexist && rm -r "$foldername" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

#----------------
# Local overrides
#----------------

local_overrides=~/.bashrc_local
( test -r $local_overrides && . $local_overrides )

true
