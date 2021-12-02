#!/usr/bin/env bash
[[ -n "$ENABLE_DEBUG_MODE" ]] && set -x
source "script-init.sh"

SHOW_MENU() {
  while true; do
    clear
    SET_COLORS
    echo -ne "
$TPGREEN ❮ ZI ❯ Source$TPRESET v$REPO_TAG
$TPDIM# ====================== # $TPRESET
  $(CECHO '-green' '1)') Test 1
  $(CECHO '-green' '2)') Test 2
  $(CECHO '-green' '3)') Test 3
  $(CECHO '-line')
  $(CECHO '-red' 'q)') Exit
$TPDIM# ====================== # $TPRESET
"
    read -rp "$TPCYAN Please select an option:$TPRESET " GET_OPTION
    if { [[ "${GET_OPTION}" =~ ^[A-Za-z0-9]+$ ]] || [[ "${GET_OPTION}" -gt 0 ]]; }; then
      case "${GET_OPTION}" in
      1)
        TITLE "CHOICE 1"
        sleep 3
        ;;
      2)
        NOTIFY "CHOICE 2"
        sleep 3
        ;;
      3)
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
