#!/usr/bin/env bash
set -e

if [ -d "./.test/bats" ]; then
  echo "Deleting folder ./.test/bats"
  rm -rf "./.test/bats/"
fi
