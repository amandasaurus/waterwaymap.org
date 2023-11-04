#!/bin/bash -x
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

make planet-waterway-boatable.pmtiles planet-waterway-all.pmtiles planet-waterway-river-stream.pmtiles planet-waterway-excl-non-waterway.pmtiles planet-waterway-name-group-name.pmtiles planet-waterway-or-naturalwater.pmtiles
make planet-waterway-river-stream.gpkg.zst planet-waterway-river-stream.gpkg.zst.torrent

echo "All data files generated"

mv ./*pmtiles ./docs/data/ || true
mv ./*gpkg* ./docs/data/ || true
ln -s ./docs/data/*.pmtiles ./ || true

jq <./docs/data/tilesets.json '.tilesets[0].key = "planet-waterway-all"|.tilesets[0].text = "All Waterways (<code>waterway</code>)"' | sponge ./docs/data/tilesets.json
jq <./docs/data/tilesets.json '.tilesets[1].key = "planet-waterway-boatable"|.tilesets[1].text = "Navigable by boat (<code>waterway</code>,<code>boat=yes,motor</code>)"' | sponge ./docs/data/tilesets.json
jq <./docs/data/tilesets.json '.tilesets[2].key = "planet-waterway-river-stream"|.tilesets[2].text = "River or Stream (<code>waterway=river,stream</code>)"' | sponge ./docs/data/tilesets.json
jq <./docs/data/tilesets.json '.tilesets[3].key = "planet-waterway-excl-non-waterway"|.tilesets[3].text = "<code>waterway</code> w/o some “dam”-like values"' | sponge ./docs/data/tilesets.json
jq <./docs/data/tilesets.json '.tilesets[4].key = "planet-waterway-name-group-name"|.tilesets[4].text = "Named Waterways (<code>waterway</code> &amp; <code>name*</code> tags, grouped by <code>name</code> tag)"' | sponge ./docs/data/tilesets.json
jq <./docs/data/tilesets.json '.tilesets[5].key = "planet-waterway-or-naturalwater"|.tilesets[5].text = "Waterways or Water (<code>waterway</code> &amp; <code>natural=water</code>)"' | sponge ./docs/data/tilesets.json
jq <./docs/data/tilesets.json '.selected_tileset = "planet-waterway-all"' | sponge ./docs/data/tilesets.json

jq <./docs/data/tilesets.json ".data_timestamp = \"${LAST_TIMESTAMP}\"" | sponge ./docs/data/tilesets.json

./rss_update.sh ./docs/data/data_updates.xml "OSM River Basins Data update" "The OSM River Basins Map has been updated with OSM data up until $LAST_TIMESTAMP"
echo "RSS feed updated, last data timestamp is $LAST_TIMESTAMP"

echo "All data & metadata finishing. Beginning upload..."
rclone sync --bwlimit 2M ./docs/data/ cloudflare:pmtiles0/2023-04-01/
echo "Upload finished"

wait

exit 0
