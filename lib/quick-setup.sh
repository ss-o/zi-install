#!/usr/bin/env bash

[[ -n "$ENABLE_DEBUG_MODE" ]] && set -x

TERM="xterm-256color"
NO_TTY="${NO_TTY:-no}"
PIPED="${PIPED:-no}"
WORKDIR="$(mktemp -d)"
ZI_INSTALL_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/exec/install.sh"
ZI_INIT_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/script-init.sh"
ZI_INSTALL="${WORKDIR}/install.sh"
ZI_INIT="${WORKDIR}/script-init.sh"

# Message functions to print messages to the user.
WGET() { wget "$1" --quiet --show-progress; }
CURL() { curl -fSL --progress-bar "$1" -o "$2"; }
CMD() { command -v "$1" >/dev/null 2>&1; }
EXEC() { type -fP "$1" >/dev/null 2>&1; }
HAS_TERMINAL() { [ -t 0 ]; }
IS_TTY() { HAS_TERMINAL; }
IS_PIPED() { ! [ -t 1 ]; }
PRE_CHECKS() {
  if CMD zsh; then
    echo -e "$(zsh --version) found on the system, proceeding..."
    sleep 1
  else
    echo -e "Zsh not found on the system, please install it before proceeding..."
    exit 1
  fi
  if CMD git; then
    echo -e "Git is installed, proceeding..."
    sleep 1
  else
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
    echo -ne "
$TPGREEN❮ ZI ❯ Source$TPRESET
$TPDIM# ---============================================--- # $TPRESET
  $(CECHO '-green' '1)') Install ❮ ZI ❯
  $(CECHO '-green' '2)') Build ZSHRC
  $(CECHO '-green' '3)') Run install + ZSHRC
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
    MSG_OK "Installing ❮ ZI ❯"
    sleep 2
    $DOWNLOAD "$ZI_INSTALL_URL" "$ZI_INSTALL" && command chmod g-rwX "$ZI_INSTALL"
    builtin source "$ZI_INSTALL"
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
  PRE_CHECKS
  # shellcheck disable=SC1090
  GET_SOURCE && SET_COLORS
  DO_OPTIONS "${@}"
}
while true; do
  MAIN "${@}"
done
