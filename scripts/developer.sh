#!/bin/sh

# Convenience script for common developer tools.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)

run_tool() {
  tool_script="$1"
  if [ -f "$SCRIPT_DIR/tools/${tool_script}.sh" ]; then
    echo "Running tools/${tool_script}"
    sh "$SCRIPT_DIR/tools/${tool_script}.sh"
  else
    echo "Skipping tools/${tool_script}; script not found"
  fi
}

run_tool gh
run_tool vscode
run_tool zed
