#!/bin/bash
set -o errexit -o nounset
cd "$(dirname "$0")"

source functions.sh

if [ ! -s planet-waterway.osm.pbf ] ; then
	if [ ! -e planet-latest.osm.pbf ] ; then
		aria2c --seed-time=0 https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf.torrent
		# TODO rename from planet-YYMMDD.osm.obf to -latest
	fi
	osmium tags-filter --remove-tags --overwrite planet-latest.osm.pbf --output-header osmosis_replication_base_url=https://planet.openstreetmap.org/replication/minute/ -o planet-waterway.osm.pbf waterway
fi

LAST_TIMESTAMP=$(osmium fileinfo -g header.option.timestamp planet-waterway.osm.pbf)
if [ -z "$LAST_TIMESTAMP" ] ; then
	LAST_TIMESTAMP=$(osmium fileinfo --no-progress -e -g data.timestamp.last  planet-waterway.osm.pbf)
fi

TMP=$(mktemp -p . "tmp.planet.XXXXXX.osm.pbf")
if [ $(( $(date +%s) - "$(date -d "$LAST_TIMESTAMP" +%s)" )) -gt $(units -t 2days sec) ] ; then
	pyosmium-up-to-date -vv --ignore-osmosis-headers --server https://planet.openstreetmap.org/replication/day/ -s 10000 planet-waterway.osm.pbf
	osmium tags-filter --overwrite --remove-tags planet-waterway.osm.pbf -o "$TMP" w/waterway && mv "$TMP" planet-waterway.osm.pbf
fi
if [ $(( $(date +%s) - "$(date -d "$(osmium fileinfo -g header.option.timestamp planet-waterway.osm.pbf)" +%s)" )) -gt $(units -t 2hours sec) ] ; then
	pyosmium-up-to-date -vv --ignore-osmosis-headers --server https://planet.openstreetmap.org/replication/hour/ -s 10000 planet-waterway.osm.pbf
	osmium tags-filter --overwrite --remove-tags planet-waterway.osm.pbf -o "$TMP" w/waterway && mv "$TMP" planet-waterway.osm.pbf
fi
pyosmium-up-to-date -vv --ignore-osmosis-headers --server https://planet.openstreetmap.org/replication/minute/ -s 10000 planet-waterway.osm.pbf
osmium tags-filter --overwrite --remove-tags planet-waterway.osm.pbf -o "$TMP" w/waterway && mv "$TMP" planet-waterway.osm.pbf
osmium check-refs planet-waterway.osm.pbf || true

osmium check-refs --no-progress --show-ids planet-waterway.osm.pbf |& grep -Po "(?<= in w)\d+$" | uniq | sort -n | uniq > incomplete_ways.txt
if [ "$(wc -l incomplete_ways.txt | cut -f1 -d" ")" -gt 0 ] ; then
	cat incomplete_ways.txt | while read WID ; do
		curl -s -o way_${WID}.osm.xml https://api.openstreetmap.org/api/0.6/way/${WID}/full
	done
	osmium cat --overwrite -o incomplete_ways.osm.pbf way_*.osm.xml
	rm way_*.osm.xml
	rm -rf incomplete_ways2.osm.pbf
	osmium sort -o incomplete_ways2.osm.pbf incomplete_ways.osm.pbf
	mv incomplete_ways2.osm.pbf incomplete_ways.osm.pbf
	echo "" > empty.opl
	rm -rf add-incomplete-ways.osc
	osmium derive-changes empty.opl incomplete_ways.osm.pbf -o add-incomplete-ways.osc
	rm -f empty.opl incomplete_ways.osm.pbf

	rm -rf new.osm.pbf
	osmium apply-changes --output-header="osmium_replication_timestamp=$LAST_TIMESTAMP" --output-header="timestamp=${LAST_TIMESTAMP}" -o new.osm.pbf planet-waterway.osm.pbf add-incomplete-ways.osc
	mv -v new.osm.pbf planet-waterway.osm.pbf
	rm -fv add-incomplete-ways.osc
	osmium check-refs planet-waterway.osm.pbf || true
fi
rm -f incomplete_ways.txt
osmium fileinfo -g header.option.timestamp planet-waterway.osm.pbf

# Now do processing

SECONDS=0
process planet-waterway.osm.pbf planet-waterway-river "-f waterway=river"
jo tilesets=[] > ./docs/data/tilesets.json
jq <./docs/data/tilesets.json '.tilesets[0].key = "planet-waterway-river"|.tilesets[0].text = "only <code>waterway=river</code>"' | sponge ./docs/data/tilesets.json
jq <./docs/data/tilesets.json '.selected_tileset = "planet-waterway-river"' | sponge ./docs/data/tilesets.json
echo "Took $SECONDS sec ( $(units "${SECONDS}sec" time) ) to do update for -f waterway=river"
jq <./docs/data/tilesets.json ".data_timestamp = \"${LAST_TIMESTAMP}\"" | sponge ./docs/data/tilesets.json

SECONDS=0
process planet-waterway.osm.pbf planet-waterway-name-no-group "-f waterway -f name"
jq <./docs/data/tilesets.json '.tilesets[1].key = "planet-waterway-name-no-group"|.tilesets[1].text = "with <code>waterway</code> &amp; <code>name</code>. Purely topological grouping"' | sponge ./docs/data/tilesets.json
echo "Took $SECONDS sec ( $(units "${SECONDS}sec" time) ) to do update for -f waterway -f name"

SECONDS=0
process planet-waterway.osm.pbf planet-waterway-name-group-name "-f waterway -f name -g name"
jq <./docs/data/tilesets.json '.tilesets[2].key = "planet-waterway-name-group-name"|.tilesets[2].text = "with <code>waterway</code> &amp; <code>name</code> tags. grouped by topology &amp; name"' | sponge ./docs/data/tilesets.json
echo "Took $SECONDS sec ( $(units "${SECONDS}sec" time) ) to do update for -f waterway -f name -g name"

SECONDS=0
process planet-waterway.osm.pbf planet-waterway-noname "-f waterway -f ∄name"
jq <./docs/data/tilesets.json '.tilesets[3].key = "planet-waterway-noname"|.tilesets[3].text = "Unnamed <code>waterway</code>"' | sponge ./docs/data/tilesets.json
echo "Took $SECONDS sec ( $(units "${SECONDS}sec" time) ) to do update for -f waterway -f ∄name"

SECONDS=0
process planet-waterway.osm.pbf planet-waterway-river-canal "-f waterway∈river,canal"
jq <./docs/data/tilesets.json '.tilesets[4].key = "planet-waterway-river-canal"|.tilesets[4].text = "<code>waterway=river</code> or <code>=canal</code>"' | sponge ./docs/data/tilesets.json
echo "Took $SECONDS sec ( $(units "${SECONDS}sec" time) ) to do update for -f waterway∈river,canal"

rclone sync ./docs/data/ cloudflare:pmtiles0/2023-04-01/  --progress

wait

exit 0
