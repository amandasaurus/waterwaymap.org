#!/bin/bash
set -o errexit -o nounset
cd "$(dirname "$0")"

echo "Starting dl_updates_from_osm.sh"

if [ ! -s planet-waterway.osm.pbf ] ; then
	echo "No planet-waterway.osm.pbf, downloading.."
	if [ ! -e planet-latest.osm.pbf ] ; then
		aria2c --seed-time=0 https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf.torrent
		# TODO rename from planet-YYMMDD.osm.obf to -latest
	fi
	osmium tags-filter --remove-tags --overwrite planet-latest.osm.pbf --output-header osmosis_replication_base_url=https://planet.openstreetmap.org/replication/minute/ -o planet-waterway.osm.pbf waterway
fi
echo "planet-waterway.osm.pbf, size: $(ls -lh planet-waterway.osm.pbf | cut -d" " -f5)"

SECONDS=0
LAST_TIMESTAMP=$(osmium fileinfo -g header.option.timestamp planet-waterway.osm.pbf)
if [ -z "$LAST_TIMESTAMP" ] ; then
	LAST_TIMESTAMP=$(osmium fileinfo --no-progress -e -g data.timestamp.last  planet-waterway.osm.pbf)
fi

TMP=$(mktemp -p . "tmp.planet.XXXXXX.osm.pbf")
pyosmium-up-to-date --ignore-osmosis-headers --server https://planet.openstreetmap.org/replication/minute/ -vv -s 10000 planet-waterway.osm.pbf
osmium tags-filter --overwrite --output-header osmosis_replication_base_url=https://planet.openstreetmap.org/replication/minute/ --remove-tags planet-waterway.osm.pbf -o "$TMP" w/waterway && mv "$TMP" planet-waterway.osm.pbf
osmium check-refs planet-waterway.osm.pbf || true

osmium check-refs --no-progress --show-ids planet-waterway.osm.pbf |& grep -Po "(?<= in w)\d+$" | uniq | sort -n | uniq > incomplete_ways.txt
if [ "$(wc -l incomplete_ways.txt | cut -f1 -d" ")" -gt 0 ] ; then
	cat incomplete_ways.txt | while read -r WID ; do
		curl -s -o "way_${WID}.osm.xml" "https://api.openstreetmap.org/api/0.6/way/${WID}/full"
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
	osmium apply-changes --output-header osmosis_replication_base_url=https://planet.openstreetmap.org/replication/minute/ --output-header="osmium_replication_timestamp=$LAST_TIMESTAMP" --output-header="timestamp=${LAST_TIMESTAMP}" -o new.osm.pbf planet-waterway.osm.pbf add-incomplete-ways.osc
	mv -v new.osm.pbf planet-waterway.osm.pbf
	rm -fv add-incomplete-ways.osc
	osmium check-refs planet-waterway.osm.pbf || true
fi
rm -f incomplete_ways.txt
echo "Took $SECONDS sec ( $(units "${SECONDS}sec" time) ) to download data updates from osm.org"
