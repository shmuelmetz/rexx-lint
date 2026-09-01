#!/bin/sh
# Source this file (". ./setenv.sh") to add rexx-lint's bin, lib, and
# checks directories to PATH.
here="$(cd "$(dirname "$0")" && pwd)"
echo "Adding rexx-lint's bin, lib, and checks directories to PATH..."
export PATH="$here/bin:$here/lib:$here/checks:$PATH"
