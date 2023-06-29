#!/bin/bash

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


	osm-lump-ways -i "$INPUT" -o "${TMP}.geojson" $LUMP_ARGS $MIN_LENGTH_ARG --save-as-linestrings
	echo "GeoJSON created successfully."
	echo "Starting tippecanoe..."
	tippecanoe \
		-n "OSM River Topologies" \
		-N "Generated on $(date -I) from OSM data from $FILE_TIMESTAMP with $(osm-lump-ways --version) and argument $LUMP_ARGS" \
		-A "© OpenStreetMap. Open Data under ODbL. https://osm.org/copyright" \
		--single-precision \
		--simplify-only-low-zooms --extend-zooms-if-still-dropping \
		--maximum-tile-bytes="$(units -t 1MiB bytes)" \
		--maximum-tile-features=500000 \
		-y length_m -y root_wayid_120 \
		-l waterway \
		--gamma 2 \
		--coalesce-smallest-as-needed \
		--order-descending-by=length_m \
		-o "${TMP}.pmtiles" "${TMP}.geojson"
	jo timestamp="$FILE_TIMESTAMP" > "./docs/data/${PREFIX}-metadata.json"
	mv "${TMP}.geojson" "./docs/data/${PREFIX}.geojson"
	mv "${TMP}.pmtiles" "./docs/tiles/${PREFIX}.pmtiles"
	echo "GeoJSON & PMTiles created successfully."
	gzip -f -9 "./docs/data/${PREFIX}.geojson" &
}
