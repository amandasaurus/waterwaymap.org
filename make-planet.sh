#!/bin/bash
set -o errexit -o nounset
cd "$(dirname "$0")"

if [ "${1:-}" = "-v" ]; then
	set -x
fi

source functions.sh

./dl_updates_from_osm.sh

LAST_TIMESTAMP=$(osmium fileinfo -g header.option.timestamp planet-waterway.osm.pbf)
if [ -z "$LAST_TIMESTAMP" ] ; then
	echo "Detecting the latest OSM object…"
	LAST_TIMESTAMP=$(osmium fileinfo --no-progress -e -g data.timestamp.last  planet-waterway.osm.pbf)
fi

# Now do processing

if [ -z "$(jq <docs/data/tilesets.json .tilesets)" ] ; then
	echo "./docs/data/tilesets.json is empty somehow, so add a base"
	jo tilesets=[] > ./docs/data/tilesets.json
fi

# Tiles
SECONDS=0
make planet-waterway-boatable.geojsons planet-waterway-canoeable.geojsons planet-waterway-name-group-name.geojsons planet-waterway-water.geojsons planet-waterway-nonartifical.geojsons planet-waterway-rivers-etc.geojsons
echo "Took $(units ${SECONDS}sec time) (${SECONDS}sec) to generate all geojsons files"
SECONDS=0
make planet-waterway-boatable.pmtiles planet-waterway-canoeable.pmtiles planet-waterway-name-group-name.pmtiles planet-waterway-water.pmtiles planet-waterway-nonartifical.pmtiles planet-waterway-rivers-etc.pmtiles
echo "Took $(units ${SECONDS}sec time) (${SECONDS}sec) to convert all geojsons to pmtiles"

SECONDS=0
rm -fv tmp.planet-loops.geojson
make planet-loops.pmtiles planet-loops.geojsons planet-ends.pmtiles planet-ends.geojsons planet-ends.geojsons.gz
zstd --quiet --force -z -k -e -19 ./docs/data/waterwaymap.org_loops_stats.csv -o waterwaymap.org_loops_stats.csv.zst
echo "Took $(units ${SECONDS}sec time) (${SECONDS}sec) to calculate loops & ends"

echo "All data files generated"

mv ./*pmtiles ./docs/data/ || true
mv ./planet-loops.geojsons ./docs/data/
mv ./planet-ends.geojsons.gz ./docs/data/
mv ./*zst* ./docs/data/ 2>/dev/null || true

jq <./docs/data/tilesets.json '.tilesets[0].key = "planet-waterway-water"|.tilesets[0].text = "Waterways (inc. canals etc)"' | sponge ./docs/data/tilesets.json
jq <./docs/data/tilesets.json '.tilesets[1].key = "planet-waterway-nonartifical"|.tilesets[1].text = "Natural Waterways (excl. canals etc)"' | sponge ./docs/data/tilesets.json
jq <./docs/data/tilesets.json '.tilesets[2].key = "planet-waterway-boatable"|.tilesets[2].text = "Navigable by boat (<code>boat=yes,motor</code>)"' | sponge ./docs/data/tilesets.json
jq <./docs/data/tilesets.json '.tilesets[3].key = "planet-waterway-canoeable"|.tilesets[3].text = "Navigable by canoe (<code>canoe=yes</code>)"' | sponge ./docs/data/tilesets.json
jq <./docs/data/tilesets.json '.tilesets[4].key = "planet-waterway-name-group-name"|.tilesets[4].text = "Named Waterways"' | sponge ./docs/data/tilesets.json
jq <./docs/data/tilesets.json '.tilesets[5].key = "planet-waterway-rivers-etc"|.tilesets[5].text = "Rivers (etc.)"' | sponge ./docs/data/tilesets.json
jq <./docs/data/tilesets.json '.selected_tileset = "planet-waterway-water"' | sponge ./docs/data/tilesets.json

jq <./docs/data/tilesets.json ".data_timestamp = \"${LAST_TIMESTAMP}\"" | sponge ./docs/data/tilesets.json

./rss_update.sh ./docs/data/data_updates.xml "WaterwayMap.org Data update" "WaterwayMap.org has been updated with OSM data up until $LAST_TIMESTAMP"
echo "RSS feed updated, last data timestamp is $LAST_TIMESTAMP"

echo "Current size of the data is: $(du -hsc ./docs/data/ | head -1 | cut -f1)"

echo "All data & metadata finishing. Beginning upload..."
rclone sync --transfers 1 --order-by size,descending --bwlimit 2M ./docs/data/ cloudflare:data-waterwaymap-org/
echo "Upload finished"

wait

exit 0
