#!/usr/bin/env bash

# DO NOT use set -e
set -u

STATUS="${1:-UNKNOWN}"
MESSAGE="${2:-No message provided}"

HOSTNAME="$(hostname)"
TIMESTAMP="$(date -Is)"

NTFY_URL="${NTFY_URL}"

TITLE="Immich Backup – ${STATUS}"

PRIORITY="3"
TAGS="floppy_disk"

if [[ "$STATUS" == "FAILED" ]]; then
  PRIORITY="5"
  TAGS="rotating_light"
fi

BODY=$(cat <<EOF
Host: ${HOSTNAME}
Time: ${TIMESTAMP}
Status: ${STATUS}

${MESSAGE}
EOF
)

curl -sS -X POST "$NTFY_URL" \
  -H "Title: ${TITLE}" \
  -H "Priority: ${PRIORITY}" \
  -H "Tags: ${TAGS}" \
  -d "$BODY" \
  >/dev/null 2>&1 || true

exit 0
