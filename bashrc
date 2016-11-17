platform=$(uname);

isWindows() {
    [[ $platform == 'MINGW32_NT-6.1' ]];
}
if isWindows; then
    export TERM='cygwin'
fi

export PATH="$HOME/.ndenv/bin:/usr/local/bin:$PATH:~/bin"

if which plenv &> /dev/null; then eval "$(plenv init -)"; fi
if which pyenv &> /dev/null; then eval "$(pyenv init -)"; fi
if which rbenv &> /dev/null; then eval "$(rbenv init -)"; fi
if which jenv  &> /dev/null; then eval "$(jenv  init -)"; fi
if which ndenv &> /dev/null; then eval "$(ndenv init -)"; fi

#-------
# Prompt
#-------

hostname=''
if isWindows; then
  hostname=`hostname`
else
  hostname=`hostname -s`
fi

parse_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

function __tab_title {
  echo -n -e "\033]0;${PWD##*/}\007"
}

# Heavily inspired from https://github.com/demure/dotfiles/blob/master/subbash/prompt
function __prompt_command() {
  local EXIT="$?"             # This needs to be first
  PS1=""

  ### Colors to Vars ### {{{
  ## Inspired by http://wiki.archlinux.org/index.php/Color_Bash_Prompt#List_of_colors_for_prompt_and_Bash
  ## Terminal Control Escape Sequences: http://www.termsys.demon.co.uk/vtansi.htm
  ## Consider using some of: https://gist.github.com/bcap/5682077#file-terminal-control-sh
  ## Can unset with `unset -v {,B,U,I,BI,On_,On_I}{Bla,Red,Gre,Yel,Blu,Pur,Cya,Whi} RCol`
  local RCol='\[\e[0m\]'  # Text Reset

  # Regular         Bold            Underline         High Intensity        BoldHigh Intensity      Background        High Intensity Backgrounds
  local Bla='\[\e[0;30m\]'; local BBla='\[\e[1;30m\]';  local UBla='\[\e[4;30m\]';  local IBla='\[\e[0;90m\]';  local BIBla='\[\e[1;90m\]'; local On_Bla='\e[40m';  local On_IBla='\[\e[0;100m\]';
  local Red='\[\e[0;31m\]'; local BRed='\[\e[1;31m\]';  local URed='\[\e[4;31m\]';  local IRed='\[\e[0;91m\]';  local BIRed='\[\e[1;91m\]'; local On_Red='\e[41m';  local On_IRed='\[\e[0;101m\]';
  local Gre='\[\e[0;32m\]'; local BGre='\[\e[1;32m\]';  local UGre='\[\e[4;32m\]';  local IGre='\[\e[0;92m\]';  local BIGre='\[\e[1;92m\]'; local On_Gre='\e[42m';  local On_IGre='\[\e[0;102m\]';
  local Yel='\[\e[0;33m\]'; local BYel='\[\e[1;33m\]';  local UYel='\[\e[4;33m\]';  local IYel='\[\e[0;93m\]';  local BIYel='\[\e[1;93m\]'; local On_Yel='\e[43m';  local On_IYel='\[\e[0;103m\]';
  local Blu='\[\e[0;34m\]'; local BBlu='\[\e[1;34m\]';  local UBlu='\[\e[4;34m\]';  local IBlu='\[\e[0;94m\]';  local BIBlu='\[\e[1;94m\]'; local On_Blu='\e[44m';  local On_IBlu='\[\e[0;104m\]';
  local Pur='\[\e[0;35m\]'; local BPur='\[\e[1;35m\]';  local UPur='\[\e[4;35m\]';  local IPur='\[\e[0;95m\]';  local BIPur='\[\e[1;95m\]'; local On_Pur='\e[45m';  local On_IPur='\[\e[0;105m\]';
  local Cya='\[\e[0;36m\]'; local BCya='\[\e[1;36m\]';  local UCya='\[\e[4;36m\]';  local ICya='\[\e[0;96m\]';  local BICya='\[\e[1;96m\]'; local On_Cya='\e[46m';  local On_ICya='\[\e[0;106m\]';
  local Whi='\[\e[0;37m\]'; local BWhi='\[\e[1;37m\]';  local UWhi='\[\e[4;37m\]';  local IWhi='\[\e[0;97m\]';  local BIWhi='\[\e[1;97m\]'; local On_Whi='\e[47m';  local On_IWhi='\[\e[0;107m\]';
  ### End Color Vars ### }}}

  # Add time to start of promp
  local now="$(date +%H:%M:%S)"
  PS1+="[${now}]"

  if [ $UID -eq "0" ];then
    PS1+="${Red}\h \W ->${RCol} "   # Set prompt for root
  else
    local PSCol=""            # Declare so null var fine
    local PSOpt=""            # Above, and fixes repeat issue

    if [ $EXIT != 0 ]; then
      ## can add `kill -l $?` to test to filter backgrounded
      PS1+="${Red}${EXIT}${RCol}"   # Add exit code, if non 0
    fi

    PS1+="${PSCol}${PSOpt}\W${RCol}" # Current working dir

    ### Add SVN Status ### {{{
    if [[ -d ".svn" ]] && [[ $(command -v svn) ]] ; then
      set -f # SVN uses wildcard as output, so prevent expansion
      local SStat="$(svn status -u | tr '\n' ';')"

      if [ "$SStat" ]; then

        ### Test For Changes ### {{{
        local SChanges="$(echo ${SStat} | tr ';' '\n' | grep -v "^$" | grep -v "^\#\#" | grep -v "Status against" | wc -l | tr -d ' ')"
        if [ "$SChanges" == "0" ]; then
          local SVNCol=$Gre
        else
          local SVNCol=$Red
        fi
        ### End Test Changes ### }}}

        ### Find Branch ### {{{
        local SBra="$(svn info | awk '/URL:/ {print $2}')"
        if [ "$SBra" ]; then
          if [[ "$SBra" =~ trunk ]]; then
            local SBra="T"      # Because why waste space
          elif [[ $SBra =~ /branches/ ]]; then
            local SBra="$(echo $SBra | sed -e 's#^.*/\(branches/.*\)/.*$#\1#')"
          elif [[ $SBra =~ /tags/ ]]; then
            local SBra="$(echo $SBra | sed -e 's#^.*/\(tags/.*\)/.*$#\1#')"
          fi
        fi
        ### End Branch ### }}}

        PS1+=" ${SVNCol}[$SBra]${RCol}" # Add result to prompt

        ## Needs an `svn up`

        local SBeh="$(echo ${SStat} | tr ';' '\n' | grep -c "\*")"
        if [ "$SBeh" -gt "0" ]; then
          PS1+="${Red}↓${RCol}${SBeh}"  # Behind
        fi

        ### Find Commit Status ### {{{

        local SMod="$(echo ${SStat} | tr ';' '\n' | grep -c "^M")"
        if [ "$SMod" -gt "0" ]; then
          PS1+="${Pur}≠${RCol}${SMod}"  # Modified
        fi

        local SUnt="$(echo ${SStat} | tr ';' '\n' | grep -c "^\?")"
        if [ "$SUnt" -gt "0" ]; then
          PS1+="${Yel}?${RCol}${SUnt}"  # Untracked
        fi
        ### End Commit Status ### }}}

      fi
      set +f
    ### End SVN Status ### }}}

    ### Add Git Status ### {{{
    ## Inspired by http://www.terminally-incoherent.com/blog/2013/01/14/whats-in-your-bash-prompt/
    # TODO: only go so far up the tree
    elif [[ $(command -v git) ]]; then
      local GStat="$(git status --porcelain -b 2>/dev/null | tr '\n' ':')"

      if [ "$GStat" ]; then
        ### Fetch Time Check ### {{{
        local LAST=$(stat -c %Y $(git rev-parse --git-dir 2>/dev/null)/FETCH_HEAD 2>/dev/null)
        if [ "${LAST}" ]; then
          local TIME=$(echo $(date +"%s") - ${LAST} | bc)
          ## Check if more than 60 minutes since last
          if [ "${TIME}" -gt "3600" ]; then
            git fetch 2>/dev/null
            PS1+=' +'
            ## Refresh var
            local GStat="$(git status --porcelain -b 2>/dev/null | tr '\n' ':')"
          fi
        fi
        ### End Fetch Check ### }}}

        ### Test For Changes ### {{{
        ## Change this to test for 'ahead' or 'behind'!
        local GChanges="$(echo ${GStat} | tr ':' '\n' | grep -v "^$" | grep -v "^\#\#" | wc -l | tr -d ' ')"
        if [ "$GChanges" == "0" ]; then
          local GitCol=$Gre
        else
          local GitCol=$Red
        fi
        ### End Test Changes ### }}}

        ### Find Branch ### {{{
        local GBra="$(echo ${GStat} | tr ':' '\n' | grep "^##" | cut -c4- | grep -o "^[a-zA-Z0-9]\{1,\}[^\.]")"
        if [ "$GBra" ]; then
          if [ "$GBra" == "master" ]; then
            local GBra="M"      # Because why waste space
          fi
        else
          local GBra="ERROR"      # It could happen supposedly?
        fi
        ### End Branch ### }}}

        PS1+=" ${GitCol}[$GBra]${RCol}" # Add result to prompt

        ### Find Commit Status ### {{{

        local GAhe="$(echo ${GStat} | tr ':' '\n' | grep "^##" | grep -o "ahead [0-9]\{1,\}" | grep -o "[0-9]\{1,\}")"
        if [ "$GAhe" ]; then
          PS1+="${Gre}↑${RCol}${GAhe}"  # Ahead
        fi

        ## Needs a `git fetch`
        local GBeh="$(echo ${GStat} | tr ':' '\n' | grep "^##" | grep -o "behind [0-9]\{1,\}" | grep -o "[0-9]\{1,\}")"
        if [ "$GBeh" ]; then
          PS1+="${Red}↓${RCol}${GBeh}"  # Behind
        fi

        local GMod="$(echo ${GStat} | tr ':' '\n' | grep -c "^[ MARC]M")"
        if [ "$GMod" -gt "0" ]; then
          PS1+="${Pur}≠${RCol}${GMod}"  # Modified
        fi

        local GUnt="$(echo ${GStat} | tr ':' '\n' | grep -c "^\?")"
        if [ "$GUnt" -gt "0" ]; then
          PS1+="${Yel}?${RCol}${GUnt}"  # Untracked
        fi
        ### End Commit Status ### }}}
      fi
      else
      MISSING_ITEMS+="git-prompt, "
    fi
    ### End Git Status ### }}}

    PS1+=" ${PSCol}-> ${RCol}"      ## End of PS1
  fi
}

if [ "$PS1" ]; then
  export PROMPT_COMMAND="__tab_title ; __prompt_command"  # Func to gen PS1 after CMDs
fi

[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2)" scp sftp ssh

#============================================================
#
#  ALIASES AND FUNCTIONS
#
#============================================================

#--------
# Exports
#--------

# Make vim the default editor
export EDITOR="vim"
# Don't clear the screen after quitting a manual page
export MANPAGER="less -X"

# Larger bash history (allow 32^3 entries; default is 500)
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

# for tmux
alias ssh='TERM=screen ssh'

alias sudob='sudo -E bash'

alias dzinstall='dzil install --install-command "cpanm ."'

# TODO: work for Linux, Mac and Windows
alias java6='export JAVA_HOME="C:\Program Files (x86)\Java\jdk1.6.0_35"'
alias java7='export JAVA_HOME="C:\Program Files (x86)\Java\jdk1.7.0_07"'

# TODO: get Downloads from env, for Windows and Mac
alias mycal="gcal ~/Downloads/*ics && rm ~/Downloads/*ics"

alias sum="xargs | tr ' ' '+' | bc" ## Usage: echo 1 2 3 | sum

function psgrep() { ps axuf | grep -v grep | grep "$@" -i --color=auto; }

function title() {
  printf "\033]0;%s\007" "$1"
}

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
