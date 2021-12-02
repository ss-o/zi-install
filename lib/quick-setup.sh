#!/usr/bin/env bash
[[ -n "$ENABLE_DEBUG_MODE" ]] && set -x

SRC_INSTALL_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/exec/install.sh"
SRC_INIT_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/script-init.sh"
SRC_INSTALL="${WORKDIR}/install.sh"
SRC_INIT="${WORKDIR}/script-init.sh"
WORKDIR="(mktemp -d)"
SOURCE="${BASH_SOURCE[0]}"
if ! command -v git >/dev/null 2>&1; then
  echo -e "Git is not installed. Please install to proceed."
  exit 1
fi
if ! command -v curl >/dev/null 2>&1; then
  echo -e "Curl is not installed. Please install to proceed"
fi
while [ -h "$SOURCE" ]; do
  ABSOLUTE_PATH="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$ABSOLUTE_PATH/$SOURCE"
done
ABSOLUTE_PATH="$(cd -P "$(dirname "$SOURCE")" && pwd)"
if [[ -f "${ABSOLUTE_PATH}/script-init.sh" ]]; then
  # Assume that repository cloned with script-init.sh
  # shellcheck disable=SC1091
  source "${ABSOLUTE_PATH}/script-init.sh"
  SET_COLORS
  MSG_OK "Source script found, proceeding..."
else
  if test -d "$WORKDIR"; then
    curl -fsSL "$SRC_INIT_URL" -o "${SRC_INIT}/script-init.sh"
    command chmod g-rwX "${SRC_INIT}/script-init.sh"
    if test -f "${SRC_INIT}/script-init.sh"; then
      source "${SRC_INIT}/script-init.sh"
      SET_COLORS
      MSG_OK "Successfully initialized"
    else
      echo "Failed to initialize"
      exit 1
    fi
  fi
fi

SHOW_MENU() {
  while true; do
    clear
    SET_COLORS
    echo -ne "
$TPGREEN ❮ ZI ❯ Source$TPRESET v$REPO_TAG
$TPDIM# ============================================ # $TPRESET
  $(CECHO '-green' '1)') Just install ❮ ZI ❯
  $(CECHO '-green' '2)') Build zshrc config.
  $(CECHO '-green' '3)') Run install and build zshrc config.
  $(CECHO '-line')
  $(CECHO '-red' 'q)') Exit
$TPDIM# =========================================== # $TPRESET
"
    read -rp "$TPCYAN Please select an option:$TPRESET " GET_OPTION
    if { [[ "${GET_OPTION}" =~ ^[A-Za-z0-9]+$ ]] || [[ "${GET_OPTION}" -gt 0 ]]; }; then
      case "${GET_OPTION}" in
      1)
        clear
        TITLE "Install ❮ ZI ❯ (without zshrc)"
        bash "$SRC_INSTALL"
        ;;
      2)
        clear
        NOTIFY "CHOICE 2"
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
        sleep 3
        MSG_INFO "To force quit press [CTRL+C]"
        sleep 3
        ;;
      esac
    else
      clear && MSG_ERR "Input not recognized, please open an issue on GitHub if the issue persists"
      sleep 3
      MSG_INFO "To force quit press [CTRL+C]"
      sleep 3
    fi
  done
}
MAIN() {
  SHOW_MENU "${@}"
  exit 0
}

while true; do
  MAIN "${@}"
done
