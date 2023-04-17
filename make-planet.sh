#!/bin/bash
set -o errexit -o nounset
cd "$(dirname "$0")"

source functions.sh

PREFIX="planet"
TMP="${PREFIX}.$(date -u +%F.%s)"
#pyosmium-up-to-date -vv ~/osm-data/planet-latest.osm.pbf || true
if [ planet-latest.osm.pbf -nt planet-waterway.osm.pbf ] ; then
	echo "Data updates, rerunning osmium tags-filter"
	osmium tags-filter --remove-tags --overwrite planet-latest.osm.pbf -o planet-waterway.osm.pbf waterway
fi

process colombia-waterway.osm.pbf colombia-waterway "-f waterway"
process colombia-waterway.osm.pbf colombia-waterway-river "-f waterway=river"
process colombia-waterway.osm.pbf colombia-waterway-name-no-group "-f waterway -f name"
process colombia-waterway.osm.pbf colombia-waterway-name-group-name "-f waterway -f name -g name"

process ~/osm-data/planet-waterway.osm.pbf planet-waterway-river "-f waterway=river"
process ~/osm-data/planet-waterway.osm.pbf planet-waterway-name-no-group "-f waterway -f name"
process ~/osm-data/planet-waterway.osm.pbf planet-waterway-name-group-name "-f waterway -f name -g name"

wait
exit 0
