#!/bin/bash
set -u

for i in $(seq 1 20); do
  for s in /run/nut/*ups*; do
    [ -S "$s" ] || continue
    chgrp nut "$s" 2>/dev/null || true
    chmod 660 "$s" 2>/dev/null || true
  done
  sleep 2
done

exit 0
