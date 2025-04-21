#!/bin/sh
cd "$(dirname "$0")" || exit 1
 
echo "Current size of the rivers_html.db is: $(du -hsc ./rivers_html.db | head -1 | cut -f1)"
echo "rm tmp.site.sqlitesite" | sftp hetzner-webhosting:public_html || true
scp ./rivers_html.db hetzner-webhosting:public_html/tmp.site.sqlitesite
echo "rename tmp.site.sqlitesite site.sqlitesite" | sftp hetzner-webhosting:public_html
