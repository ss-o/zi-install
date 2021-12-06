#!/usr/bin/env bash

[[ -n "$ENABLE_DEBUG_MODE" ]] && set -x

NO_TTY="${NO_TTY:-no}"
PIPED="${PIPED:-no}"
WORKDIR="$(mktemp -d)"
ZI_INIT_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/script-init.sh"
ZI_INIT="${WORKDIR}/script-init.sh"
ZI_ZSHRC="${HOME}/.zshrc"

ZI_ANNEX_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/config/annexes"
ZI_P10K_HEAD_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/config/p10k-head"
ZI_P10K_PROMT_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/config/p10k-prompt"
ZI_HEAD_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/config/head"
ZI_SETOPT_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/config/setopt"
ZI_ZSTYLE_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/config/zstyle"
ZI_FUZZY_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/config/fuzzy"
ZI_OMZ_LIB_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/config/omz-lib"
ZI_OMZ_PLUG_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/config/omz-plugins"
ZI_OMZ_THEME_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/config/omzt-robbyrussell"
ZI_REC_PLUG_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/config/rec-plugins"
ZI_CONSOLE_TOOLS_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/config/console-tools"
ZI_EXT_GIT_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/config/ext-git"
: ZI_SHARKDP_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/config/sharkdp"
ZI_RUST_UTILS_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/config/rust-utils"
ZI_ZSH_USERS_FAST_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/config/zsh-users%2Bfast"

ZI_ANNEX="${WORKDIR}/annexes"
ZI_P10K_HEAD="${WORKDIR}/p10k-head"
ZI_P10K_PROMT="${WORKDIR}/p10k-prompt"
ZI_HEAD="${WORKDIR}/head"
ZI_SETOPT="${WORKDIR}/setopt"
ZI_ZSTYLE="${WORKDIR}/zstyle"
ZI_FUZZY="${WORKDIR}/fuzzy"
ZI_OMZ_LIB="${WORKDIR}/omz-lib"
ZI_OMZ_PLUG="${WORKDIR}/omz-plugins"
ZI_OMZ_THEME="${WORKDIR}/omzt-robbyrussell"
ZI_REC_PLUG="${WORKDIR}/rec-plugins"
ZI_CONSOLE_TOOLS="${WORKDIR}/console-tools"
ZI_EXT_GIT="${WORKDIR}/ext-git"
: ZI_SHARKDP="${WORKDIR}/sharkdp"
ZI_RUST_UTILS="${WORKDIR}/rust-utils"
ZI_ZSH_USERS_FAST="${WORKDIR}/zsh-users-fast"

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
  $(CECHO '-green' '1)') Add setopt + zstyle
  $(CECHO '-green' '2)') Oh-My-Zsh library
  $(CECHO '-green' '3)') Oh-My-Zsh plugins
  $(CECHO '-green' '4)') Console tools + Fuzzy
  $(CECHO '-green' '5)') Exetended Git tools
  $(CECHO '-green' '6)') Rust utilities
  $(CECHO '-green' '7)') Zsh-Users + Fast-Syntax + History-MW
  $(CECHO '-green' '8)') Recommended plugins
  $(CECHO '-green' '9)') Powerlevel10k theme
  $(CECHO '-yellow' 'c)') Continue to create .zshrc
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
    $DOWNLOAD "$ZI_SETOPT_URL" "$ZI_SETOPT"
    NOTIFY "Added setopt"
    sleep 2
    $DOWNLOAD "$ZI_ZSTYLE_URL" "$ZI_ZSTYLE"
    NOTIFY "Added zstyle"
    sleep 2
    ;;
  2)
    clear
    $DOWNLOAD "$ZI_OMZ_LIB_URL" "$ZI_OMZ_LIB"
    NOTIFY "Added oh-my-zsh library"
    sleep 2
    ;;
  3)
    clear
    $DOWNLOAD "$ZI_OMZ_PLUG_URL" "$ZI_OMZ_PLUG"
    NOTIFY "Added oh-my-zsh plugins"
    sleep 2
    ;;
  4)
    clear
    $DOWNLOAD "$ZI_CONSOLE_TOOLS_URL" "$ZI_CONSOLE_TOOLS"
    NOTIFY "Added Console-tools"
    sleep 2
    $DOWNLOAD "$ZI_FUZZY_URL" "$ZI_FUZZY"
    NOTIFY "Added Fuzzy"
    sleep 2
    ;;
  5)
    clear
    $DOWNLOAD "$ZI_EXT_GIT_URL" "$ZI_EXT_GIT"
    NOTIFY "Added Extended Git tools"
    sleep 2
    ;;
  6)
    clear
    $DOWNLOAD "$ZI_RUST_UTILS_URL" "$ZI_RUST_UTILS"
    NOTIFY "Added Rust utilities"
    sleep 2
    ;;
  7)
    clear
    $DOWNLOAD "$ZI_ZSH_USERS_FAST_URL" "$ZI_ZSH_USERS_FAST"
    NOTIFY "Added Zsh-Users + Fast-Syntax + History-MW"
    sleep 2
    ;;
  8)
    clear
    $DOWNLOAD "$ZI_REC_PLUG_URL" "$ZI_REC_PLUG"
    NOTIFY "Added Recommended plugins"
    sleep 2
    ;;
  9)
    clear
    $DOWNLOAD "$ZI_P10K_HEAD_URL" "$ZI_P10K_HEAD"
    $DOWNLOAD "$ZI_P10K_PROMT_URL" "$ZI_P10K_PROMT"
    NOTIFY "Added powerlevel10k theme"
    sleep 2
    ;;
  c | C)
    clear
    NOTIFY "Creating .zshrc"
    sleep 2
    CREATE_ZSHRC
    MSG_OK "Created .zshrc"
    sleep 2
    MSG_NOTE "Review/edit your .zshrc file"
    sleep 2
    MSG_NOTE "Reload your shell for changes to take effect"
    sleep 2
    CLEANUP
    exit 0
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
  if [[ -f "$ZI_ZSHRC" ]]; then
    MSG_INFO "File .zshrc already exists, please select an option:"
    MSG_NOTE "Press [y] to overwrite, [n] to exit, default is [n]"
    if CONTINUE; then
      rm -rf "$ZI_ZSHRC"
    else
      CLEANUP
      exit 0
    fi
  fi
  if [[ -f "$ZI_P10K_HEAD" ]]; then
    cat "$ZI_P10K_HEAD" >>"${HOME}/.zshrc"
  fi
  if [[ ! -f "$ZI_HEAD" ]]; then
    $DOWNLOAD "$ZI_HEAD_URL" "$ZI_HEAD"
    cat "$ZI_HEAD" >>"${HOME}/.zshrc"
  fi
  if [[ -f "$ZI_SETOPT" ]]; then
    cat "$ZI_SETOPT" >>"${HOME}/.zshrc"
  fi
  if [[ -f "$ZI_ZSTYLE" ]]; then
    cat "$ZI_ZSTYLE" >>"${HOME}/.zshrc"
  fi
  if [[ -f "$ZI_OMZ_LIB" ]]; then
    cat "$ZI_OMZ_LIB" >>"${HOME}/.zshrc"
  fi
  if [[ -f "$ZI_OMZ_PLUG" ]]; then
    cat "$ZI_OMZ_PLUG" >>"${HOME}/.zshrc"
  fi
  if [[ ! -f "$ZI_ANNEX" ]]; then
    $DOWNLOAD "$ZI_ANNEX_URL" "$ZI_ANNEX"
    cat "$ZI_ANNEX" >>"${HOME}/.zshrc"
  fi
  if [[ -f "$ZI_CONSOLE_TOOLS" ]]; then
    cat "$ZI_CONSOLE_TOOLS" >>"${HOME}/.zshrc"
  fi
  if [[ -f "$ZI_FUZZY" ]]; then
    cat "$ZI_FUZZY" >>"${HOME}/.zshrc"
  fi
  if [[ -f "$ZI_EXT_GIT" ]]; then
    cat "$ZI_EXT_GIT" >>"${HOME}/.zshrc"
  fi
  if [[ -f "$ZI_RUST_UTILS" ]]; then
    cat "$ZI_RUST_UTILS" >>"${HOME}/.zshrc"
  fi
  if [[ -f "$ZI_ZSH_USERS_FAST" ]]; then
    cat "$ZI_ZSH_USERS_FAST" >>"${HOME}/.zshrc"
  fi
  if [[ -f "$ZI_REC_PLUG" ]]; then
    cat "$ZI_REC_PLUG" >>"${HOME}/.zshrc"
  fi
  if [[ -f "$ZI_P10K_PROMT" ]]; then
    cat "$ZI_P10K_PROMT" >>"${HOME}/.zshrc"
  else
    $DOWNLOAD "$ZI_OMZ_THEME_URL" "$ZI_OMZ_THEME"
    cat "$ZI_OMZ_THEME" >>"${HOME}/.zshrc"
  fi
}

DO_OPTIONS() {
  if HAS_TERMINAL; then
    TERM="xterm-256color"
  fi
  if ! IS_TTY; then
    NO_TTY=yes
  fi
  while [ $# = 0 ]; do
    SHOW_MENU "${@}"
  done
  while [ $# -gt 0 ]; do
    case "$1" in
    -1)
      GET_OPTION="1"
      DO_SELECTION
      ;;
    -2)
      GET_OPTION="2"
      DO_SELECTION
      ;;
    -3)
      GET_OPTION="3"
      DO_SELECTION
      ;;
    -4)
      GET_OPTION="4"
      DO_SELECTION
      ;;
    -5)
      GET_OPTION="5"
      DO_SELECTION
      ;;
    -6)
      GET_OPTION="6"
      DO_SELECTION
      ;;
    -7)
      GET_OPTION="7"
      DO_SELECTION
      ;;
    -8)
      GET_OPTION="8"
      DO_SELECTION
      ;;
    -9)
      GET_OPTION="9"
      DO_SELECTION
      ;;
    -c)
      GET_OPTION="c"
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
  return 0
}

MAIN "${@}" || return 1
