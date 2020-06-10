create_command() {
  echo "$2" > "$COMMON_TMP_BIN/$1"
  chmod +x "$COMMON_TMP_BIN/$1"
}