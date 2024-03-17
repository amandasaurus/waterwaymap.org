#!/bin/bash
set -o errexit -o nounset
cd "$(dirname "$0")"

echo "Starting dl_updates_from_osm.sh"
TAG_FILTER="w/waterway w/natural=water w/canoe"

if [ ! -s planet-waterway.osm.pbf ] ; then
	if [ ! -e planet-latest.osm.pbf ] ; then
		echo "No planet-waterway.osm.pbf, downloading.."
		aria2c --seed-time=0 https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf.torrent
		# TODO rename from planet-YYMMDD.osm.pbf to -latest
	fi
	osmium tags-filter --remove-tags --overwrite planet-latest.osm.pbf --output-header osmosis_replication_base_url=https://planet.openstreetmap.org/replication/minute/ -o planet-waterway.osm.pbf $TAG_FILTER
fi
echo "planet-waterway.osm.pbf, size: $(ls -lh planet-waterway.osm.pbf | cut -d" " -f5)"
# quick shortcut for when we run this a log
if [ $(( $(date +%s) - $(stat -c %Y planet-waterway.osm.pbf) )) -lt 600 ] ; then
	exit 0
fi

SECONDS=0
LAST_TIMESTAMP=$(osmium fileinfo -g header.option.timestamp planet-waterway.osm.pbf)
if [ -z "$LAST_TIMESTAMP" ] ; then
	LAST_TIMESTAMP=$(osmium fileinfo --no-progress -e -g data.timestamp.last  planet-waterway.osm.pbf)
fi
echo "Current latest timestamp in file is $LAST_TIMESTAMP"

TMP=$(mktemp -p . "tmp.planet.XXXXXX.osm.pbf")
if [ $(( $(date +%s) - "$(date -d "$LAST_TIMESTAMP" +%s)" )) -gt "$(units -t 2days sec)" ] ; then
	echo "Downloading per-day updates.."
       pyosmium-up-to-date -v --ignore-osmosis-headers --server https://planet.openstreetmap.org/replication/day/ -s 10000 planet-waterway.osm.pbf
       osmium tags-filter --overwrite --remove-tags planet-waterway.osm.pbf -o "$TMP" $TAG_FILTER && mv "$TMP" planet-waterway.osm.pbf
fi
if [ $(( $(date +%s) - "$(date -d "$(osmium fileinfo -g header.option.timestamp planet-waterway.osm.pbf)" +%s)" )) -gt "$(units -t 2hours sec)" ] ; then
	echo "Downloading per-hour updates.."
       pyosmium-up-to-date -v --ignore-osmosis-headers --server https://planet.openstreetmap.org/replication/hour/ -s 10000 planet-waterway.osm.pbf
       osmium tags-filter --overwrite --remove-tags planet-waterway.osm.pbf -o "$TMP" $TAG_FILTER && mv "$TMP" planet-waterway.osm.pbf
fi
echo "Downloading per-minute updates.."
pyosmium-up-to-date -v --ignore-osmosis-headers --server https://planet.openstreetmap.org/replication/minute/ -s 10000 planet-waterway.osm.pbf
osmium tags-filter --overwrite --output-header osmosis_replication_base_url=https://planet.openstreetmap.org/replication/minute/  --remove-tags planet-waterway.osm.pbf -o "$TMP" $TAG_FILTER && mv "$TMP" planet-waterway.osm.pbf
osmium check-refs planet-waterway.osm.pbf || true

./dl_missing_refs.sh planet-waterway.osm.pbf

echo "Took $SECONDS sec ( $(units "${SECONDS}sec" time) ) to download data updates from osm.org"
