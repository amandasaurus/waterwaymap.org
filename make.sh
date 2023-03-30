#!/bin/bash
set -o errexit -o nounset
cd "$(dirname "$0")"

PREFIX="irl-br-waterway"
TMP="${PREFIX}.$(date -u +%F.%s)"
pyosmium-up-to-date -vv ~/osm-data/britain-and-ireland-latest.osm.pbf
cargo run --release -- -i ~/osm-data/britain-and-ireland-latest.osm.pbf -o "${TMP}.geojson" -f waterway=river,stream,ditch --min-length-m 100 --timeout-dist-to-longer-s 0 --no-incl-wayids
tippecanoe -y length_m -y root_wayid -l waterway --drop-smallest-as-needed --order-descending-by=length_m -o "${TMP}.pmtiles" "${TMP}.geojson"

mv "${TMP}.geojson" ./public_html/data/${PREFIX}.geojson
gzip -9 ./public_html/data/${PREFIX}.geojson
mv "${TMP}.pmtiles" ./public_html/tiles/${PREFIX}.pmtiles
