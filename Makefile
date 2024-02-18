.PRECIOUS: planet-waterway.osm.pbf

planet-waterway.osm.pbf:
	./dl_updates_from_osm.sh

%.pmtiles: %.geojsons
	rm -fv tmp.$@
	timeout 8h tippecanoe \
		-n "OSM River Topologies" \
		-N "Generated on $(shell date -I) from OSM data with $(shell osm-lump-ways --version) and argument" \
		-A "© OpenStreetMap. Open Data under ODbL. https://osm.org/copyright" \
		-zg \
		--no-feature-limit \
		--simplification=8 \
		--drop-densest-as-needed \
		-y length_m -y root_wayid_120 \
		-l waterway \
		--gamma 2 \
		--no-progress-indicator \
		-o tmp.$@ $<
	mv tmp.$@ $@

%.gz: %
	gzip -9 -k -f $<

%.zst: %
	zstd -9 -f $<

%-ge100km.gpkg: %.geojsons
	ogr2ogr -select root_wayid,length_m_int -unsetFid -overwrite -where "length_km_int >= 100" $@ $<

%-ge20km.geojsons: %.geojsons
	ogr2ogr -sql "select root_wayid, length_m_int as length_m, tag_group_0 as name from \"$*\" where length_km >= 20" -unsetFid -overwrite $@ $<

%.torrent: %
	rm -fv $@
	mktorrent -l 22 $< \
     -a udp://tracker.opentrackr.org:1337 \
     -a udp://tracker.datacenterlight.ch:6969/announce,http://tracker.datacenterlight.ch:6969/announce \
     -a udp://tracker.torrent.eu.org:451 \
     -a udp://tracker-udp.gbitt.info:80/announce,http://tracker.gbitt.info/announce,https://tracker.gbitt.info/announce \
     -a http://retracker.local/announce \
	 -w "https://data.waterwaymap.org/$<" \
     -c "WaterwayMap.org data export. licensed under https://opendatacommons.org/licenses/odbl/ by OpenStreetMap contributors" \
     -o $@ > /dev/null

planet-waterway-river.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i planet-waterway.osm.pbf -o tmp.$@ -f waterway=river --min-length-m 100  --save-as-linestrings
	mv tmp.$@ $@

planet-waterway-name-no-group.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f "∃~name(:.+)?"
	mv tmp.$@ $@

planet-waterway-name-group-name.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f "∃~name(:.+)?" -g name --split-into-single-paths
	mv tmp.$@ $@

planet-waterway-noname.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f "∄~name(:.+)?"
	mv tmp.$@ $@

planet-waterway-river-canal.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway∈river,canal
	mv tmp.$@ $@

planet-waterway-river-stream.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway∈river,stream
	mv tmp.$@ $@

planet-waterway-river-canal-stream.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway∈river,canal,stream
	mv tmp.$@ $@

planet-waterway-river-or-named.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f waterway∈river,canal∨∃name
	mv tmp.$@ $@

planet-waterway-boatable.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f boat∈yes,motor
	mv tmp.$@ $@

planet-waterway-canoeable.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f canoe∈yes,portage,permissive,designated,destination,customers,permit
	mv tmp.$@ $@

planet-waterway-all.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway
	mv tmp.$@ $@

planet-waterway-or-naturalwater.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway∨natural=water
	mv tmp.$@ $@


planet-waterway-water.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f waterway∉dam,weir,lock_gate,sluice_gate,security_lock,fairway,dock,boatyard,fuel,riverbank,pond,check_dam,turning_point,water_point,safe_water
	mv tmp.$@ $@

planet-waterway-nonartifical.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f waterway∉dam,weir,lock_gate,sluice_gate,security_lock,fairway,dock,boatyard,fuel,riverbank,pond,check_dam,turning_point,water_point,safe_water -f waterway∉canal,ditch,drain
	mv tmp.$@ $@

planet-waterway-rivers-etc.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway∈river,stream,rapids,tidal_channel
	mv tmp.$@ $@

planet-waterway-missing-wiki.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f name -f ∄wikipedia -f ∄wikidata -g name
	mv tmp.$@ $@

planet-loops.geojsons planet-upstreams.geojsons planet-ends.geojsons: planet-waterway.osm.pbf
	rm -fv tmp.planet-{loops,upstreams,ends}.geojsons
	osm-lump-ways-down -i ./planet-waterway.osm.pbf -o tmp.planet-%s.geojsons -f waterway -f waterway∉dam,weir,lock_gate,sluice_gate,security_lock,fairway,dock,boatyard,fuel,riverbank,pond,check_dam,turning_point,water_point,safe_water,derelict_canal,offshore_field,boat_lift,depth_line,floating_barrier,floodgate -f waterway∉ditch,drain,tidal_channel -f waterway≠canal∨lock=yes -f waterway∉put_in,link -f waterway≠spillway∨area≠yes -f waterway≠canal∨usage=spillway -f waterway≠canal∨usage∈headrace,tailrace --openmetrics ./docs/data/waterwaymap.org_loops_metrics.prom --csv-stats-file ./docs/data/waterwaymap.org_loops_stats.csv
	mv tmp.planet-loops.geojsons planet-loops.geojsons
	mv tmp.planet-upstreams.geojsons planet-upstreams.geojsons || true
	mv tmp.planet-ends.geojsons planet-ends.geojsons || true

planet-loops.pmtiles: planet-loops.geojsons
	rm -fv tmp.$@
	timeout 8h tippecanoe \
		-n "OSM Waterway Loops" \
		-N "Generated on $(shell date -I) from OSM data with $(shell osm-lump-ways --version) and argument" \
		-A "© OpenStreetMap. Open Data under ODbL. https://osm.org/copyright" \
		-zg \
		--simplification=8 \
		-r1 \
		--cluster-densest-as-needed \
		--no-feature-limit \
		--no-tile-size-limit \
		--accumulate-attribute num_nodes:sum \
		--accumulate-attribute length_m:sum \
		-y root_nid -y num_nodes -y length_m \
		-l loops \
		--no-progress-indicator \
		-o tmp.$@ $<
	mv tmp.$@ $@

planet-upstreams.pmtiles: planet-upstreams.geojsons
	rm -fv tmp.$@
	timeout 8h tippecanoe \
		-n "OSM Waterway Upstream" \
		-N "Generated on $(shell date -I) from OSM data with $(shell osm-lump-ways --version) and argument" \
		-A "© OpenStreetMap. Open Data under ODbL. https://osm.org/copyright" \
		-zg \
		--simplification=8 \
		--cluster-densest-as-needed \
		-r1 \
		--cluster-distance 1 \
		--accumulate-attribute from_upstream_m:max \
		-y from_upstream_m \
		-l upstreams \
		--gamma 2 \
		-o tmp.$@ $<
	mv tmp.$@ $@

planet-ends.pmtiles: planet-ends.geojsons
	rm -fv tmp.$@
	timeout 8h tippecanoe \
		-n "OSM Waterway Endpoints" \
		-N "Generated on $(shell date -I) from OSM data with $(shell osm-lump-ways --version) and argument" \
		-A "© OpenStreetMap. Open Data under ODbL. https://osm.org/copyright" \
		-r1 \
		-z 10 \
		--feature-filter '{ "*": [">=", "upstream_m", 2000 ] }' \
		--no-feature-limit \
		--order-descending-by upstream_m \
		-r1 \
		--cluster-distance 5 \
		--accumulate-attribute upstream_m:sum \
		-y upstream_m -y nid \
		-l ends \
		--no-progress-indicator \
		-o tmp.$@ $<
	mv tmp.$@ $@

planet-ends.geojsons.gz: planet-ends.geojsons
	rm -fv $@
	gzip -k -9 $<
