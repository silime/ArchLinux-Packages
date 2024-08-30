#!/usr/bin/bash
interface="${1}"
timeout="${2}"
[ -z "${interface}" ]&&exit 2
[ -z "${timeout}" ]&&timeout=10
[[ "${timeout}" -lt 0 ]]&&exit 2
int=0
timeout=$((timeout*5))
while ! [ -h "/sys/class/net/${interface}" ]; do
  int=$((int+1))
  [[ "${int}" -gt "${timeout}" ]]&&exit 1
  sleep 0.2
done
true
