#!/bin/bash

function process() {
	INPUT=$1
	PREFIX=$2
	LUMP_ARGS=$3
	FILE_TIMESTAMP=$(osmium fileinfo --get header.option.timestamp "$INPUT")
	TMP="${PREFIX}.$(date -u +%F.%s)"

	osm-lump-ways -i "$INPUT" -o "${TMP}.geojson" $LUMP_ARGS --min-length-m 100 --save-as-linestrings
	echo "GeoJSON created successfully."
	echo "Starting tippecanoe..."
	tippecanoe \
		-n "OSM River Topologies" \
		-N "Generated on $(date -I) from OSM data from $FILE_TIMESTAMP with $(osm-lump-ways --version) and argument $LUMP_ARGS" \
		-A "© OpenStreetMap. Open Data under ODbL. https://osm.org/copyright" \
		-S 10 --single-precision \
		--simplify-only-low-zooms \
		-y length_m -y root_wayid \
		-l waterway \
		--gamma 2 \
		--coalesce-smallest-as-needed \
		--drop-smallest-as-needed --order-by=length_m \
		-o "${TMP}.pmtiles" "${TMP}.geojson"
	mv "${TMP}.geojson" "./docs/data/${PREFIX}.geojson"
	mv "${TMP}.pmtiles" "./docs/tiles/${PREFIX}.pmtiles"
	echo "GeoJSON & PMTiles created successfully."
	gzip -f -9 "./docs/data/${PREFIX}.geojson" &
}
