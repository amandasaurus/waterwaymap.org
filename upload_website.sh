#!/bin/sh
cd "$(dirname "$0")" || exit 1
 
cd docs/ || exit 1
echo "put -r ." | sftp hetzner-webhosting:public_html
