#!/usr/bin/bash
address="${1}"
timeout="${2}"
[ -z "${address}" ]&&exit 2
[ -z "${timeout}" ]&&timeout=10
[[ "${timeout}" -lt 0 ]]&&exit 2
int=0
timeout=$((timeout*5))
while ! ip address show | grep -w "${address}" &>/dev/null; do
  int=$((int+1))
  [[ "${int}" -gt "${timeout}" ]]&&exit 1
  sleep 0.2
done
true
