.PRECIOUS: planet-waterway.osm.pbf

all: planet-waterway-name-group-name.pmtiles planet-waterway-or-naturalwater.pmtiles planet-waterway-boatable.pmtiles planet-waterway-all.pmtiles

planet-waterway.osm.pbf:
	./dl_updates_from_osm.sh

%.gz: %
	gzip -9 -f $<

planet-waterway-river.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -v -i planet-waterway.osm.pbf -o tmp.$@ -f waterway=river --min-length-m 100  --save-as-linestrings
	mv tmp.$@ $@

planet-waterway-name-no-group.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -v -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f "∃~name(:.+)?"
	mv tmp.$@ $@

planet-waterway-name-group-name.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f "∃~name(:.+)?" -g wikidata,name --split-into-single-paths
	mv tmp.$@ $@

planet-waterway-noname.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -v -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f "∄~name(:.+)?"
	mv tmp.$@ $@

planet-waterway-river-canal.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -v -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway∈river,canal
	mv tmp.$@ $@

planet-waterway-river-stream.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -v -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway∈river,stream
	mv tmp.$@ $@

planet-waterway-river-canal-stream.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -v -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway∈river,canal,stream
	mv tmp.$@ $@

planet-waterway-river-or-named.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -v -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f waterway∈river,canal∨∃name
	mv tmp.$@ $@

planet-waterway-boatable.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -v -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f boat∈yes,motor
	mv tmp.$@ $@

planet-waterway-all.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -v -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway
	mv tmp.$@ $@

planet-waterway-or-naturalwater.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -v -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway∨natural=water
	mv tmp.$@ $@

planet-waterway-flowing.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -v -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f waterway∈river,stream
	mv tmp.$@ $@

planet-waterway-excl-non-moving.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -v -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f waterway∉dam,weir,lock_gate,sluice_gate,security_lock,fairway,dock,boatyard,fuel,riverbank,pond,check_dam,turning_point,water_point,spillway
	mv tmp.$@ $@

%.pmtiles: %.geojsons
	rm -fv tmp.$@
	timeout 8h tippecanoe \
		-n "OSM River Topologies" \
		-N "Generated on $(shell date -I) from OSM data with $(shell osm-lump-ways --version) and argument" \
		-A "© OpenStreetMap. Open Data under ODbL. https://osm.org/copyright" \
		-zg \
		--simplification=2 \
		--drop-densest-as-needed \
		-y length_m -y root_wayid_120 \
		-l waterway \
		--gamma 2 \
		-o tmp.$@ $<
	#echo "PMTiles created successfully (in ${SECONDS}sec $(units "${SECONDS}sec" time)). size: $(ls -lh "${TMP}.pmtiles" | cut -d" " -f5)"
	mv tmp.$@ $@
