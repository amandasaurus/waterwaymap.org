#!/bin/bash
set -o errexit -o nounset
cd "$(dirname "$0")"

if [ "${1:-}" = "-v" ]; then
	set -x
fi

source functions.sh

if [ "$(osm-lump-ways --version)" != "osm-lump-ways 3.3.0" ] ; then
  echo "Wrong version of osm-lump-ways installed: $(osm-lump-ways --version)"
  exit 1
fi

./dl_updates_from_osm.sh

LAST_TIMESTAMP=$(osmium fileinfo -g header.option.timestamp planet-waterway.osm.pbf)
if [ -z "$LAST_TIMESTAMP" ] ; then
	echo "Detecting the latest OSM object…"
	LAST_TIMESTAMP=$(osmium fileinfo --no-progress -e -g data.timestamp.last  planet-waterway.osm.pbf)
fi

# Now do processing

if [ ! -s ./upload_to_cloudflare/tilesets.json ] || [ -z "$(jq <./upload_to_cloudflare/tilesets.json .tilesets)" ] ; then
	echo "./upload_to_cloudflare/tilesets.json is empty somehow, so add a base"
	jo tilesets=[] > ./upload_to_cloudflare/tilesets.json
fi
jq <./upload_to_cloudflare/tilesets.json ".data_timestamp = \"${LAST_TIMESTAMP}\"" | sponge ./upload_to_cloudflare/tilesets.json

# Tiles
SECONDS=0
make geojson_files
echo "Took $(units ${SECONDS}sec time) (${SECONDS}sec) to generate all geojsons files"
SECONDS=0
make -j2 output_files
echo "Took $(units ${SECONDS}sec time) (${SECONDS}sec) to convert all geojsons to pmtiles"

zstd --quiet --force -z -k -e -19 ./upload_to_cloudflare/waterwaymap.org_loops_stats.csv -o waterwaymap.org_loops_stats.csv.zst
zstd --quiet --force -z -k -e -19 ./waterwaymap.org_ends_stats.csv -o ./waterwaymap.org_ends_stats.csv.zst

echo "All data files generated"

for F in \
  water-w_frames water-frames \
  nonartificial-frames nonartificial-w_frames \
  boatable canoeable \
  maxwidth \
  name-group-name rivers-etc \
  ; do
  mv planet-waterway-${F}.pmtiles ./upload_to_cloudflare/ || true
done
for F in \
  loops ends grouped-ends  \
  ; do
  mv planet-${F}.pmtiles ./upload_to_cloudflare/ || true
done
mv ./planet-loops.geojson.gz ./upload_to_cloudflare/ || true
mv ./planet-ditch-loops.geojson.gz ./upload_to_cloudflare/ || true
mv ./planet-loops-firstpoints.geojson.gz ./upload_to_cloudflare/ || true
mv ./planet-ends.geojson.gz ./upload_to_cloudflare/ || true
mv ./planet-unnamed-big-ends.geojson.gz ./upload_to_cloudflare || true
mv ./planet-waterway-stream-ends.geojson.gz ./upload_to_cloudflare/ || true
mv ./*zst ./upload_to_cloudflare/ 2>/dev/null || true
cp ./waterwaymap.org_ends_stats.csv.zst ./upload_to_cloudflare/ 2>/dev/null || true

jq <./upload_to_cloudflare/tilesets.json '.tilesets[0].key = "planet-waterway-water"|.tilesets[0].text = "Waterways (inc. canals etc)"|.tilesets[0].frames = true' | sponge ./upload_to_cloudflare/tilesets.json
jq <./upload_to_cloudflare/tilesets.json '.tilesets[1].key = "planet-waterway-nonartificial"|.tilesets[1].text = "Natural Waterways (excl. canals etc)"|.tilesets[1].frames = true' | sponge ./upload_to_cloudflare/tilesets.json
jq <./upload_to_cloudflare/tilesets.json '.tilesets[2].key = "planet-waterway-boatable"|.tilesets[2].text = "Navigable by boat (<code>boat=yes,motor</code>)"' | sponge ./upload_to_cloudflare/tilesets.json
jq <./upload_to_cloudflare/tilesets.json '.tilesets[3].key = "planet-waterway-canoeable"|.tilesets[3].text = "Navigable by canoe (<code>canoe=yes</code>)"' | sponge ./upload_to_cloudflare/tilesets.json
jq <./upload_to_cloudflare/tilesets.json '.tilesets[4].key = "planet-waterway-name-group-name"|.tilesets[4].text = "Named Waterways"' | sponge ./upload_to_cloudflare/tilesets.json
jq <./upload_to_cloudflare/tilesets.json '.tilesets[5].key = "planet-waterway-rivers-etc"|.tilesets[5].text = "Rivers (etc.)"' | sponge ./upload_to_cloudflare/tilesets.json
jq <./upload_to_cloudflare/tilesets.json '.tilesets[6].key = "planet-grouped-ends"|.tilesets[6].text = "Natural Waterway (downhills)"' | sponge ./upload_to_cloudflare/tilesets.json
jq <./upload_to_cloudflare/tilesets.json '.tilesets[7].key = "planet-waterway-maxwidth"|.tilesets[7].text = "With <code>maxswidth</code> tag"' | sponge ./upload_to_cloudflare/tilesets.json
jq <./upload_to_cloudflare/tilesets.json '.selected_tileset = "planet-grouped-ends"' | sponge ./upload_to_cloudflare/tilesets.json

./rss_update.sh ./upload_to_cloudflare/data_updates.xml "WaterwayMap.org Data update" "WaterwayMap.org has been updated with OSM data up until $LAST_TIMESTAMP"
echo "RSS feed updated, last data timestamp is $LAST_TIMESTAMP"

echo "Current size of the data is: $(du -hsc ./upload_to_cloudflare/ | head -1 | cut -f1)"

echo "All data & metadata finishing. Beginning upload..."
SECONDS=0
rclone sync --transfers 1 --order-by size,descending --bwlimit 3M ./upload_to_cloudflare/ cloudflare:data-waterwaymap-org/
echo "Took $(units ${SECONDS}sec time) (${SECONDS}sec) to upload pmtiles to cloudflare"
SECONDS=0
./upload_rivers_db.sh
echo "Took $(units ${SECONDS}sec time) (${SECONDS}sec) to upload /river/ page db to hetzner"
echo "Upload finished"

wait

exit 0
