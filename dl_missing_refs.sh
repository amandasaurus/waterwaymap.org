#!/bin/bash
set -o errexit -o nounset
cd "$(dirname "$0")"

FILENAME="${1:?Arg 1 must be filename}"

osmium check-refs "$FILENAME" || true

osmium check-refs --no-progress --show-ids "$FILENAME" |& grep -Po "(?<= in w)\d+$" | uniq | sort -n | uniq > incomplete_ways.txt
if [ "$(wc -l incomplete_ways.txt | cut -f1 -d" ")" -gt 0 ] ; then
	echo "There are $(wc -l incomplete_ways.txt|cut -f1 -d" ") incomplete ways, which we need to download"
	cat incomplete_ways.txt | while read -r WID ; do
		curl -s -o "way_${WID}.osm.xml" "https://api.openstreetmap.org/api/0.6/way/${WID}/full"
	done
	find . -maxdepth 1 -mindepth 1 -type f -name 'way_*.osm.xml' -empty -print -delete
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
	osmium apply-changes -o new.osm.pbf "$FILENAME" add-incomplete-ways.osc
	mv -v new.osm.pbf "$FILENAME"
	rm -fv add-incomplete-ways.osc
	osmium check-refs "$FILENAME" || true
fi
rm -f incomplete_ways.txt
