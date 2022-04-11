#!/usr/bin/env bash
alias ls='ls --color'
alias uzbl='UZBL_DOWNLOAD_DIR=~/Downloads uzbl-tabbed'

wsr() {
  local host=$1
  local if=$2
  local cfilt=$3

  local no_ssh="not port 22"
  local filter=

  if [[ -z "$cfilt" ]]; then
    filter=$no_ssh
  else
    filter="${no_ssh} and ${cfilt}"
  fi

  R_DUMP=sudo tcpdump -U -s 0 -i "${if}" -w - "'${filter}'"
  ssh "${host}" "${R_DUMP}" | wireshark -k -i -
}
