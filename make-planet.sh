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

make all -j 4

jq <./docs/data/tilesets.json '.tilesets[0].key = "planet-waterway-river"|.tilesets[0].text = "only <code>waterway=river</code>"' | sponge ./docs/data/tilesets.json
jq <./docs/data/tilesets.json '.selected_tileset = "planet-waterway-river"' | sponge ./docs/data/tilesets.json
jq <./docs/data/tilesets.json '.tilesets[1].key = "planet-waterway-name-no-group"|.tilesets[1].text = "with <code>waterway</code> &amp; <code>name*</code>. Purely topological grouping"' | sponge ./docs/data/tilesets.json
jq <./docs/data/tilesets.json '.tilesets[2].key = "planet-waterway-name-group-name"|.tilesets[2].text = "with <code>waterway</code> &amp; <code>name*</code> tags. grouped by topology &amp; <code>wikidata</code> then <code>name</code>"' | sponge ./docs/data/tilesets.json
jq <./docs/data/tilesets.json '.tilesets[3].key = "planet-waterway-noname"|.tilesets[3].text = "Unnamed <code>waterway</code>"' | sponge ./docs/data/tilesets.json
jq <./docs/data/tilesets.json '.tilesets[4].key = "planet-waterway-river-canal"|.tilesets[4].text = "<code>waterway=river</code> or <code>=canal</code>"' | sponge ./docs/data/tilesets.json
jq <./docs/data/tilesets.json '.tilesets[5].key = "planet-waterway-boatable"|.tilesets[5].text = "Navigable by boat (<code>waterway</code>,<code>boat=yes,motor</code>)"' | sponge ./docs/data/tilesets.json
jq <./docs/data/tilesets.json '.tilesets[6].key = "planet-waterway-all"|.tilesets[6].text = "All <code>waterway</code>"' | sponge ./docs/data/tilesets.json
jq <./docs/data/tilesets.json '.tilesets[7].key = "planet-waterway-flowing"|.tilesets[7].text = "<code>waterway</code> w/o some “dam”-like values"' | sponge ./docs/data/tilesets.json


jq <./docs/data/tilesets.json ".data_timestamp = \"${LAST_TIMESTAMP}\"" | sponge ./docs/data/tilesets.json

./rss_update.sh ./docs/data/data_updates.xml "OSM River Basins Data update" "The OSM River Basins Map has been updated with OSM data up until $LAST_TIMESTAMP"

rclone sync --bwlimit 2M ./docs/data/ cloudflare:pmtiles0/2023-04-01/  --progress

wait

exit 0
