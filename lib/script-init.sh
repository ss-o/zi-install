#!/usr/bin/env bash
[[ -n "$ENABLE_DEBUG_MODE" ]] && set -x
# SET_WORKDIR SET_PATHS SET_COLORS
# shellcheck disable=SC2034
REPO_TAG="$(git describe --tags)"

SET_WORKDIR() {
  if test -d "$(maketemp -d -t zi-workdir.XXXXXXXXXX)"; then
    WORKDIR="(mktemp -d -t zi-workdir.XXXXXXXXXX)"
  fi
  if ! test -d "$WORKDIR"; then
    WORKDIR="(mktemp -d)"
  fi
  if ! test -d "$WORKDIR"; then
    WORKDIR="/tmp/zi-workdir$$"
  fi
  if ! test -d "$WORKDIR"; then
    if test mkdir -p "$(pwd)/temp"; then
      WORKDIR="$(pwd)/temp"
      mkdir -p "$WORKDIR"
    else
      echo -e "Unable to create safe work environment to proceed."
      echo -e "For assistance, please open new issue at https://github.com/zi-source/issues/new"
      exit 1
    fi
  fi
}

# Function to setup the environment path.
SET_PATHS() {
  SOURCE="${BASH_SOURCE[0]}"
  while [ -h "$SOURCE" ]; do
    ABSOLUTE_PATH="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$ABSOLUTE_PATH/$SOURCE"
  done
  ABSOLUTE_PATH="$(cd -P "$(dirname "$SOURCE")" && pwd)"
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
MSG_OK() { echo -e "\e[0m[ ${TPGREEN}✔\e[0m ]${TPBOLD} ➜➜➜ \e[0m[ ${TPGREEN}${*}\e[0m ]"; }
MSG_ERR() { echo -e "\e[0m[ ${TPRED}✖\e[0m ]${TPBOLD} ➜➜➜ \e[0m[ ${TPRED}${*}\e[0m ]"; }
MSG_INFO() { echo -e "\e[0m[ ${TPBOLD}${TPYELLOW}➜\e[0m ]${TPBOLD} ➜➜➜ \e[0m[ ${TPBOLD}${TPYELLOW}${*}\e[0m ]"; }
MSG_NOTE() { echo -e "\e[0m[ ${TPBOLD}${TPCYAN}߹\e[0m ]${TPBOLD} ➜➜➜ \e[0m[ ${TPBOLD}${TPCYAN}${*}\e[0m ]"; }
CLEANUP() {
  [[ -d "$WORKDIR" ]] && rm -rf "$WORKDIR"
}
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
  if [ ! -e "${WORKDIR}" ]; then
    trap 'rm -rvf ${WORKDIR}; $?' INT TERM EXIT
    echo -e "Session started" >"${WORKDIR}/session.log"
    "${@}"
    rm -rvf "${WORKDIR}"
    trap - INT TERM EXIT
  else
    ERORR "Failed to start session"
  fi
}
