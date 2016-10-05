#!/usr/bin/env bash - 

set -o nounset                              # Treat unset variables as an error

brew list \
  | while read l; do echo -n "$l "; echo $(brew deps $l); done \
  | awk 'NF == 1 {print $1, $1} NF > 1 {for (i=1;i<=NF;i++) print $1, $i}' \
  | tsort \
  | tail -r \
  | while read l; do echo -n "$l "; brew reinstall $l; done
