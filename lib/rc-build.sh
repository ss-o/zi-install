#!/usr/bin/env bash

[[ -n "$ENABLE_DEBUG_MODE" ]] && set -x

REPO_TAG="$(git describe --tags --abbrev=0)"

GET_PATHS() {
  SOURCE="${BASH_SOURCE[0]}"
  while [ -h "$SOURCE" ]; do
    ABSOLUTE_PATH="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$ABSOLUTE_PATH/$SOURCE"
  done
  ABSOLUTE_PATH="$(cd -P "$(dirname "$SOURCE")" && pwd)"
}
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
MSG_OK() { echo -e "\e[0m[ ${TPBOLD}${TPGREEN}✔\e[0m ]${TPBOLD} ➜➜➜ \e[0m[ ${TPGREEN}${*}\e[0m ]"; }
MSG_ERR() { echo -e "\e[0m[ ${TPBOLD}${TPRED}✖\e[0m ]${TPBOLD} ➜➜➜ \e[0m[ ${TPRED}${*}\e[0m ]"; }
MSG_INFO() { echo -e "\e[0m[ ${TPBOLD}${TPYELLOW}➜\e[0m ]${TPBOLD} ➜➜➜ \e[0m[ ${TPDIM}${TPYELLOW}${*}\e[0m ]"; }
MSG_NOTE() { echo -e "\e[0m[ ${TPBOLD}${TPCYAN}߹\e[0m ]${TPBOLD} ➜➜➜ \e[0m[ ${TPCYAN}${*}\e[0m ]"; }
ERROR() {
  MSG_ERR "$@" >&2
  exit 1
}
SUCCESS() { MSG_OK "$@"; }
FINISHED() {
  MSG_OK "$@"
  exit 0
}

MENU_1() {
  SET_COLORS
  echo -ne "
$TPGREEN ZI Source$TPRESET version: [$REPO_TAG]

$TPCYAN Please select an option: $TPRESET
$TPDIM # ====================== # $TPRESET
$(CECHO '-green' '1)') Test
$(CECHO '-red' '2)') Exit
$TPDIM # ====================== # $TPRESET
"
  until [[ "${OPTS_1}" =~ ^[0-9]+$ ]] && [ "${OPTS_1}" -ge 1 ] && [ "${OPTS_1}" -le 15 ]; do
    read -rp "Available options: [1-2]:" OPTS_1
  done
  case "${OPTS_1}" in
  1) MSG_INFO "Choice: Test" ;;
  2)
    MSG_NOTE "Choice: Exit"
    exit 0
    ;;
  esac
}
MENU_1
