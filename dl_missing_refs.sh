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

echo "Starting $0, calculating the current state of referrential integrity..."
osmium check-refs --check-relations "$FILENAME" || true

for OSM_TYPE in relation way ; do
  echo "Checking ${OSM_TYPE}s..."
  T=${OSM_TYPE:0:1}
  rm -f incomplete_objs.txt
  osmium check-refs --check-relations --no-progress --show-ids "$FILENAME" |& grep -Po "(?<= in $T)\d+$" | uniq | sort -n | uniq > incomplete_objs.txt

  NUM_MISSING=$(wc -l incomplete_objs.txt | cut -f1 -d" ")
  if [ "$NUM_MISSING" -gt 0 ] ; then
    rm -rf obj_*.osm.xml
    echo "There are $NUM_MISSING incomplete ${OSM_TYPE}s, which we need to download"
    cat incomplete_objs.txt | while read -r ID ; do
      while [ ! -s "obj_${T}${ID}.osm.xml" ] ; do
        curl --fail -A "waterwaymap.org / dl_missing_refs"  -s -o "obj_${T}${ID}.osm.xml" "https://api.openstreetmap.org/api/0.6/${OSM_TYPE}/${ID}/full"
        if grep -q "You have downloaded too much data." "obj_${T}${ID}.osm.xml" ; then
          # oops 
          rm "obj_${T}${ID}.osm.xml"
          sleep 5
          continue
        fi
      done
      echo "Done ${T}${ID}"
    done | pv -l -s "$NUM_MISSING" -c -N "Downloading incomplete ${OSM_TYPE}s" > /dev/null

    # clean up, just in case
    find . -maxdepth 1 -mindepth 1 -type f -name 'obj_*.osm.xml' -empty -print -delete

    # Merge files together
    # bash/linux has a limit on the total length of a command. With too many files, this update will fail.
    while [ "$(find . -maxdepth 1 -mindepth 1 -type f -name 'obj_*.osm.xml' -print | wc -l)" -gt 100 ] ; do
      echo "There are $(find . -maxdepth 1 -mindepth 1 -type f -name 'obj_*.osm.xml' -print | wc -l) XML files. Merging together"
      DEST=$(mktemp -p . obj_combo_XXXXXX.osm.xml)
      FILES=$(find . -maxdepth 1 -mindepth 1 -type f -name "obj_${T}*.osm.xml" -printf "%s %p\n" | sort -n | cut -d" " -f2 | head -n 100 | tr "\n" " ")
      osmium cat --no-progress --overwrite -o "$DEST" $FILES
      rm $FILES
    done

    # now join them all together
    osmium cat --no-progress --overwrite -o incomplete.osm.pbf obj_*.osm.xml
    rm obj_*.osm.xml

    rm -rf new.osm.pbf
    osmium sort --no-progress -o new.osm.pbf incomplete.osm.pbf
    mv new.osm.pbf incomplete.osm.pbf

    echo "Size of the objects to merge in: $(ls -lh incomplete.osm.pbf | cut -d" " -f5)"
    echo "" > empty.opl
    rm -rf add-incomplete-obj.osc
    osmium derive-changes --no-progress empty.opl incomplete.osm.pbf -o add-incomplete-obj.osc
    rm -f empty.opl incomplete.osm.pbf

    rm -rf new.osm.pbf
    osmium apply-changes -o new.osm.pbf "$FILENAME" add-incomplete-obj.osc
    mv -v new.osm.pbf "$FILENAME"
    rm -fv add-incomplete-obj.osc

  fi
done

echo "Finished. Final check-ref output:"
osmium check-refs "$FILENAME" || true
rm -f incomplete_objs.txt
