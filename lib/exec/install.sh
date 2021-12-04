#!/usr/bin/env bash
[[ -n "$ENABLE_DEBUG_MODE" ]] && set -x

WORKDIR="$(mktemp -d)"
GIT_R="https://github.com"
ZI_REPO="${ZINIT_REPO:-z-shell/zi.git}"
PBAR_URL="https://raw.githubusercontent.com/z-shell/zi/main/lib/zsh/git-process-output.zsh"
ZI_INIT_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/script-init.sh"
PROGRESS_BAR="${WORKDIR}/git-process-output.zsh"
ZI_INIT="${WORKDIR}/zi-init.zsh"

# Hardcoding is something that should be avoided as much as possible.
# If you hardcode something on your code it will completely "destroy" the portability of your code in a great extent.
# For this reason I am looking to allow changes for default directories where possible to avoid hardcoding paths in the scripts.
# This file is a part of the Z-Shell ZI which will be maintained the flexibility and portability for the users.
[[ -z "$ZI_HOME" ]] && ZI_HOME="${ZI_HOME:-${ZDOTDIR:-$HOME}/.zi}"
[[ -z "$ZI_BIN_DIR" ]] && ZI_BIN_DIR="${ZI_BIN_DIR:-bin}"
[[ -z "$ZI_SOURCE" ]] && ZI_SOURCE="${ZI_SOURCE:-${ZI_HOME}/${ZI_BIN_DIR}/zi.zsh}"
[[ -z "$ZSHRC_FILE" ]] && ZSHRC_FILE="${ZSHRC_FILE:-ZDOTDIR:-$HOME}/.zshrc}}"

WGET() { wget "$1" --quiet --show-progress; }
CURL() { curl -fSL --progress-bar "$1" -o "$2"; }
CMD() { command -v "$1" >/dev/null 2>&1; }
EXEC() { type -fP "$1" >/dev/null 2>&1; }
GIT_E() { command git -C "${ZI_HOME}/${ZI_BIN_DIR}" "$@"; }
GIT_V() { GIT_E describe --tags 2>/dev/null; }
GIT_O() { GIT_E config -l | grep remote.origin.url | awk -F'=' '{print $2}'; }
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
  if [[ ! -f "$PROGRESS_BAR" ]]; then
    $DOWNLOAD "$PBAR_URL" "$PROGRESS_BAR" && command chmod g-rwX "$PROGRESS_BAR"
  else
    echo -e "Unable to download the progress bar"
    exit 1
  fi
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
DO_INSTALL() {
  if [[ -d "${ZI_HOME}/${ZI_BIN_DIR}/.git" ]]; then
    builtin cd "${ZI_HOME}/${ZI_BIN_DIR}" || ERROR "Something went wrong while changing directory to ${ZI_HOME}/${ZI_BIN_DIR}"
    MSG_NOTE "We found origin $(GIT_O) in the ❮ ZI ❯ source directory. Updating..."
    MSG_INFO "Re-initializing Z-Shell ❮ ZI ❯ at ${ZI_HOME}/${ZI_BIN_DIR}"
    git clean -d -f -f && MSG_INFO "Cleaned up the repository"
    git reset -q --hard HEAD && MSG_INFO "Reseting the index and working tree"
    git pull -q origin main && MSG_OK "Succesfully updated"
    MSG_OK "❮ ZI ❯ Origin: $(GIT_O)"
    MSG_OK "❮ ZI ❯ Version: $(GIT_V)"
  fi
  if [[ ! -f "$ZI_SOURCE" ]]; then
    builtin cd "$ZI_HOME" || ERROR "Something went wrong while changing directory"
    printf "\033[34;01m▓▒░\033[31;01m Installing the (\033[34;01m…Z-Shell…\033[36;01m…❮ ZI ❯…\033[31;01m)\n\033[0m"
    printf "\033[34;01m▓▒░\033[31;1m Interactive feature-rich plugin manager for (\033[34;01m…ZSH…\033[31;01m)\n\033[0m"

    {
      command git clone --progress "${GIT_R}/${ZI_REPO}" "${ZI_HOME}/${ZI_BIN_DIR}" 2>&1 | { "$PROGRESS_BAR" || cat; }
    } 2>/dev/null

    if [[ -f "$ZI_SOURCE" ]]; then
      builtin cd "${ZI_BIN_DIR}" || ERROR "Something went wrong while changing directory"
      MSG_OK "Installation successful."
      MSG_OK "❮ ZI ❯ Origin: $(GIT_O)"
      MSG_OK "❮ ZI ❯ Version: $(GIT_V)"
    else
      MSG_ERR "The clone has failed."
      ERROR "Please report issue to https://github.com/z-shell/zi/issues/new"
    fi
  fi
}
MAIN() {
  PRE_CHECKS
  GET_SOURCE
  # shellcheck disable=SC1090
  source "$ZI_INIT" && SET_COLORS
  SET_DIR
  DO_INSTALL
  CLEANUP
  exit 0
}
while true; do
  MAIN "${@}" || exit 1
done
