.PRECIOUS: planet-waterway.osm.pbf

planet-waterway.osm.pbf:
	./dl_updates_from_osm.sh

%.pmtiles: %.geojsons
	rm -fv tmp.$@
	timeout 8h tippecanoe \
		-n "WaterwayMap.org" \
		-N "Generated on $(shell date -I) from OSM data with $(shell ./osm-lump-ways --version)" \
		-A "© OpenStreetMap. Open Data under ODbL. https://osm.org/copyright" \
		-zg \
		--no-feature-limit \
		--simplification=8 --no-simplification-of-shared-nodes --simplification-at-maximum-zoom=2 \
		-y length_m -y root_nodeid -y root_nodeid_120 \
		--reorder --coalesce \
		--drop-smallest-as-needed \
		-l waterway \
		--gamma 2 \
		--extend-zooms-if-still-dropping \
		--no-progress-indicator \
		-o tmp.$@ $<
	mv tmp.$@ $@

%-frames.pmtiles: %-frames.geojsons %.pmtiles
	# Ensure this has the same maxzoom as the other file, so when we merge them
	# together they will always be shown
	rm -fv tmp.$@
	timeout 8h tippecanoe \
		-n "WaterwayMap.org Frames" \
		-N "Generated on $(shell date -I) from OSM data with $(shell osm-lump-ways --version)" \
		-A "© OpenStreetMap. Open Data under ODbL. https://osm.org/copyright" \
		-z$(shell pmtiles show $*.pmtiles | grep -oP "(?<=^max zoom: )\d+$$") \
		--no-feature-limit \
		--simplification=8 --no-simplification-of-shared-nodes --simplification-at-maximum-zoom=2 \
		--drop-smallest-as-needed \
		-y length_m -y root_nodeid -y root_nodeid_120 \
		-l frames \
		--gamma 2 \
		--extend-zooms-if-still-dropping \
		--no-progress-indicator \
		-o tmp.$@ $<
	mv tmp.$@ $@

%-w_frames.pmtiles: %.pmtiles %-frames.pmtiles
	rm -fv tmp.$@
	tile-join --no-tile-size-limit -o tmp.$@ $^
	mv tmp.$@ $@


%.gz: %
	gzip -9 -k -f $<

%.zst: %
	zstd -20 --ultra -f $<

%-ge100km.gpkg: %.geojsons
	ogr2ogr -select root_nodeid,length_m_int -unsetFid -overwrite -where "length_km_int >= 100" $@ $<

%-ge20km.geojsons: %.geojsons
	ogr2ogr -sql "select root_nodeid, length_m_int as length_m, tag_group_0 as name from \"$*\" where length_km >= 20" -unsetFid -overwrite $@ $<

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


#####################################################
# Here are the default map views on WaterwayMap.org #
#####################################################

# Default view. “Waterways (inc. canals etc)”
planet-waterway-water.geojsons planet-waterway-water-frames.geojsons: planet-waterway.osm.pbf
	rm -f tmp.planet-waterway-water.geojsons tmp.planet-waterway-water-frames.geojsons
	osm-lump-ways \
		-i $< -o tmp.planet-waterway-water.geojsons \
		--min-length-m 100 --save-as-linestrings \
		-f waterway \
		-f waterway∉dam,weir,lock_gate,sluice_gate,security_lock,fairway,dock,boatyard,fuel,riverbank,pond,check_dam,turning_point,water_point,safe_water \
		-f waterway∉seaway \
		--output-frames tmp.planet-waterway-water-frames.geojsons --frames-group-min-length-m 1e6
	mv tmp.planet-waterway-water.geojsons planet-waterway-water.geojsons
	mv tmp.planet-waterway-water-frames.geojsons planet-waterway-water-frames.geojsons

# “Natural Waterways (excl. canals etc)”
planet-waterway-nonartificial.geojsons planet-waterway-nonartificial-frames.geojsons: planet-waterway.osm.pbf
	rm -f tmp.planet-waterway-nonartificial.geojsons tmp.planet-waterway-nonartificial-frames.geojsons
	osm-lump-ways \
		-i $< -o tmp.planet-waterway-nonartificial.geojsons \
		--min-length-m 100 --save-as-linestrings \
		-F @flowing_water.tagfilterfunc \
		--output-frames tmp.planet-waterway-nonartificial-frames.geojsons --frames-group-min-length-m 1e6
	mv tmp.planet-waterway-nonartificial.geojsons planet-waterway-nonartificial.geojsons
	mv tmp.planet-waterway-nonartificial-frames.geojsons planet-waterway-nonartificial-frames.geojsons

# The “Navigable by boat” view
planet-waterway-boatable.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f boat∈yes,motor∨waterway=fairway
	mv tmp.$@ $@

# The “Navigable by canoe” view
planet-waterway-canoeable.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -F "canoe∈yes,portage,permissive,designated,destination,customers,permit→T; portage∈yes,permissive,designated,destination,customers,permit→T; F"
	mv tmp.$@ $@

# The “Named Waterways” view
planet-waterway-name-group-name.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f "∃~name(:.+)?" -g name --split-into-single-paths
	mv tmp.$@ $@

# The “Rivers (etc.)” view
planet-waterway-rivers-etc.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway∈river,stream,rapids,tidal_channel
	mv tmp.$@ $@

###################################################
# end of the default map views on WaterwayMap.org #
###################################################


planet-waterway-river.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i planet-waterway.osm.pbf -o tmp.$@ -f waterway=river --min-length-m 100  --save-as-linestrings
	mv tmp.$@ $@

planet-waterway-name-no-group.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f "∃~name(:.+)?"
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

planet-waterway-has-cemt.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f CEMT∈0,I,II,III,IV,Va,Vb,VIa,VIb,VIc,VII
	mv tmp.$@ $@

planet-waterway-cemt-ge-I.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f CEMT∈I,II,III,IV,Va,Vb,VIa,VIb,VIc,VII
	mv tmp.$@ $@

planet-waterway-cemt-ge-II.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f CEMT∈II,III,IV,Va,Vb,VIa,VIb,VIc,VII
	mv tmp.$@ $@

planet-waterway-cemt-ge-III.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f CEMT∈III,IV,Va,Vb,VIa,VIb,VIc,VII
	mv tmp.$@ $@

planet-waterway-cemt-ge-IV.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f CEMT∈IV,Va,Vb,VIa,VIb,VIc,VII
	mv tmp.$@ $@

planet-waterway-cemt-ge-V.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f CEMT∈V,Va,Vb,VIa,VIb,VIc,VII
	mv tmp.$@ $@

planet-waterway-cemt-ge-VI.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f CEMT∈VIa,VIb,VIc,VII
	mv tmp.$@ $@

planet-waterway-cemt-ge-VII.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f CEMT∈VII
	mv tmp.$@ $@

planet-waterway-cemt-all-geojsons: planet-waterway-has-cemt.geojsons planet-waterway-cemt-ge-I.geojsons planet-waterway-cemt-ge-II.geojsons planet-waterway-cemt-ge-III.geojsons planet-waterway-cemt-ge-IV.geojsons planet-waterway-cemt-ge-V.geojsons planet-waterway-cemt-ge-VI.geojsons planet-waterway-cemt-ge-VII.geojsons
planet-waterway-cemt-all-pmtiles: planet-waterway-has-cemt.pmtiles planet-waterway-cemt-ge-I.pmtiles planet-waterway-cemt-ge-II.pmtiles planet-waterway-cemt-ge-III.pmtiles planet-waterway-cemt-ge-IV.pmtiles planet-waterway-cemt-ge-V.pmtiles planet-waterway-cemt-ge-VI.pmtiles planet-waterway-cemt-ge-VII.pmtiles

planet-waterway-all.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway
	mv tmp.$@ $@

planet-waterway-or-naturalwater.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway∨natural=water
	mv tmp.$@ $@


planet-waterway-missing-wiki.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f name -f ∄wikipedia -f ∄wikidata -g name
	mv tmp.$@ $@

planet-loops.geojsons planet-ends.geojsons planet-grouped-ends.geojsons: planet-waterway.osm.pbf
	rm -fv tmp.planet-{loops,upstreams,ends}.geojsons
	osm-lump-ways-down -i ./planet-waterway.osm.pbf -F @flowing_water.tagfilterfunc --openmetrics ./docs/data/waterwaymap.org_loops_metrics.prom --csv-stats-file ./docs/data/waterwaymap.org_loops_stats.csv --upstream-output-biggest-end --min-upstream-m 100 --ends tmp.planet-ends.geojsons --ends-tag name --ends-tag wikidata --ends-tag wikipedia --loops tmp.planet-loops.geojsons --grouped-ends tmp.planet-grouped-ends.geojsons
	mv tmp.planet-loops.geojsons planet-loops.geojsons || true
	mv tmp.planet-ends.geojsons planet-ends.geojsons || true
	mv tmp.planet-grouped-ends.geojsons planet-grouped-ends.geojsons || true

planet-waterway-stream-ends.geojson: planet-waterway.osm.pbf flowing_water_wo_streams.tagfilterfunc
	rm -f tmp.$@
	osm-lump-ways-down -i ./planet-waterway.osm.pbf --ends tmp.$@ -F @flowing_water_wo_streams.tagfilterfunc --ends-membership waterway=stream
	rm -f $@
	ogr2ogr $@ tmp.$@ -where '"is_in:waterway=stream"'

planet-unnamed-big-ends.geojson: planet-ends.geojsons
	rm -f tmp.$@
	ogr2ogr tmp.$@ $< -where '"tag:name" is null and  upstream_m >= 1000000'
	mv tmp.$@ $@

waterwaymap.org_ends_stats.csv: planet-ends.geojsons
	bash -c 'if [ ! -s $@ ] ; then echo "timestamp,iso_datetime,upstream_m,nid,lat,lng,wikidata,name,wikipedia" > $@ ; fi'
	$(eval ISO_TIMESTAMP=$(shell jq -Mr <docs/data/tilesets.json ".data_timestamp"))
	$(eval TIMESTAMP=$(shell date -d $(ISO_TIMESTAMP) +%s))
	jq -Mr <planet-ends.geojsons ".|select( .properties.\"tag:name\" != null and .properties.upstream_m >= 500000)|[$(TIMESTAMP),\"$(ISO_TIMESTAMP)\",.properties.upstream_m,.properties.nid,.geometry.coordinates[0],.geometry.coordinates[1],.properties.\"tag:wikidata\",.properties.\"tag:name\",.properties.\"tag:wikipedia\"]|@csv" | xsv sort -s 3 -NR --no-headers | head -n 1000 >> $@
	zstd --quiet --force -z -k -e -19 $@ -o $@.zst

planet-ditch-loops.geojson ./docs/data/waterwaymap.org_ditch_loops_stats.csv: planet-waterway.osm.pbf
	rm -rf tmp.planet-ditch-loops.geojson
	osm-lump-ways-down -i ./planet-waterway.osm.pbf -f waterway=ditch --csv-stats-file ./docs/data/waterwaymap.org_ditch_loops_stats.csv --loops tmp.planet-ditch-loops.geojson
	mv tmp.planet-ditch-loops.geojson planet-ditch-loops.geojson

planet-loops-lines.pmtiles: planet-loops.geojsons
	rm -fv tmp.$@
	timeout 8h tippecanoe \
		-n "WaterwayMap.org Loops" \
		-N "Generated on $(shell date -I) from OSM data with $(shell osm-lump-ways --version)" \
		-A "© OpenStreetMap. Open Data under ODbL. https://osm.org/copyright" \
		--simplification=8 --no-simplification-of-shared-nodes --simplification-at-maximum-zoom=2 \
		-r1 \
		--cluster-densest-as-needed \
		--no-feature-limit \
		--no-tile-size-limit \
		--accumulate-attribute num_nodes:sum \
		--accumulate-attribute length_m:sum \
		-y root_nid -y num_nodes -y length_m \
		-l loop_lines \
		--no-progress-indicator \
		-o tmp.$@ $<
	mv tmp.$@ $@

%-firstpoints.geojsons: %.geojsons
	jq --seq <$< >$@ '{"type": "Feature", "properties": .properties, "geometry": {"type": "Point", "coordinates": .geometry.coordinates[0][0] }}'

%.geojson: %.geojsons
	ogr2ogr $@ $<

planet-loops-firstpoints.pmtiles: planet-loops-firstpoints.geojsons
	rm -fv tmp.$@
	timeout 8h tippecanoe \
		-n "WaterwayMap.org Loops" \
		-N "Generated on $(shell date -I) from OSM data with $(shell osm-lump-ways --version)" \
		-A "© OpenStreetMap. Open Data under ODbL. https://osm.org/copyright" \
		--simplification=8 --no-simplification-of-shared-nodes --simplification-at-maximum-zoom=2 \
		-r1 \
		--cluster-densest-as-needed \
		--no-feature-limit \
		--no-tile-size-limit \
		--accumulate-attribute num_nodes:sum \
		--accumulate-attribute length_m:sum \
		-y root_nid -y num_nodes -y length_m \
		-l loop_points \
		--no-progress-indicator \
		-o tmp.$@ $<
	mv tmp.$@ $@

planet-loops.pmtiles: planet-loops-firstpoints.pmtiles planet-loops-lines.pmtiles
	rm -fv tmp.$@
	tile-join --no-tile-size-limit -o tmp.$@ $^
	mv tmp.$@ $@

#planet-upstreams.pmtiles: planet-upstreams.geojsons
#	rm -fv tmp.$@
#	timeout 8h tippecanoe \
#		-n "WaterwayMap.org Upstream" \
#		-N "Generated on $(shell date -I) from OSM data with $(shell osm-lump-ways-down --version)" \
#		-A "© OpenStreetMap. Open Data under ODbL. https://osm.org/copyright" \
#		-zg \
#		--simplification=8 --no-simplification-of-shared-nodes --simplification-at-maximum-zoom=2 \
#		-r1 \
#		-y from_upstream_m_100 -y end_nid \
#		-j '{ "*": [ "any", [ ">=", "$$zoom", 6 ], [ "from_upstream_m_100", "ge", 1000000 ] ] }' \
#		--reorder --coalesce \
#		--no-feature-limit \
#		--drop-smallest-as-needed \
#		-l upstreams \
#		-o tmp.$@ $<
#	mv tmp.$@ $@

#planet-waterway-w-ends.pmtiles: planet-upstreams.geojsons
#	rm -fv tmp.$@
#	timeout 8h tippecanoe \
#		-n "WaterwayMap.org Upstream" \
#		-N "Generated on $(shell date -I) from OSM data with $(shell osm-lump-ways-down --version)" \
#		-A "© OpenStreetMap. Open Data under ODbL. https://osm.org/copyright" \
#		-zg \
#		--simplification=8 --no-simplification-of-shared-nodes --simplification-at-maximum-zoom=2 \
#		-r1 \
#		-y end_nid \
#		--reorder --coalesce \
#		--no-feature-limit \
#		--drop-smallest-as-needed \
#		-l waterway_ends \
#		-o tmp.$@ $<
#	mv tmp.$@ $@


planet-ends.pmtiles: planet-ends.geojsons
	rm -fv tmp.$@
	timeout 8h tippecanoe \
		-n "WaterwayMap.org Endpoints" \
		-N "Generated on $(shell date -I) from OSM data with $(shell osm-lump-ways --version)" \
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

# Attempt to generate geojsons which group related upstream values (for
# different zoom levels) together
#
#planet-upstreams.pg_imported: planet-upstreams.csv planet-ends.geojsons
#	time ogr2ogr -f PostgreSQL PG:"" planet-ends.geojsons -nln waterway_ends -select nid,upstream_m -lco SPATIAL_INDEX=none -lco GEOMETRY_NAME=geom -lco UNLOGGED=on -overwrite
#	time ogr2ogr -f PostgreSQL PG:"" planet-upstreams.csv -nln waterway_upstreams -select end_nid,from_upstream_m -lco SPATIAL_INDEX=none -lco GEOMETRY_NAME=geom -lco UNLOGGED=on -overwrite -oo AUTODETECT_TYPE=yes -oo KEEP_GEOM_COLUMNS=no
#	psql -c "create index on waterway_upstreams (end_nid);"
#	psql -c "cluster waterway_upstreams on waterway_upstreams_end_nid_idx;"
#	psql -c "create index on waterway_ends (nid);"
#	psql -c "cluster waterway_ends on waterway_ends_nid_idx;"
#	touch $@
#
#planet-waterway-upstream-100.geojsons: planet-upstreams.pg_imported
#	rm -f tmp.$@
#	ogr2ogr tmp.$@ PG:"" -sql "select end_nid, (select upstream_m from waterway_ends where nid = end_nid limit 1) as end_upstream_m, 100*round(from_upstream_m/100) as upstream_m, (St_dump(st_linemerge(st_union(geom), true))).geom as geom from waterway_upstreams group by end_nid, upstream_m"
#	mv tmp.$@ $@
#
#planet-waterway-upstream-1000.geojsons: planet-upstreams.pg_imported
#	rm -f tmp.$@
#	ogr2ogr tmp.$@ PG:"" -sql "select end_nid, (select upstream_m from waterway_ends where nid = end_nid limit 1) as end_upstream_m, 1000*round(from_upstream_m/1000) as upstream_m, (St_Dump(st_linemerge(st_union(geom), true))).geom as geom from waterway_upstreams group by end_nid, upstream_m"
#	mv tmp.$@ $@
#
#planet-waterway-upstream-10000.geojsons: planet-upstreams.pg_imported
#	rm -f tmp.$@
#		ogr2ogr tmp.$@ PG:"" -sql "select end_nid, (select upstream_m from waterway_ends where nid = end_nid limit 1) as end_upstream_m, 10000*round(from_upstream_m/10000) as upstream_m, (ST_Dump(st_linemerge(st_union(geom), true))).geom as geom from waterway_upstreams group by end_nid, upstream_m"
#	mv tmp.$@ $@

planet-grouped-ends.pmtiles: planet-grouped-ends.geojsons
	rm -fv tmp.$@
	timeout 8h tippecanoe \
		-n "WaterwayMap.org Upstream" \
		-N "Generated on $(shell date -I) from OSM data with $(shell osm-lump-ways-down --version)" \
		-A "© OpenStreetMap. Open Data under ODbL. https://osm.org/copyright" \
		-zg \
		--simplification=8 --no-simplification-of-shared-nodes --simplification-at-maximum-zoom=2 \
		-r1 \
		-y end_nid -y end_upstream_m \
		--reorder --coalesce \
		--no-feature-limit --maximum-tile-bytes $(shell units -t 1MiB bytes) \
		--extend-zooms-if-still-dropping \
		--drop-smallest-as-needed \
		--no-progress-indicator \
		-l upstreams \
		-o tmp.$@ $<
	mv tmp.$@ $@

