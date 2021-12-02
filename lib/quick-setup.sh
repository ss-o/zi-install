#!/usr/bin/env bash
[[ -n "$ENABLE_DEBUG_MODE" ]] && set -x
SRC_INSTALL_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/exec/install.sh"
SRC_INIT_URL="https://raw.githubusercontent.com/ss-o/zi-source/main/lib/script-init.sh"
WORKDIR="(mktemp -d -t zi-work.XXXXXXXXXX)"
SRC_INSTALL="${WORKDIR}/(mktemp -t zi-install.XXXXXXXXXX)"
SRC_INIT="${WORKDIR}/$(mktemp -t zi-init.XXXXXXXXXX)"
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  ABSOLUTE_PATH="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$ABSOLUTE_PATH/$SOURCE"
done
ABSOLUTE_PATH="$(cd -P "$(dirname "$SOURCE")" && pwd)"
if [[ ! -f "${ABSOLUTE_PATH}/script-init.sh" ]]; then
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$SRC_INIT_URL" -o "$SRC_INIT"
    curl -fsSL "$SRC_INSTALL_URL" -o "$SRC_INSTALL"
  elif command -v wget >/dev/null 2>&1; then
    wget -q "$SRC_INIT_URL" -O "$SRC_INIT"
    wget -q "$SRC_INSTALL_URL" -O "$SRC_INSTALL"
  else
    echo -e "No curl or wget available. Aborting."
    echo -e "Please install curl or wget and try again."
  fi
  chmod a+x "$SRC_INIT" "$SRC_INSTALL"
  # shellcheck disable=SC1090
  source "$SRC_INIT"
  SET_COLORS
  MSG_OK "Successfully installed source script, proceeding..."
else
  # Assume that repository cloned with script-init.sh
  # shellcheck disable=SC1091
  source "${ABSOLUTE_PATH}/script-init.sh"
  SET_COLORS
  MSG_OK "Source script found, proceeding..."
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
        TITLE "Install ❮ ZI ❯ (without zshrc)"
        sleep 2
        bash "$SRC_INSTALL"
        ;;
      2)
        NOTIFY "CHOICE 2"
        sleep 3
        ;;
      3)
        MSG_INFO "CHOICE 3"
        sleep 3
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
