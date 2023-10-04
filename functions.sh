#!/bin/bash

. "$HOME/.cargo/env"

function process() {
	INPUT=$1
	PREFIX=$2
	LUMP_ARGS=$3
	FILE_TIMESTAMP=$(osmium fileinfo --get header.option.timestamp "$INPUT")
	TMP="tmp.${PREFIX}.$(date -u +%F.%s)"

	if [[ $LUMP_ARGS =~ "min-length-m" ]] ; then
		MIN_LENGTH_ARG=""
	else
		MIN_LENGTH_ARG="--min-length-m 100"
	fi


	osm-lump-ways -v -i "$INPUT" -o "${TMP}.geojson" $LUMP_ARGS $MIN_LENGTH_ARG --save-as-linestrings
	echo "GeoJSON created successfully. uncompressed size: $(ls -lh "${TMP}.geojson" | cut -d" " -f5)"
	echo "Starting tippecanoe..."
	timeout 5h tippecanoe \
		-n "OSM River Topologies" \
		-N "Generated on $(date -I) from OSM data from ${FILE_TIMESTAMP:-OSMIUM_HEADER_MISSING} with $(osm-lump-ways --version) and argument $LUMP_ARGS" \
		-A "© OpenStreetMap. Open Data under ODbL. https://osm.org/copyright" \
		--single-precision \
		--extend-zooms-if-still-dropping \
		--simplification=8 \
		--drop-densest-as-needed \
		-y length_m -y root_wayid_120 \
		--no-feature-limit \
		-l waterway \
		--gamma 2 \
		--order-descending-by=length_m \
		--no-progress-indicator \
		-o "${TMP}.pmtiles" "${TMP}.geojson"
	 	#--maximum-tile-bytes="$(units -t 5MiB bytes)" \
	mv "${TMP}.geojson" "./${PREFIX}.geojson"
	gzip -f -9 "./${PREFIX}.geojson" &
	echo "PMTiles created successfully. size: $(ls -lh "${TMP}.pmtiles" | cut -d" " -f5)"
	mv "${TMP}.pmtiles" "./docs/data/${PREFIX}.pmtiles"
	echo "GeoJSON & PMTiles created successfully."
}
