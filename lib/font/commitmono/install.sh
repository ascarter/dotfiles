#!/bin/sh

curl -sSL -O ??
mkdir -p ~/.local/share/fonts
unzip -d ~/.local/share/fonts ~/Downloads/CommitMonoV143.zip -x "*.txt" "*.json"
fc-cache -f -v
