#!/bin/sh

WORKDIR="$(mktemp -d)"

#ZINIT_HOME="${ZINIT_HOME:-$ZPLG_HOME}"
if [ -z "$ZINIT_HOME" ]; then
    ZINIT_HOME="${ZDOTDIR:-$HOME}/.zinit"
fi

#ZINIT_BIN_DIR_NAME="${ZINIT_BIN_DIR_NAME:-$ZPLG_BIN_DIR_NAME}"
if [ -z "$ZINIT_BIN_DIR_NAME" ]; then
   ZINIT_BIN_DIR_NAME="bin"
fi

if ! test -d "$ZINIT_HOME"; then
    mkdir "$ZINIT_HOME"
    chmod g-w "$ZINIT_HOME"
    chmod o-w "$ZINIT_HOME"
fi

if ! command -v git >/dev/null 2>&1; then
    echo "[1;31m▓▒░[0m Something went wrong: no [1;32mgit[0m available, cannot proceed."
    exit 1
fi

# Get the download-progress bar tool
if command -v curl >/dev/null 2>&1; then
    mkdir -p /tmp/zinit
    cd /tmp/zinit || return
    curl -fsSLO https://raw.githubusercontent.com/z-shell/zinit/main/git-process-output.zsh &&
        chmod a+x /tmp/zinit/git-process-output.zsh
elif command -v wget >/dev/null 2>&1; then
    mkdir -p /tmp/zinit
    cd /tmp/zinit || return
    wget -q https://raw.githubusercontent.com/z-shell/zinit/main/git-process-output.zsh &&
        chmod a+x /tmp/zinit/git-process-output.zsh
fi

echo
if test -d "$ZINIT_HOME/$ZINIT_BIN_DIR_NAME/.git"; then
    cd "$ZINIT_HOME/$ZINIT_BIN_DIR_NAME" || return
    echo "[1;34m▓▒░[0m Updating [1;36mZINIT[1;33m Initiative Plugin Manager[0m at [1;35m$ZINIT_HOME/$ZINIT_BIN_DIR_NAME[0m"
    git pull origin main
else
    cd "$ZINIT_HOME" || return
    echo "[1;34m▓▒░[0m Installing [1;36mZINIT[1;33m Initiative Plugin Manager[0m at [1;35m$ZINIT_HOME/$ZINIT_BIN_DIR_NAME[0m"
    { git clone --progress https://github.com/z-shell/zinit.git "$ZINIT_BIN_DIR_NAME" \
        2>&1 | { /tmp/zinit/git-process-output.zsh || cat; }; } 2>/dev/null
    if [ -d "$ZINIT_BIN_DIR_NAME" ]; then
        echo
        echo "[1;34m▓▒░[0m ZINIT Succesfully installed at [1;32m$ZINIT_HOME/$ZINIT_BIN_DIR_NAME[0m".
        VERSION="$(command git -C "$ZINIT_HOME/$ZINIT_BIN_DIR_NAME" describe --tags 2>/dev/null)"
        echo "[1;34m▓▒░[0m Version: [1;32m$VERSION[0m"
    else
        echo
        echo "[1;31m▓▒░[0m Something went wrong, couldn't install Zinit at [1;33m$ZINIT_HOME/$ZINIT_BIN_DIR_NAME[0m"
    fi
fi

#
# Modify .zshrc
#
THE_ZDOTDIR="${ZDOTDIR:-$HOME}"
RCUPDATE=1
if grep -E '(zinit|zplugin)\.zsh' "$THE_ZDOTDIR/.zshrc" >/dev/null 2>&1; then
    echo "[34m▓▒░[0m .zshrc already contains \`zinit …' commands – not making changes."
    RCUPDATE=0
fi

if [ $RCUPDATE -eq 1 ]; then
    echo "[34m▓▒░[0m Updating $THE_ZDOTDIR/.zshrc (10 lines of code, at the bottom)"
    ZINIT_HOME="$(echo $ZINIT_HOME | sed "s|$HOME|\$HOME|")"
    command cat <<-EOF >>"$THE_ZDOTDIR/.zshrc"
### Zinit
if [[ ! -f $ZINIT_HOME/$ZINIT_BIN_DIR_NAME/zi.zsh ]]; then
    print -P "%F{33}▓▒░ %F{160}Installing %F{33}ZINIT%F{160} Initiative Plugin Manager (%F{33}z-shell/zinit%F{160})…%f"
    command mkdir -p "$ZINIT_HOME" && command chmod g-rwX "$ZINIT_HOME"
    command git clone -q https://github.com/z-shell/zinit "$ZINIT_HOME/$ZINIT_BIN_DIR_NAME" && \\
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \\
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi
source "$ZINIT_HOME/$ZINIT_BIN_DIR_NAME/zi.zsh"
autoload -Uz _zi
(( \${+_comps} )) && _comps[zi]=_zi
EOF
    file="$(mktemp)"
    command cat <<-EOF >>"$file"
zi light-mode for \\
  z-shell/z-a-meta-plugins annexes
EOF
    echo
    echo "[38;5;219m▓▒░[0m Would you like to add the annexes to the zshrc?" \
        "It will be the following snippet:"
    command cat "$file"
    printf "[38;5;219m▓▒░[0m Enter y/n and press Return: "
    read -r input
    if [ "$input" = y ] || [ "$input" = Y ]; then
        command cat "$file" >>"$THE_ZDOTDIR"/.zshrc
        echo
        echo "[34m▓▒░[0m Done."
        echo
    else
        echo
        echo "[34m▓▒░[0m Done (skipped the annexes chunk)."
        echo
    fi
    command cat <<-EOF >>"$THE_ZDOTDIR/.zshrc"
EOF
fi
command cat <<-EOF
[34m▓▒░[0m Successfully installed!
For more information see:
- [38;5;226m Wiki:         https://github.com/z-shell/zi/wiki
- [38;5;226m Discussions:  https://github.com/z-shell/zi/discussions
- [38;5;226m Issues:       https://github.com/z-shell/zi/issues
EOF
