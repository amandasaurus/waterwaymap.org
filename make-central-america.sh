#!/bin/bash
set -o errexit -o nounset
cd "$(dirname "$0")"

source functions.sh

pyosmium-up-to-date -vv central-america-latest.osm.pbf || true
if [ central-america-latest.osm.pbf -nt central-america-waterway.osm.pbf ] ; then
	echo "Data updates, rerunning osmium tags-filter"
	osmium tags-filter --remove-tags --overwrite central-america-latest.osm.pbf -o central-america-waterway.osm.pbf waterway
fi

process central-america-waterway.osm.pbf central-america-waterway "-f waterway"
process central-america-waterway.osm.pbf central-america-waterway-river "-f waterway=river"
process central-america-waterway.osm.pbf central-america-waterway-name-no-group "-f waterway -f name"
process central-america-waterway.osm.pbf central-america-waterway-name-group-name "-f waterway -f name -g name"

wait

for F in central-america-waterway central-america-waterway-river central-america-waterway-name-no-group central-america-waterway-name-group-name ; do
	echo $F
	rclone copyto ./docs/tiles/${F}.pmtiles cloudflare:pmtiles0/2023-04-01/${F}.pmtiles  --progress
	rclone copyto ./docs/data/${F}-metadata.json cloudflare:pmtiles0/2023-04-01/${F}-metadata.json  --progress
	echo ; echo
done

exit 0
