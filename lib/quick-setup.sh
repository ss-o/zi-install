#!/usr/bin/env bash
trap '' SIGINT SIGQUIT SIGTERM
[[ -n "$ENABLE_DEBUG_MODE" ]] && set -x
: TERM="xterm-256color"
: GITOPT="-q"
: GITSUB="--quiet"
: GITSUBOPT="--quiet"
: NO_TTY="${NO_TTY:-no}"
: PIPED="${PIPED:-no}"
: SRC_INSTALL_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/exec/install.sh"
: SRC_INIT_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/script-init.sh"
: SRC_INSTALL="${WORKDIR}/install.sh"
: SRC_INIT="${WORKDIR}/script-init.sh"
# shellcheck disable=SC2034
REPO_TAG="$(git describe --tags)"

SET_WORKDIR() {
  WORKDIR="(mktemp -d -t zi-workdir.XXXXXXXXXX)"
  if test "$WORKDIR"; then
    WORKDIR="(mktemp -d -t zi-workdir.XXXXXXXXXX)"
  else
    WORKDIR="(mktemp -d)"
    if test -d "$WORKDIR"; then
      WORKDIR="(mktemp -d)"
    else
      WORKDIR="/tmp/zi-workdir$$"
      if test -d "$WORKDIR"; then
        WORKDIR="/tmp/zi-workdir$$"
      else
        if command -v mkdir -p "$(PWD)/temp" >/dev/null 2>&1; then
          WORKDIR="$(PWD)/temp"
          mkdir -p "$WORKDIR"
        else
          echo -e "Unable to create safe work environment to proceed."
          echo -e "For assistance, please open new issue at https://github.com/zi-source/issues/new"
          exit 1
        fi
      fi
    fi
  fi
}
# Function enables colors for interactive shells.
SET_COLORS() {
  TPRESET=""
  TPRED=""
  TPGREEN=""
  TPYELLOW=""
  TPBLUE=""
  TPMAGENTA=""
  TPCYAN=""
  TPWHITE=""
  TPBGRED=""
  TPBGGREEN=""
  TPBOLD=""
  TPDIM=""
  test -t 2 || return 1
  if command -v tput >/dev/null 2>&1; then
    if [ $(($(tput colors 2>/dev/null))) -ge 8 ]; then
      TPRESET="$(tput sgr 0)"
      TPRED="$(tput setaf 1)"
      TPGREEN="$(tput setaf 2)"
      TPYELLOW="$(tput setaf 3)"
      TPBLUE="$(tput setaf 4)"
      TPMAGENTA="$(tput setaf 5)"
      TPCYAN="$(tput setaf 6)"
      TPWHITE="$(tput setaf 7)"
      TPBGRED="$(tput setab 1)"
      TPBGGREEN="$(tput setab 2)"
      TPBOLD="$(tput bold)"
      TPDIM="$(tput dim)"
    fi
  fi
  return 0
}
TITLE() {
  printf "\033[30;46m"
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' ' '
  printf '%-*s\n' "${COLUMNS:-$(tput cols)}" "  # $1" | tr ' ' ' '
  printf '%*s' "${COLUMNS:-$(tput cols)}" '' | tr ' ' ' '
  printf "\e[0m"
  printf "\n"
}
NOTIFY() {
  printf "\033[30;42m"
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' ' '
  printf '%-*s\n' "${COLUMNS:-$(tput cols)}" "  # $1" | tr ' ' ' '
  printf '%*s' "${COLUMNS:-$(tput cols)}" '' | tr ' ' ' '
  printf "\e[0m"
  printf "\n"
}
# Aditional echo colors
CECHO() {
  while [[ "$1" ]]; do
    case "$1" in
    -norm) color="\033[00m" ;;
    -black) color="\033[30;01m" ;;
    -red) color="\033[31;01m" ;;
    -green) color="\033[32;01m" ;;
    -yellow) color="\033[33;01m" ;;
    -blue) color="\033[34;01m" ;;
    -magenta) color="\033[35;01m" ;;
    -cyan) color="\033[36;01m" ;;
    -white) color="\033[37;01m" ;;
    -line)
      one_line=1
      shift
      continue
      ;;
    *)
      echo -n "$1"
      shift
      continue
      ;;
    esac

    shift
    echo -en "$color"
    echo -en "$1"
    echo -en "\033[00m"
    shift

  done
  if [[ ! $one_line ]]; then
    echo
  fi
}
# Message functions to print messages to the user.
HAS_TERMINAL() { [ -t 0 ]; }
IS_TTY() { HAS_TERMINAL; }
IS_PIPED() { ! [ -t 1 ]; }
MSG_OK() { echo -e "\e[0m[ ${TPGREEN}✔\e[0m ]${TPBOLD} ➜➜➜ \e[0m[ ${TPGREEN}${*}\e[0m ]"; }
MSG_ERR() { echo -e "\e[0m[ ${TPRED}✖\e[0m ]${TPBOLD} ➜➜➜ \e[0m[ ${TPRED}${*}\e[0m ]"; }
MSG_INFO() { echo -e "\e[0m[ ${TPBOLD}${TPYELLOW}➜\e[0m ]${TPBOLD} ➜➜➜ \e[0m[ ${TPBOLD}${TPYELLOW}${*}\e[0m ]"; }
MSG_NOTE() { echo -e "\e[0m[ ${TPBOLD}${TPCYAN}߹\e[0m ]${TPBOLD} ➜➜➜ \e[0m[ ${TPBOLD}${TPCYAN}${*}\e[0m ]"; }
CLEANUP() { [[ -d "$WORKDIR" ]] && rm -rvf "$WORKDIR"; }
# Prints error message and exits with error code 1.
ERROR() {
  MSG_ERR "$@" >&2
  CLEANUP
  exit 1
}
# Prints success message and exits with error code 0.
FINISHED() {
  MSG_OK "$@"
  exit 0
}
# Functions to reduce the amount of code in the scripts.
WGET() { wget "$1" --quiet --show-progress; }
CURL() { curl -fSL --progress-bar "$1" -o "$2"; }
CMD() { command -v "$1" >/dev/null 2>&1; }
EXEC() { type -fP "$1" >/dev/null 2>&1; }
MAKE_DIR() { [[ ! -d "$1" ]] && mkdir -p "$1"; }
CONTINUE() {
  read -r -p "$1* [y/N]" response
  case $response in
  [yY][eE][sS] | [yY])
    true
    ;;
  *)
    false
    ;;
  esac
}
NO_ROOT() {
  if [[ $USER == "root" ]]; then
    ERROR "Do not run as root, no privileges required."
  fi
}
SYMLINK() {
  local src="$1" dst="$2"
  local overwrite='' backup='' skip=''
  local action=''
  #shellcheck disable=SC2166
  if [ -f "$dst" -o -d "$dst" -o -L "$dst" ]; then
    if [ "$overwrite_all" == "false" ] && [ "$backup_all" == "false" ] && [ "$skip_all" == "false" ]; then
      currentSrc="$(readlink "$dst")"
      if [ "$currentSrc" == "$src" ]; then
        skip=true
      else
        "File $dst ($(basename "$src")) already exists, what do you want to do?"
        "[s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
        read -n 1 action
        case "$action" in
        o)
          overwrite=true
          ;;
        O)
          overwrite_all=true
          ;;
        b)
          backup=true
          ;;
        B)
          backup_all=true
          ;;
        s)
          skip=true
          ;;
        S)
          skip_all=true
          ;;
        *) ;;
        esac
      fi
    fi
    overwrite=${overwrite:-$overwrite_all}
    backup=${backup:-$backup_all}
    skip=${skip:-$skip_all}
    if [ "$overwrite" == "true" ]; then
      rm -rf "$dst" && MSG_INFO "Removed $dst"
    fi
    if [ "$backup" == "true" ]; then
      mv "$dst" "${dst}.backup" && MSG_INFO "Backup made - ${dst}.backup"
    fi
    if [ "$skip" == "true" ]; then
      MSG_INFO "Skipped $src"
    fi
  fi
  if [ "$skip" != "true" ]; then
    ln -fs "$1" "$2" && MSG_OK "Linked $1 to $2"
  fi
}
START_WORK_SESSION() {
  NO_ROOT
  SET_WORKDIR
  if [ ! -e "${WORKDIR}" ]; then
    trap 'CLEANUP' INT TERM EXIT
    touch "${WORKDIR}/session.log"
    SHOW_MENU
    CLEANUP
    trap - INT TERM EXIT
    return 0
  else
    ERORR "Failed to start session"
  fi
}

SHOW_MENU() {
  while true; do
    clear
    SET_COLORS
    echo -ne "
$TPGREEN ❮ ZI ❯ Source$TPRESET v$REPO_TAG
$TPDIM # ---============================================--- # $TPRESET
$(CECHO '-green' '1)') Just install ❮ ZI ❯
$(CECHO '-green' '2)') Build ZSHRC
$(CECHO '-green' '3)') Run install + ZSHRC
$(CECHO '-line')
$(CECHO '-red' 'q)') Exit
$TPDIM # ---===========================================--- # $TPRESET
"
    read -rp "$TPCYAN Please select an option:$TPRESET " GET_OPTION
    if { [[ "${GET_OPTION}" =~ ^[A-Za-z0-9]+$ ]] || [[ "${GET_OPTION}" -gt 0 ]]; }; then
      DO_SELECTION
    fi
  done
}

DO_SELECTION() {
  case "${GET_OPTION}" in
  1)
    clear
    MSG_OK "Installing ❮ ZI ❯"
    sleep 3
    if [ -f "$(PWD)/exec/install.sh" ]; then
      bash "$(PWD)/exec/install.sh"
      exit 0
    else
      bash <(https://git.io/zi-install)
      exit 0
    fi
    ;;
  2)
    clear
    NOTIFY "CHOICE 2"
    sleep 4
    ;;
  3)
    clear
    MSG_INFO "CHOICE 3"
    ;;
  q | Q)
    clear
    MSG_NOTE "For any questions, your are welcome to discuss them on:"
    MSG_INFO "❮ ZI ❯ GitHub https://github.com/z-shell/zi/discussions"
    FINISHED "Session finished successfully"
    ;;
  *)
    clear && MSG_NOTE "Invalid option, please try again"
    sleep 2
    MSG_INFO "To force quit press [CTRL+C]"
    sleep 2
    ;;
  esac
  shift
}
DO_OPTIONS() {
  if HAS_TERMINAL; then
    export TERM
    echo "$TERM"
  fi
  if ! IS_TTY; then
    NO_TTY=yes
  fi
  while [ $# = 0 ]; do
    SHOW_MENU "${@}"
  done
  while [ $# -gt 0 ]; do
    case $1 in
    -i | --install)
      GET_OPTION="1"
      DO_SELECTION
      ;;
    *) ERORR "Unknown option, please try again" ;;
    esac
    shift
  done
}
MAIN() {
  DO_OPTIONS "${@}"
  FINISHED "Session finished successfully"
}

while true; do
  MAIN "${@}"
done
