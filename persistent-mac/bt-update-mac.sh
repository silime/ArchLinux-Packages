#!/bin/bash
MAC="$(bash /etc/systemd/scripts/generate-mac.sh bluetooth)"
for i in {0..5}; do
  sleep "$i"
  if bluetoothctl mgmt.public-addr "$MAC"; then
    break
  fi
done
exit "$?"
