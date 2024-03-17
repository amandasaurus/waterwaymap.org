#!/bin/sh
ROOT=$(realpath "$(dirname "$0")")
cd "$ROOT" || exit 1

systemctl is-active --user -q osm-waterwaymap.timer && exit 0

systemd-run --collect --user --unit osm-waterwaymap --on-calendar="23:00" "$ROOT/make-planet.sh"

