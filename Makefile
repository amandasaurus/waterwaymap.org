.PRECIOUS: planet-waterway.osm.pbf

all: planet-waterway-river.pmtiles planet-waterway-name-group-name.pmtiles planet-waterway-river-canal.pmtiles planet-waterway-boatable.pmtiles planet-waterway-all.pmtiles planet-waterway-flowing.pmtiles

planet-waterway.osm.pbf:
	./dl_updates_from_osm.sh

%.gz: %
	gzip -9 -f $<

planet-waterway-river.geojson: planet-waterway.osm.pbf
	osm-lump-ways -v -i planet-waterway.osm.pbf -o tmp.$@ -f waterway=river --min-length-m 1000  --save-as-linestrings
	mv tmp.$@ $@

planet-waterway-name-no-group.geojson: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 1000 --save-as-linestrings -f waterway -f "∃~name(:.+)?"
	mv tmp.$@ $@

planet-waterway-name-group-name.geojson: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 1000 --save-as-linestrings -f waterway -f "∃~name(:.+)?" -g wikidata,name
	mv tmp.$@ $@

planet-waterway-noname.geojson: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 1000 --save-as-linestrings -f waterway -f "∄~name(:.+)?"
	mv tmp.$@ $@

planet-waterway-river-canal.geojson: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 1000 --save-as-linestrings -f waterway∈river,canal
	mv tmp.$@ $@

planet-waterway-boatable.geojson: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 1000 --save-as-linestrings -f waterway -f boat∈yes,motor
	mv tmp.$@ $@

planet-waterway-all.geojson: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 1000 --save-as-linestrings -f waterway
	mv tmp.$@ $@

planet-waterway-flowing.geojson: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 1000 --save-as-linestrings -f waterway -f waterway∉dam,weir,lock_gate,sluice_gate,security_lock,fairway,dock,boatyard,fuel,riverbank,pond,check_dam,turning_point,water_point,spillway
	mv tmp.$@ $@

%.pmtiles: %.geojson
	timeout 5h tippecanoe \
		-n "OSM River Topologies" \
		-N "Generated on $(shell date -I) from OSM data with $(shell osm-lump-ways --version) and argument" \
		-A "© OpenStreetMap. Open Data under ODbL. https://osm.org/copyright" \
		--single-precision \
		--simplification=8 \
		--drop-densest-as-needed \
		-y length_m -y root_wayid_120 \
		-l waterway \
		--coalesce --reorder \
		--gamma 2 \
		--no-progress-indicator \
		-o tmp.$@ $<
	#echo "PMTiles created successfully (in ${SECONDS}sec $(units "${SECONDS}sec" time)). size: $(ls -lh "${TMP}.pmtiles" | cut -d" " -f5)"
	mv tmp.$@ $@
