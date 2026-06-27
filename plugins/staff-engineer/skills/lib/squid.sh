# Shared config helpers for squid skills. Flat YAML manifest at .squid/config.yml in the
# app repo. Missing file or key → the caller's opinionated default. No yq dependency
# (flat `key: value` only — valid YAML, readable with grep/sed). Source from a skill:
#   DIR="$(cd "$(dirname "$0")" && pwd -P)"; . "$DIR/../lib/squid.sh"
SQUID_CONFIG="${SQUID_CONFIG:-.squid/config.yml}"

# squid_get <key> [default] → value (default if unset/absent)
squid_get() {
  local v=""
  [ -f "$SQUID_CONFIG" ] && v="$(grep -E "^$1:[[:space:]]" "$SQUID_CONFIG" 2>/dev/null | head -1 \
    | sed -E "s/^$1:[[:space:]]*//; s/[[:space:]]*#.*$//; s/[[:space:]]*$//")"
  [ -n "$v" ] && printf '%s\n' "$v" || printf '%s\n' "${2:-}"
}

# squid_init — create the manifest with a header if it doesn't exist yet
squid_init() {
  [ -f "$SQUID_CONFIG" ] && return 0
  mkdir -p "$(dirname "$SQUID_CONFIG")"
  printf '%s\n' "# squid manifest — skills read this. Missing key = opinionated default. Edit to deviate." > "$SQUID_CONFIG"
}

# squid_set <key> <value> — force-write (records a decision). Portable (no sed -i).
squid_set() {
  squid_init
  if grep -qE "^$1:" "$SQUID_CONFIG"; then
    local tmp; tmp="$(mktemp)"
    sed -E "s|^$1:.*|$1: $2|" "$SQUID_CONFIG" > "$tmp" && mv "$tmp" "$SQUID_CONFIG"
  else
    printf '%s: %s\n' "$1" "$2" >> "$SQUID_CONFIG"
  fi
}

# squid_default <key> <value> — seed a default only if the key is absent (never clobbers a user edit)
squid_default() {
  grep -qE "^$1:" "$SQUID_CONFIG" 2>/dev/null || squid_set "$1" "$2"
}
