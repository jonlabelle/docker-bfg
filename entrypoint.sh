#!/bin/sh

# BFG wrapper script to handle default help when no arguments provided

if [ "$#" -eq 0 ]; then
  exec java -jar /usr/local/bin/bfg.jar --help
else
  exec java -jar /usr/local/bin/bfg.jar "$@"
fi
