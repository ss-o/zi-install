WORKDIR="(mktemp -d)"
SOURCE="${BASH_SOURCE[0]}"
GET_SOURCE_FILE() {
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
}
