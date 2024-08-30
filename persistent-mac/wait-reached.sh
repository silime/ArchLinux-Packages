#!/usr/bin/bash
address="${1}"
stimeout="${2}"
[ -z "${address}" ]&&exit 2
[ -z "${stimeout}" ]&&stimeout=10
[[ "${stimeout}" -lt 0 ]]&&exit 2
int=0
while ! timeout 1s ping -c 1 -W 1 "${address}" &>/dev/null; do
int=$((int+1))
  [[ "${int}" -gt "${stimeout}" ]]&&exit 1
  sleep 0.5
done
true
