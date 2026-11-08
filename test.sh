#!/bin/sh
set -eu
cd "$(dirname "$0")"
export MYVIMRC="$PWD/init.lua"
exec nvim --headless -u "$MYVIMRC" -i NONE -l tests/config_spec.lua
