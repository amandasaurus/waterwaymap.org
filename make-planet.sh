#!/bin/bash
set -o errexit -o nounset
cd "$(dirname "$0")"

source functions.sh

PREFIX="planet"
TMP="tmp.${PREFIX}.$(date -u +%F.%s)"
if [ planet-latest.osm.pbf -nt planet-waterway.osm.pbf ] ; then
	echo "Data updates, rerunning osmium tags-filter"
	TMP=$(mktemp -p . "tmp.planet.XXXXXX.osm.pbf")
	osmium tags-filter --remove-tags --overwrite planet-latest.osm.pbf -o "$TMP" waterway
	mv "$TMP" planet-waterway.osm.pbf
fi

process ~/osm-data/planet-waterway.osm.pbf planet-waterway-river "-f waterway=river"
rclone copyto ./docs/tiles/planet-waterway-river.pmtiles cloudflare:pmtiles0/2023-04-01/planet-waterway-river.pmtiles  --progress

process ~/osm-data/planet-waterway.osm.pbf planet-waterway-name-no-group "-f waterway -f name"
rclone copyto ./docs/tiles/planet-waterway-name-no-group.pmtiles cloudflare:pmtiles0/2023-04-01/planet-waterway-name-no-group.pmtiles  --progress

process ~/osm-data/planet-waterway.osm.pbf planet-waterway-name-group-name "-f waterway -f name -g name"
rclone copyto ./docs/tiles/planet-waterway-name-group-name.pmtiles cloudflare:pmtiles0/2023-04-01/planet-waterway-name-group-name.pmtiles  --progress

wait

exit 0
