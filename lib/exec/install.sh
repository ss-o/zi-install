#!/usr/bin/env bash
[[ -n "$ENABLE_DEBUG_MODE" ]] && set -x

NO_TTY="${NO_TTY:-no}"
PIPED="${PIPED:-no}"
WORKDIR="$(mktemp -d)"
GIT_R="https://github.com"
ZI_REPO="${ZINIT_REPO:-z-shell/zi.git}"
: PBAR_URL="https://raw.githubusercontent.com/z-shell/zi/main/lib/zsh/git-process-output.zsh"
ZI_INIT_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/script-init.sh"
: PROGRESS_BAR="${WORKDIR}/git-process-output.zsh"
ZI_INIT="${WORKDIR}/script-init.zsh"
ZI_ZSHRC_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/config/temp_zshrc"
ZI_ZSHRC="${WORKDIR}/temp_zshrc"

# Hardcoding is something that should be avoided as much as possible.
# If you hardcode something on your code it will completely "destroy" the portability of your code in a great extent.
# For this reason I am looking to allow changes for default directories where possible to avoid hardcoding paths in the scripts.
# This file is a part of the Z-Shell ZI which will be maintained the flexibility and portability for the users.
[[ -z "$ZI_HOME" ]] && ZI_HOME="${ZI_HOME:-${ZDOTDIR:-$HOME}/.zi}"
[[ -z "$ZI_BIN_DIR" ]] && ZI_BIN_DIR="${ZI_BIN_DIR:-bin}"
[[ -z "$ZI_SOURCE" ]] && ZI_SOURCE="${ZI_SOURCE:-${ZI_HOME}/${ZI_BIN_DIR}/zi.zsh}"
[[ -z "$ZSHRC_FILE" ]] && ZSHRC_FILE="${ZSHRC_FILE:-${ZDOTDIR:-$HOME}/.zshrc}"

WGET() { wget "$1" --quiet --show-progress; }
CURL() { curl -fSL --progress-bar "$1" -o "$2"; }
CMD() { command -v "$1" >/dev/null 2>&1; }
EXEC() { type -fP "$1" >/dev/null 2>&1; }
HAS_TERMINAL() { [ -t 0 ]; }
IS_TTY() { HAS_TERMINAL; }
IS_PIPED() { ! [ -t 1 ]; }
GIT_E() { command git -C "${ZI_HOME}/${ZI_BIN_DIR}" "$@"; }
GIT_V() { GIT_E describe --tags 2>/dev/null; }
GIT_O() { GIT_E config -l | grep remote.origin.url | awk -F'=' '{print $2}'; }
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
    exit 1
  fi
  #if [[ ! -f "$PROGRESS_BAR" ]]; then
  #  $DOWNLOAD "$PBAR_URL" "$PROGRESS_BAR" && command chmod a+x "$PROGRESS_BAR"
  #else
  #  echo -e "Unable to download the progress bar"
  #  exit 1
  #fi
  # shellcheck disable=SC1090
  source "$ZI_INIT"
}

SET_DIR() {
  if ! test -d "$ZI_HOME"; then
    command mkdir -p "$ZI_HOME"
    command chmod g-rwX "$ZI_HOME"
    MSG_OK "Successfully created ❮ ZI ❯ Home directory"
  fi
  if ! test -d "${ZI_HOME}/${ZI_BIN_DIR}"; then
    command mkdir -p "${ZI_HOME}/${ZI_BIN_DIR}"
    command chmod g-rwX "${ZI_HOME}/${ZI_BIN_DIR}"
    MSG_OK "Successfully created ❮ ZI ❯ Bin directory"
  fi
}
CREATE_ZSHRC() {
  if [[ -f "$ZSHRC_FILE" ]]; then
    MSG_INFO "File .zshrc already exists, please select an option:"
    MSG_NOTE "Press [y] to overwrite, [n] to exit, default is [n]:"
    if CONTINUE; then
      rm -rf "$ZI_ZSHRC"
    else
      CLEANUP
      exit 0
    fi
  fi
  $DOWNLOAD "$ZI_ZSHRC_URL" "$ZI_ZSHRC"
  cat "$ZI_ZSHRC" >"$ZSHRC_FILE"
}

DO_INSTALL() {
  CREATE_ZSHRC
  if [[ -d "${ZI_HOME}/${ZI_BIN_DIR}/.git" ]]; then
    builtin cd "${ZI_HOME}/${ZI_BIN_DIR}" || ERROR "Something went wrong while changing directory to ${ZI_HOME}/${ZI_BIN_DIR}"
    MSG_NOTE "We found ❮ ZI ❯ directory. Updating..."
    MSG_INFO "Re-initializing Z-Shell ❮ ZI ❯ at ${ZI_HOME}/${ZI_BIN_DIR}"
    git clean -d -f -f && git reset -q --hard HEAD
    clear
    TITLE "Update successfully completed ❮ ZI ❯ Version: $(GIT_V)"
  else
    SET_DIR
    builtin cd "$ZI_HOME" || ERROR "Something went wrong while changing directory"
    MSG_NOTE "Installing the (\033[34;01m…Z-Shell…\033[36;01m …❮ ZI ❯…)\033[0m"
    MSG_NOTE "Interactive feature-rich plugin manager for (\033[34;01m…ZSH…\033[36;01m)\033[0m"
    ##{ command git clone -q "${GIT_R}/${ZI_REPO}" "${ZI_HOME}/${ZI_BIN_DIR}" 2>&1 | { $PROGRESS_BAR || cat; }; } 2>/dev/null
    command git clone -q "${GIT_R}/${ZI_REPO}" "${ZI_HOME}/${ZI_BIN_DIR}"
    if [[ -f "$ZI_SOURCE" ]]; then
      clear
      TITLE "❮ ZI ❯ Install successfully completed ❮ ZI ❯ Version: $(GIT_V)"
    else
      MSG_ERR "The clone has failed."
      ERROR "Please report issue to https://github.com/z-shell/zi/issues/new"
    fi
  fi
}
MAIN() {
  PRE_CHECKS
  GET_SOURCE && SET_COLORS
  if HAS_TERMINAL; then
    TERM="xterm-256color"
  fi
  if ! IS_TTY; then
    NO_TTY=yes
  fi
  DO_INSTALL
  MSG_INFO "For additional questions or support please visit:      "
  MSG_NOTE "Discussions:  https://github.com/z-shell/zi/discussions"
  MSG_NOTE "Issues:       https://github.com/z-shell/zi/issues/new "
  CLEANUP
  exit 0
}
MAIN "${@}" || return 1
