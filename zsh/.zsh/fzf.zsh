fzf-down() {
  fzf --height 50% "$@" --border
}

export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview' --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' --header 'Press CTRL-Y to copy command into clipboard' --border"

if command -v fd > /dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND='fd --type f --hidden --follow --exclude .git'
fi

# Use fd (https://github.com/sharkdp/fd) instead of the default find
# command for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "$1"
}


command -v bat  > /dev/null && export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always {}'"



### Fancy stuff ###

# zsh; needs setopt re_match_pcre. You can, of course, adapt it to your own shell easily.
tmuxkillf () {
    local sessions
    sessions="$(tmux ls|fzf --exit-0 --multi)"  || return $?
    local i
    for i in "${(f@)sessions}"
    do
        [[ $i =~ '([^:]*):.*' ]] && {
            echo "Killing $match[1]"
            tmux kill-session -t "$match[1]"
        }
    done
}

# tm - create new tmux session, or switch to existing one. Works from within tmux too. (@bag-man)
# `tm` will allow you to select your tmux session via fzf.
# `tm irc` will attach to the irc session (if it exists), else it will create it.

tm() {
  [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"
  if [ $1 ]; then
    tmux $change -t "$1" 2>/dev/null || (tmux new-session -d -s $1 && tmux $change -t "$1"); return
  fi
  session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0) &&  tmux $change -t "$session" || echo "No sessions found."
}

# fs [FUZZY PATTERN] - Select selected tmux session
#   - Bypass fuzzy finder if there's only one match (--select-1)
#   - Exit if there's no match (--exit-0)
fs() {
  local session
  session=$(tmux list-sessions -F "#{session_name}" | \
    fzf --query="$1" --select-1 --exit-0) &&
  tmux switch-client -t "$session"
}

# fkill - kill processes - list only the ones you can kill. Modified the earlier script.
fkill() {
    local pid 
    if [ "$UID" != "0" ]; then
        pid=$(ps -f -u $UID | sed 1d | fzf -m | awk '{print $2}')
    else
        pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
    fi  

    if [ "x$pid" != "x" ]
    then
        echo $pid | xargs kill -${1:-9}
    fi  
}



#https://medium.com/@calbertts/docker-and-fuzzy-finder-fzf-4c6416f5e0b5
runc() {
  export FZF_DEFAULT_OPTS='--height 90% --reverse --border'
  local image=$(docker images --format '{{.Repository}}:{{.Tag}}' | fzf-tmux --reverse --multi)
  if [[ $image != '' ]]; then
    echo -e "\n  \033[1mDocker image:\033[0m" $image
    read -e -p $'  \e[1mOptions: \e[0m' -i "-it --rm" options

    printf "  \033[1mChoose the command: \033[0m"
    local cmd=$(echo -e "/bin/bash\nsh" | fzf-tmux --reverse --multi)
    if [[ $cmd == '' ]]; then
        read -e -p $'  \e[1mCustom command: \e[0m' cmd
    fi
    echo -e "  \033[1mCommand: \033[0m" $cmd

    export FZF_DEFAULT_COMMAND='find ./ -type d -maxdepth 1 -exec basename {} \;'
    printf "  \033[1mChoose the volume: \033[0m"
    local volume=$(fzf-tmux --reverse --multi)
    local curDir=${PWD##*/}
    if [[ $volume == '.' ]]; then
        echo -e "  \033[1mVolume: \033[0m" $volume
        volume="`pwd`:/$curDir -w /$curDir"
    else
        echo -e "  \033[1mVolume: \033[0m" $volume
        volume="`pwd`/$volume:/$volume -w /$volume"
    fi

    export FZF_DEFAULT_COMMAND=""
    export FZF_DEFAULT_OPTS=""

    history -s runc
    history -s docker run $options -v $volume $image $cmd
    echo ''
    docker run $options -v $volume $image $cmd
  fi
}


# Select a docker container to start and attach to
function da() {
  local cid
  cid=$(docker ps -a | sed 1d | fzf -1 -q "$1" | awk '{print $1}')

  [ -n "$cid" ] && docker start "$cid" && docker attach "$cid"
}

# Select a running docker container to stop
function ds() {
  local cid
  cid=$(docker ps | sed 1d | fzf -q "$1" | awk '{print $1}')

  [ -n "$cid" ] && docker stop "$cid"
}

# Select a docker container to remove
function drm() {
  local cid
  cid=$(docker ps -a | sed 1d | fzf -q "$1" | awk '{print $1}')

  [ -n "$cid" ] && docker rm "$cid"
}


function delete-branches() {
  git branch |
    grep --invert-match '\*' |
    cut -c 3- |
    fzf --multi --preview="git log {}" |
    xargs --no-run-if-empty git branch --delete --force
}
