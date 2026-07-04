#!/usr/bin/env bash
set -e
cd ~/.config/nvim
git fetch origin
git checkout main
git reset --hard origin/main
