#!/bin/bash
set -o errexit -o nounset
cd "$(dirname "$0")"

source functions.sh

pyosmium-up-to-date -vv south-america-latest.osm.pbf || true
if [ south-america-latest.osm.pbf -nt south-america-waterway.osm.pbf ] ; then
	echo "Data updates, rerunning osmium tags-filter"
	osmium tags-filter --remove-tags --overwrite south-america-latest.osm.pbf -o south-america-waterway.osm.pbf waterway
fi

process south-america-waterway.osm.pbf south-america-waterway "-f waterway"
process south-america-waterway.osm.pbf south-america-waterway-river "-f waterway=river"
process south-america-waterway.osm.pbf south-america-waterway-name-no-group "-f waterway -f name"
process south-america-waterway.osm.pbf south-america-waterway-name-group-name "-f waterway -f name -g name"

wait

for F in south-america-waterway south-america-waterway-river south-america-waterway-name-no-group south-america-waterway-name-group-name ; do
	echo $F
	rclone copyto ./docs/tiles/${F}.pmtiles cloudflare:pmtiles0/2023-04-01/${F}.pmtiles  --progress
	rclone copyto ./docs/data/${F}-metadata.json cloudflare:pmtiles0/2023-04-01/${F}-metadata.json  --progress
	echo ; echo
done

exit 0
