#!/usr/bin/env bash
set -euo pipefail

AUTH="$(/usr/bin/x11vnc -env FD_XDM=1 -findauth :0 2>/dev/null | sed -n 's/^XAUTHORITY=//p' | tail -n 1)"
if [ -z "${AUTH}" ]; then
  AUTH="$(ps -ef | sed -n 's/.*Xorg .* -auth \([^ ]*\).*/\1/p' | head -n 1)"
fi

if [ -z "${AUTH}" ]; then
  echo "Could not determine XAUTHORITY for :0" >&2
  exit 1
fi

exec /usr/bin/x11vnc \
  -display :0 \
  -auth "${AUTH}" \
  -forever \
  -shared \
  -xkb \
  -noxrecord \
  -noxfixes \
  -noxdamage \
  -rfbauth /home/nutserver/.vnc/passwd \
  -rfbport 5900
