#!/usr/bin/env bash
DIR="$(cd "$(dirname "$0")" && pwd)"
open -na "Ghostty" --args -e /bin/sh -c "cd '$DIR' && exec nvim -u init.lua"
