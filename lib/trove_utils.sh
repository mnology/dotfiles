#!/bin/bash - 

set -o nounset                              # Treat unset variables as an error

trove () {
  ssh trove "${@}"
}
