#! /bin/sh
cd "$(dirname "$0")" || exit 1

scp -C -q -Fssh_config ./install.sh wwm-render1:
ssh -Fssh_config wwm-render1 ./install.sh
scp -C -q -Fssh_config ~/.terminfo/x/xterm-kitty wwm-render1:.terminfo/x/
