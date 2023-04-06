#!/bin/bash
set -o errexit -o nounset
cd "$(dirname "$0")"

PREFIX="planet"
TMP="${PREFIX}.$(date -u +%F.%s)"
if [ planet-latest.osm.pbf -nt planet-waterway.osm.pbf ] ; then
	osmium tags-filter --remove-tags --overwrite planet-latest.osm.pbf -o planet-waterway.osm.pbf waterway
fi

FILE_TIMESTAMP=$(osmium fileinfo --get header.option.timestamp planet-waterway.osm.pbf)

function process() {
	INPUT=$1
	PREFIX=$2
	LUMP_ARGS=$3
	TMP="${PREFIX}.$(date -u +%F.%s)"

	osm-lump-ways -i "$INPUT" -o "${TMP}.geojson" $LUMP_ARGS --min-length-m 100 --timeout-dist-to-longer-s 0 --no-incl-wayids --save-as-linestrings
	echo "GeoJSON created successfully."
	echo "Starting tippecanoe..."
	tippecanoe -n "OSM River Topologies" -N "Generated on $(date -I) from OSM data from $FILE_TIMESTAMP with $(osm-lump-ways --version) and argument $LUMP_ARGS"  -A "© OpenStreetMap. Open Data under ODbL. https://osm.org/copyright" -S 10 -y length_m -y root_wayid -l waterway --drop-smallest-as-needed --order-descending-by=length_m -o "${TMP}.pmtiles" "${TMP}.geojson"
	mv "${TMP}.geojson" "./docs/data/${PREFIX}.geojson"
	mv "${TMP}.pmtiles" "./docs/tiles/${PREFIX}.pmtiles"
	echo "GeoJSON & PMTiles created successfully."
	gzip -f -9 "./docs/data/${PREFIX}.geojson" &
}

process ~/osm-data/planet-waterway.osm.pbf planet-waterway-river "-f waterway=river"
process ~/osm-data/planet-waterway.osm.pbf planet-waterway-name-no-group "-f waterway -f name"
process ~/osm-data/planet-waterway.osm.pbf planet-waterway-name-group-name "-f waterway -f name -g name"

wait
exit 0
