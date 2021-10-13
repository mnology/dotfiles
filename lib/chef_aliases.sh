#!/bin/bash -
#===============================================================================
#
#          FILE: chef_aliases.sh
#
#         USAGE: ./chef_aliases.sh
#
#   DESCRIPTION:
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (),
#  ORGANIZATION:
#       CREATED: 07/16/2015 14:47
#      REVISION:  ---
#===============================================================================
eval "$(chef shell-init zsh)"

kssh() {
  local env=${1}
  local role=${2}

  knife ssh \
    -a ipaddress "role:${role} AND environment:${env}_env" \
    tmux --tmux-split
}
