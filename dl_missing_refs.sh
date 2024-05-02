#!/bin/bash
# Makes an OSM PBF file referntially complete, by downloading nodes from
# OSM.org API that are referenced from ways in the input file.
#
# The `dl_updates_from_osm.sh` script does repeated `pyosmium-up-to-date` on a
# filtered OSM file, applying OSM diffs, and afterwards filtering out unwanted
# ways. OSM Diffs do not contain the referred objects. When a way is changed,
# to add a `waterway` tag, that new way version will be in the diff, and for
# the first time in the filtered OSM file. However the diff will not have
# included the ways in that way. An OSM file, updated this way, will not be
# referrantially complete. Some tools (e.g. `osm2pgsql`) will silently accept
# (& ignore) these incomplete objects. `osm-lump-ways` will fail to process,
# and report an error. 
#
# A simple solution is to keep the who 75 GiB planet file around, run
# `pyosmium-up-to-date` on that, and filter afterwards. That will always be
# referentially complete. However `pyosmium-up-to-date` must rewrite the planet
# file, and takes about 45 minutes. Filtering this new file, takes longer too.
# IME it is quicker to do pyosmium-up-to-date on a filtered file and run this
# programme after.
#
# If the OSM diff service returned some form of “augmented diffs”¹, or the OSM
# data model was changed to add the node position to ways directly (as Jochen
# Topf has suggested²), then this would't be needed.
#
# ¹ <https://wiki.openstreetmap.org/wiki/Overpass_API/Augmented_Diffs>
# ² <https://media.jochentopf.com/media/2022-08-15-study-evolution-of-the-osm-data-model.pdf>
#
set -o errexit -o nounset
FILENAME=$(realpath "${1:?Arg 1 must be filename}")
cd "$(dirname "$0")"

echo "Starting $0, this is the current status of referrential integreity"
osmium check-refs "$FILENAME" || true

osmium check-refs --no-progress --show-ids "$FILENAME" |& grep -Po "(?<= in w)\d+$" | uniq | sort -n | uniq > incomplete_ways.txt
NUM_MISSING=$(wc -l incomplete_ways.txt | cut -f1 -d" ")
if [ "$NUM_MISSING" -gt 0 ] ; then
	rm -rf way_*.osm.xml
	echo "There are $NUM_MISSING incomplete ways, which we need to download"
	cat incomplete_ways.txt | while read -r WID ; do
		curl -A "waterwaymap.org / dl_missing_refs"  -s -o "way_${WID}.osm.xml" "https://api.openstreetmap.org/api/0.6/way/${WID}/full"
    echo "Done w${WID}"
	done | pv -l -s "$NUM_MISSING" -c -N "Downloading incomplete ways" > /dev/null
	find . -maxdepth 1 -mindepth 1 -type f -name 'way_*.osm.xml' -empty -print -delete
	osmium cat --no-progress --overwrite -o incomplete_ways.osm.pbf way_*.osm.xml
	rm way_*.osm.xml
	rm -rf incomplete_ways2.osm.pbf
	osmium sort --no-progress -o incomplete_ways2.osm.pbf incomplete_ways.osm.pbf
	mv incomplete_ways2.osm.pbf incomplete_ways.osm.pbf
	echo "" > empty.opl
	rm -rf add-incomplete-ways.osc
	osmium derive-changes --no-progress empty.opl incomplete_ways.osm.pbf -o add-incomplete-ways.osc
	rm -f empty.opl incomplete_ways.osm.pbf

	rm -rf new.osm.pbf
	osmium apply-changes -o new.osm.pbf "$FILENAME" add-incomplete-ways.osc
	mv -v new.osm.pbf "$FILENAME"

  echo "Finished. Final check-ref output:"
	rm -fv add-incomplete-ways.osc
	osmium check-refs "$FILENAME" || true
fi
rm -f incomplete_ways.txt
