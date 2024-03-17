#!/bin/sh
cd "$(dirname "$0")" || exit 1
exec ssh -Fssh_config wwm-render1 "$@"
