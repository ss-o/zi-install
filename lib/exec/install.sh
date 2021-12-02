#!/usr/bin/env bash
[[ -n "$ENABLE_DEBUG_MODE" ]] && set -x
source "../script-init.sh"

GIT_R="https://github.com"
ZI_REPO="${ZINIT_REPO:-z-shell/zi.git}"
ZI_SOURCE="${ZI_HOME}/${ZI_BIN_NAME}/zi.zsh"
PBAR_URL="https://raw.githubusercontent.com/z-shell/zinit/main/git-process-output.zsh"
ZI_VERSION="$(command git -C "${ZI_HOME}/${ZI_BIN_NAME}" describe --tags 2>/dev/null)"
PROGRESS_BAR="${WORKDIR}/git-process-output.zsh"
ZSHRC="${ZSHRC:-${XDG_DATA_HOME:-ZDOTDIR:-$HOME}/.zshrc}}"

CHECK_DEPENDENCIES() {
if CMD zsh; then
MSG_OK "$(zsh --version) found on the system, proceeding..."
sleep 1
  if CMD git; then
  MSG_OK "Git is installed, proceeding..."
  sleep 1
  else
    ERROR "Git is not installed, please install it first."
  fi
fi
}

CHECK_DIRECTORIES() {
[[ -z "$ZI_HOME" ]] && ZI_HOME="${ZI_HOME:-${XDG_DATA_HOME:-$ZDOTDIR:-$HOME}/.zi}"
[[ -z "$ZI_BIN_DIR" ]] && ZI_BIN_DIR="${ZI_BIN_DIR:-bin}"
  if [ ! -f "$ZI_SOURCE" ]; then
  if ! test -d "$ZI_HOME"; then
    command mkdir -p "$ZI_HOME"
    command chmod g-rwX "$ZI_HOME"
    MSG_OK "Successfully created ❮ ZI ❯ Home directory"
  fi
  if ! test -d "${ZI_HOME}/${ZI_BIN_NAME}"; then
    command mkdir -p "${ZI_HOME}/${ZI_BIN_NAME}"
    command chmod g-rwX "${ZI_HOME}/${ZI_BIN_NAME}"
    MSG_OK "Successfully created ❮ ZI ❯ bin directory"
  fi
fi
}

GET_PROGRESS_BAR() {
    if CMD curl; then
        CURL "$PBAR_URL" "$PROGRESS_BAR" || ERROR "Failed to download resource"
    elif CMD wget; then
        WGET "$PBAR_URL" "$PROGRESS_BAR" || ERROR "Failed to download resource"
    fi
    chmod a+x "$PROGRESS_BAR"
}

if test -d "${ZI_HOME}/${ZI_BIN_NAME}/.git"; then
  MSG_NOTE "We found a git repository in the ❮ ZI ❯ source directory. Updating..."
  builtin cd "${ZI_HOME}/${ZI_BIN_NAME}" || ERROR "Something went wrong while changing directory"
  MSG_INFO "Re-initializing Z-Shell ❮ ZI ❯ at ${ZI_HOME}/${ZI_BIN_NAME}"
  git clean -d -f -f && MSG_INFO "Cleaned up the repository"
  git reset -q --hard HEAD && MSG_INFO "Reseting the index and working tree"
  git pull -q origin main && MSG_OK "Succesfully updated"
  MSG_INFO "❮ ZI ❯ Version: $ZI_VERSION"
fi
  GET_PROGRESS_BAR || ERROR "Failed to download progress bar"
  builtin cd "$ZI_HOME" || ERROR "Something went wrong while changing directory"
  printf "\033[34;01m▓▒░\033[31;01m Installing the (\033[34;01m…Z-Shell…\033[36;01m…❮ ZI ❯…\033[31;01m)\n\033[0m"
  printf "\033[34;01m▓▒░\033[31;1m Interactive feature-rich plugin manager for (\033[34;01m…ZSH…\033[31;01m)\n\033[0m"
  { git clone --depth 1 --progress "${GIT_R}/${ZI_REPO}" "${ZI_HOME}/${ZI_BIN_NAME}" 2>&1 | { "$PROGRESS_BAR" || cat; }; } 2>/dev/null
  if [ -f "$ZI_SOURCE" ]; then
    MSG_OK "Installation successful."
    MSG_INFO "❮ ZI ❯ Version: $ZI_VERSION"
  else
    MSG_ERR "The clone has failed."
    ERROR "Please report issue to https://github.com/z-shell/zi/issues/new"
  fi
fi
