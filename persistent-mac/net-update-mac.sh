#!/bin/bash
MAC="$(bash /etc/systemd/scripts/generate-mac.sh "$@")"
ip link set dev "$@" down &> /dev/null || true
ip link set dev "$@" address "$MAC"
