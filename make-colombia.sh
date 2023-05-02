#!/bin/bash
set -o errexit -o nounset
cd "$(dirname "$0")"

source functions.sh

pyosmium-up-to-date -vv colombia-latest.osm.pbf || true
if [ colombia-latest.osm.pbf -nt colombia-waterway.osm.pbf ] ; then
	echo "Data updates, rerunning osmium tags-filter"
	osmium tags-filter --remove-tags --overwrite colombia-latest.osm.pbf -o colombia-waterway.osm.pbf waterway
fi

process colombia-waterway.osm.pbf colombia-waterway "-f waterway"
process colombia-waterway.osm.pbf colombia-waterway-river "-f waterway=river"
process colombia-waterway.osm.pbf colombia-waterway-name-no-group "-f waterway -f name"
process colombia-waterway.osm.pbf colombia-waterway-name-group-name "-f waterway -f name -g name"

wait

for F in colombia-waterway colombia-waterway-river colombia-waterway-name-no-group colombia-waterway-name-group-name ; do
	echo $F
	rclone copyto ./docs/tiles/${F}.pmtiles cloudflare:pmtiles0/2023-04-01/${F}.pmtiles  --progress
	rclone copyto ./docs/data/${F}-metadata.json cloudflare:pmtiles0/2023-04-01/${F}-metadata.json  --progress
	echo ; echo
done

exit 0
