#!/usr/bin/env bash

[[ -n "$ENABLE_DEBUG_MODE" ]] && set -x

TERM="xterm-256color"
NO_TTY="${NO_TTY:-no}"
PIPED="${PIPED:-no}"
WORKDIR="$(mktemp -d)"
ZI_INIT_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/script-init.sh"
ZI_INIT="${WORKDIR}/script-init.sh"

ZI_P10K_HEAD_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/config/p10k-head"
ZI_HEAD_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/config/head"
ZI_SETOPT_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/config/setopt"
ZI_ZSTYLE_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/config/zstyle"

ZI_P10K_HEAD="${WORKDIR}/p10k-head"
ZI_HEAD="${WORKDIR}/head"
ZI_SETOPT="${WORKDIR}/setopt"
ZI_ZSTYLE="${WORKDIR}/zstyle"

# Message functions to print messages to the user.
WGET() { wget "$1" --quiet --show-progress; }
CURL() { curl -fSL --progress-bar "$1" -o "$2"; }
CMD() { command -v "$1" >/dev/null 2>&1; }
EXEC() { type -fP "$1" >/dev/null 2>&1; }
HAS_TERMINAL() { [ -t 0 ]; }
IS_TTY() { HAS_TERMINAL; }
IS_PIPED() { ! [ -t 1 ]; }
PRE_CHECKS() {
  if ! CMD zsh; then
    echo -e "Zsh not found on the system, please install it before proceeding..."
    exit 1
  fi
  if ! CMD git; then
    echo -e "Git is not installed, please install it first."
    exit 1
  fi
  if CMD curl; then
    DOWNLOAD="CURL"
    echo -e "Curl is set as downloader, proceeding..."
  elif CMD wget; then
    DOWNLOAD="WGET"
    echo -e "Wget is set as downloader, proceeding..."
  else
    echo "Neither curl nor wget are installed, please install one of them before proceeding."
    exit 1
  fi
}
GET_SOURCE() {
  if [[ ! -f "$ZI_INIT" ]]; then
    $DOWNLOAD "$ZI_INIT_URL" "$ZI_INIT" && command chmod g-rwX "$ZI_INIT"
  else
    echo -e "Unable to download zi-init.zsh, please check your internet connection."
  fi
  # shellcheck disable=SC1090
  source "$ZI_INIT"
}
SHOW_MENU() {
  while true; do
    clear
    echo -ne "
$TPGREEN❮ ZI ❯ Source$TPRESET
$TPDIM# ---============================================--- # $TPRESET
  $(CECHO '-green' '1)') Add setopt .zshrc
  $(CECHO '-green' '2)') Add zstyle .zshrc
  $(CECHO '-yellow' 'c)') Create .zshrc
  $(CECHO '-line')
  $(CECHO '-red' 'q)') Exit
$TPDIM# ---===========================================--- # $TPRESET
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
    NOTIFY "CHOICE 1"
    $DOWNLOAD "$ZI_SETOPT_URL" "$ZI_SETOPT"
    MSG_OK "Added setopt .zshrc"
    sleep 2
    ;;
  2)
    clear
    NOTIFY "CHOICE 2"
    $DOWNLOAD "$ZI_ZSTYLE_URL" "$ZI_ZSTYLE"
    MSG_OK "Added zstyle .zshrc"
    ;;
  3)
    clear
    NOTIFY "CHOICE 3"
    sleep 2
    ;;
  c | C)
    clear
    NOTIFY "CHOICE 10"
    CREATE_ZSHRC
    sleep 2
    ;;
  q | Q)
    clear
    MSG_NOTE "For any questions, your are welcome to discuss them on:"
    MSG_INFO "❮ ZI ❯ GitHub https://github.com/z-shell/zi/discussions"
    CLEANUP
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
CREATE_ZSHRC() {
  if [[ -f "$ZI_HEAD" ]]; then
    $DOWNLOAD "$ZI_HEAD_URL" "$ZI_HEAD"
    cat "$ZI_HEAD" >>"${HOME}/.zshrc"
  fi
  if [[ -f "$ZI_SETOPT" ]]; then
    cat "$ZI_SETOPT" >>"${HOME}/.zshrc"
  fi
  if [[ -f "$ZI_ZSTYLE" ]]; then
    cat "$ZI_ZSTYLE" >>"${HOME}/.zshrc"
  fi
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
    -c | --config)
      GET_OPTION="2"
      DO_SELECTION
      ;;
    *) ERORR "Unknown option, please try again" ;;
    esac
    shift
  done
}
MAIN() {
  PRE_CHECKS
  # shellcheck disable=SC1090
  GET_SOURCE && SET_COLORS
  DO_OPTIONS "${@}"
  CLEANUP
  return 0
}

MAIN "${@}" || return 1