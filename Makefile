.PRECIOUS: planet-waterway.osm.pbf

geojson_files: planet-waterway-boatable.geojsons planet-waterway-canoeable.geojsons \
  planet-waterway-maxwidth.geojsons \
  planet-waterway-name-group-name.geojsons \
  planet-waterway-water.geojsons planet-waterway-water-frames.geojsons \
  planet-waterway-nonartificial.geojsons planet-waterway-nonartificial-frames.geojsons \
  planet-waterway-rivers-etc.geojsons \
  planet-loops.geojsons planet-ends.geojsons planet-grouped-ends.geojsons planet-grouped-waterways.geojson planet-longest-source-mouth.geojsons \
  planet-waterway-stream-ends.geojson.gz \
  planet-unnamed-big-ends.geojson.gz \
  planet-ditch-loops.geojson.gz

output_files: output_pmtiles_files output_loops output_ends output_dl_stats output_riverdb

output_pmtiles_files: planet-waterway-boatable.pmtiles planet-waterway-canoeable.pmtiles \
  planet-waterway-maxwidth.pmtiles \
  planet-waterway-name-group-name.pmtiles \
  planet-waterway-water.pmtiles planet-waterway-water-frames.pmtiles \
  planet-waterway-nonartificial.pmtiles planet-waterway-nonartificial-frames.pmtiles \
  planet-waterway-rivers-etc.pmtiles \
  planet-waterway-water-w_frames.pmtiles planet-waterway-nonartificial-w_frames.pmtiles \
  planet-grouped-ends.pmtiles

output_loops: planet-loops.pmtiles planet-loops-firstpoints.geojson.gz planet-loops.geojson.gz \
	planet-loops.pmtiles planet-loops-firstpoints.geojson.gz planet-loops.geojson.gz
output_ends: planet-ends.pmtiles planet-ends.geojson.gz waterwaymap.org_ends_stats.csv.zst
output_dl_stats: planet-upstreams.csv.zst planet-grouped-ends.geojsons.zst
output_riverdb: rivers_html.db

planet-waterway.osm.pbf:
	./dl_updates_from_osm.sh

%.pmtiles: %.geojsons
	rm -fv tmp.$@
	timeout 8h tippecanoe \
		-n "WaterwayMap.org" \
		-N "Generated on $(shell date -I) from OSM data with $(shell osm-lump-ways --version)" \
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
		--temporary-directory=$(PWD) \
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
		--temporary-directory=$(PWD) \
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

planet-waterway-maxwidth.geojsons: planet-waterway.osm.pbf
	rm -f tmp.$@
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f maxwidth
	mv tmp.$@ $@

# maxwidth:physical
# Currently not called because there are no geometries that match it, and
# various tools fail if there's no data.
planet-waterway-maxwidthphysical.geojsons: planet-waterway.osm.pbf
	rm -f tmp.$@
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f maxwidth:physical
	mv tmp.$@ $@

# The “Named Waterways” view
planet-waterway-name-group-name.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway -f "∃~name(:.+)?" -g name --split-into-single-paths
	mv tmp.$@ $@

# The “Rivers (etc.)” view
planet-waterway-rivers-etc.geojsons: planet-waterway.osm.pbf
	osm-lump-ways -i $< -o tmp.$@ --min-length-m 100 --save-as-linestrings -f waterway∈river,stream,rapids,tidal_channel
	mv tmp.$@ $@

planet-loops.geojsons planet-ends.geojsons planet-grouped-ends.geojsons planet-upstreams.csv planet-grouped-waterways.geojson waterwaymap.org_ends_stats.csv planet-longest-source-mouth.geojsons:  planet-waterway.osm.pbf
	rm -fv tmp.planet-{loops,upstreams,ends}.geojsons
	osm-lump-ways-down \
		-i ./planet-waterway.osm.pbf -F @flowing_water.tagfilterfunc --min-upstream-m 100 \
		--loops tmp.planet-loops.geojsons  --loops-csv-stats-file ./upload_to_cloudflare/waterwaymap.org_loops_stats.csv \
		--flow-follows-tag name \
		--ends tmp.planet-ends.geojsons --ends-tag name --ends-tag wikidata --ends-tag wikipedia \
		--grouped-ends tmp.planet-grouped-ends.geojsons --grouped-ends-max-distance-m 10e3 \
		--ends-csv-file ./waterwaymap.org_ends_stats.csv --ends-csv-only-largest-n 1000 --ends-csv-min-length-m 50e3 \
		--upstreams tmp.planet-upstreams.csv --upstreams-min-upstream-m 1000 \
		--grouped-waterways tmp.planet-grouped-waterways.geojson \
		--relation-tags-overwrite --relation-tags-role main_stream \
		--longest-source-mouth tmp.planet-longest-source-mouth.geojsons --longest-source-mouth-min-length-m 200e3 --longest-source-mouth-longest-n 1M --longest-source-mouth-only-named
	  
	mv tmp.planet-loops.geojsons planet-loops.geojsons || true
	mv tmp.planet-ends.geojsons planet-ends.geojsons || true
	mv tmp.planet-grouped-ends.geojsons planet-grouped-ends.geojsons || true
	mv tmp.planet-upstreams.csv planet-upstreams.csv || true
	mv tmp.planet-grouped-waterways.geojson planet-grouped-waterways.geojson || true
	mv tmp.planet-longest-source-mouth.geojsons planet-longest-source-mouth.geojsons || true

waterwaymap.org_ends_stats.csv.zstd: waterwaymap.org_ends_stats.csv
	qsv sort --faster --unique --numeric -s timestamp,upstream_m_rank -o ./waterwaymap.org_ends_stats.csv ./waterwaymap.org_ends_stats.csv
	zstd --quiet --force -z -k -e -19 waterwaymap.org_ends_stats.csv -o waterwaymap.org_ends_stats.csv.zst


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

planet-waterway-stream-ends.geojson: planet-waterway.osm.pbf flowing_water_wo_streams.tagfilterfunc
	rm -f tmp.$@
	osm-lump-ways-down -i ./planet-waterway.osm.pbf --ends tmp.$@ -F @flowing_water_wo_streams.tagfilterfunc --ends-membership waterway=stream --flow-split-equally
	rm -f $@
	ogr2ogr $@ tmp.$@ -where '"is_in:waterway=stream"'

planet-unnamed-big-ends.geojson: planet-ends.geojsons
	rm -f tmp.$@
	ogr2ogr tmp.$@ $< -where '"tag:name" is null and  upstream_m >= 1000000'
	mv tmp.$@ $@

planet-upstreams.csv.zst: planet-upstreams.csv
	rm -f tmp.$@
	# Yes zstd compression level 1 appears to be very effective, with better
	# compression ratio
	cat $< | xsv select end_nid,from_upstream_m,geom | zstd --threads=0 -1 > tmp.$@
	mv tmp.$@ $@

planet-grouped-ends.geojsons.zst: planet-grouped-ends.geojsons
	rm -f tmp.$@
	zstd -T0 -k -f -8 -o tmp.$@ planet-grouped-ends.geojsons
	mv tmp.$@ $@


planet-ditch-loops.geojson ./upload_to_cloudflare/waterwaymap.org_ditch_loops_stats.csv: planet-waterway.osm.pbf
	rm -rf tmp.planet-ditch-loops.geojson
	osm-lump-ways-down -i ./planet-waterway.osm.pbf -f waterway=ditch --loops-csv-stats-file ./upload_to_cloudflare/waterwaymap.org_ditch_loops_stats.csv --loops tmp.planet-ditch-loops.geojson
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
		--temporary-directory=$(PWD) \
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
		--temporary-directory=$(PWD) \
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
		-y upstream_m -y nid -y tag:name \
		-l ends \
		--no-progress-indicator \
		--temporary-directory=$(PWD) \
		-o tmp.$@ $<
	mv tmp.$@ $@

planet-ends.geojsons.gz: planet-ends.geojsons
	rm -fv $@
	gzip -k -9 $<

planet-grouped-ends.pmtiles: planet-grouped-ends-z0-3.mbtiles planet-grouped-ends-z4-7.mbtiles planet-grouped-ends-z8-.mbtiles
	rm -f tmp.$@
	tile-join --no-tile-size-limit -o tmp.$@ $^
	mv tmp.$@ $@

planet-grouped-ends-z8-.mbtiles: planet-grouped-ends.geojsons
	rm -fv tmp.$@
	timeout 8h tippecanoe \
		-Z8 -zg \
		-n "WaterwayMap.org Upstream" \
		-N "Generated on $(shell date -I) from OSM data with $(shell osm-lump-ways-down --version)" \
		-A "© OpenStreetMap. Open Data under ODbL. https://osm.org/copyright" \
		--simplification=8 --no-simplification-of-shared-nodes --simplification-at-maximum-zoom=2 \
		-r1 \
		-y end_nid -y end_upstream_m -y avg_upstream_m \
		--reorder --coalesce \
		--no-feature-limit --maximum-tile-bytes $(shell units -t 2MiB bytes) \
		--extend-zooms-if-still-dropping \
		--drop-fraction-as-needed \
		--no-progress-indicator \
		--temporary-directory=$(PWD) \
		-l upstreams \
		-o tmp.$@ $<
	mv tmp.$@ $@

planet-grouped-ends-z0-3.mbtiles: planet-grouped-ends.geojsons
	rm -fv tmp.$@
	timeout 8h tippecanoe \
		-Z0 -z3 \
		-j '{"upstreams": [ ">=", "avg_upstream_m", 2000000 ] }' \
		-n "WaterwayMap.org Upstream" \
		-N "Generated on $(shell date -I) from OSM data with $(shell osm-lump-ways-down --version)" \
		-A "© OpenStreetMap. Open Data under ODbL. https://osm.org/copyright" \
		-r1 \
		-y end_nid -y end_upstream_m -y avg_upstream_m \
		--drop-fraction-as-needed \
		--no-progress-indicator \
		--temporary-directory=$(PWD) \
		-l upstreams \
		-o tmp.$@ $<
	mv tmp.$@ $@

planet-grouped-ends-z4-7.mbtiles: planet-grouped-ends.geojsons
	rm -fv tmp.$@
	timeout 8h tippecanoe \
		-Z4 -z7 \
		-j '{"upstreams": [ ">=", "avg_upstream_m", 100000 ] }' \
		-n "WaterwayMap.org Upstream" \
		-N "Generated on $(shell date -I) from OSM data with $(shell osm-lump-ways-down --version)" \
		-A "© OpenStreetMap. Open Data under ODbL. https://osm.org/copyright" \
		--simplification=8 --no-simplification-of-shared-nodes --simplification-at-maximum-zoom=2 \
		-r1 \
		-y end_nid -y end_upstream_m -y avg_upstream_m \
		--no-feature-limit --maximum-tile-bytes $(shell units -t 1.5MiB bytes) \
		--drop-fraction-as-needed \
		--no-progress-indicator \
		--temporary-directory=$(PWD) \
		-l upstreams \
		-o tmp.$@ $<
	mv tmp.$@ $@


planet-upstreams.gpkg: planet-upstreams.csv
	ogr2ogr $@ $< -lco SPATIAL_INDEX=yes -gt unlimited -select end_nid,from_upstream_m  -oo GEOM_POSSIBLE_NAMES=geom
	#ogr2ogr $@ $< -lco SPATIAL_INDEX=no -condif OGR_SQLITE_SYNCHRONOUS=off -oo OGR_SQLITE_CACHE=512 -gt unlimited -select end_nid,from_upstream_m 
	sqlite3 $@ "create index if not exists \"planet-upstreams_end_nid\" on \"planet-upstreams\" (end_nid);"
	sqlite3 $@ "create index if not exists \"planet-upstreams_from_upstream_m\" on \"planet-upstreams\" (from_upstream_m);"

planet-upstreams-%.fgb: planet-upstreams.gpkg
	ogr2ogr $@ $< -nlt LINESTRING -explodecollections -sql "select end_nid, from_upstream_m - mod(from_upstream_m, $*) as from_upstream_m_1, ST_linemerge(st_union(geom)) from \"planet-upstreams\" where from_upstream_m >= $* group by end_nid, from_upstream_m_1;"

planet-upstreams-%.pmtiles: planet-upstreams-%.fgb
	tippecanoe -l wideupstreams -T end_nid:int --force --drop-fraction-as-needed  --no-feature-limit -zg -at -ae -o $@ $<

%.fgb: %.geojsons
	ogr2ogr $@ $<

planet-upstreams.pmtiles: planet-upstreams-10000.fgb
	tippecanoe -l wideupstreams -T end_nid:int --force --drop-fraction-as-needed  --no-feature-limit -zg -at -ae -o $@ $<

planet-grouped-waterways.gpkg: planet-grouped-waterways.geojson
	rm -f tmp.$@
	ogr2ogr tmp.$@ $< -oo ARRAY_AS_STRING=YES
	sqlite3 tmp.$@ 'create index name on "planet-grouped-waterways" (tag_group_value);'
	sqlite3 tmp.$@ 'create index length on "planet-grouped-waterways" (length_m);'
	mv tmp.$@ $@

planet-grouped-waterways.spatialite: planet-grouped-waterways.geojson
	rm -f tmp.$@
	ogr2ogr -f SQLite -dsco SPATIALITE=yes tmp.$@ $< -nlt MULTILINESTRING -unsetFid -oo ARRAY_AS_STRING=YES -lco SRID=4326 -lco GEOMETRY_NAME=geom
	sqlite3 tmp.$@ 'create index name on planet_grouped_waterways (tag_group_value);'
	sqlite3 tmp.$@ 'create index length on planet_grouped_waterways (length_m);'
	mv tmp.$@ $@

planet-grouped-waterways.pgimported: planet-grouped-waterways.geojson
	rm -f tmp.$@
	psql -Xe -c "drop table if exists planet_grouped_waterways cascade;"
	psql -Xe -c "drop table if exists ww_rank_in_a cascade;"
	ogr2ogr -f PostgreSQL PG: $< -nlt MULTILINESTRING -unsetFid -oo ARRAY_AS_STRING=YES -t_srs EPSG:4326 -lco GEOMETRY_NAME=geom
	psql -Xe -c 'create index name on planet_grouped_waterways (tag_group_value);'
	psql -Xe -c 'create index length on planet_grouped_waterways (length_m);'
	touch $@

admins.osm.pbf: planet-waterway.osm.pbf
	rm -f tmp.$@
	osmium tags-filter $< -o tmp.$@ admin_level=1,2,3,4,5,6
	mv tmp.$@ $@

admins.geojsonseq: admins.osm.pbf
	rm -f tmp.$@
	osmium export $< -o tmp.$@
	mv tmp.$@ $@

admins.gpkg: admins.geojsonseq
	rm -f tmp.$@
	ogr2ogr tmp.$@ $< -select name,admin_level -where "name IS NOT NULL"

admins.spatialite: admins.geojsonseq
	rm -f tmp.$@
	ogr2ogr -f SQLite -dsco SPATIALITE=yes tmp.$@ $< -select name,"name:en",admin_level -where "name IS NOT NULL AND admin_level IS NOT NULL AND OGR_GEOMETRY IN ('Polygon','MultiPolygon')" -nlt MULTIPOLYGON -unsetFid -lco SRID=4326 -lco GEOMETRY_NAME=geom
	mv tmp.$@ $@

admins.pgimported: admins.geojsonseq
	ogr2ogr -f PostgreSQL PG: $< -select name,"name:en",admin_level -where "name IS NOT NULL AND admin_level IS NOT NULL AND OGR_GEOMETRY IN ('Polygon','MultiPolygon')" -nlt MULTIPOLYGON -unsetFid -t_srs EPSG:4326 -lco GEOMETRY_NAME=geom
	touch $@

riversite_input_data.gpkg: planet-grouped-waterways.gpkg admins.geojsonseq
	rm -f tmp.$@
	cp planet-grouped-waterways.gpkg tmp.$@
	ogr2ogr tmp.$@ admins.geojsonseq -select name,"name:en",admin_level -where "name IS NOT NULL AND admin_level IS NOT NULL AND OGR_GEOMETRY IN ('Polygon','MultiPolygon')" -nlt MULTIPOLYGON  -nln admins -update -unsetFid -lco SPATIAL_INDEX=yes
	sqlite3 tmp.$@ 'create index admins__admin_level on admins (admin_level);'
	sqlite3 tmp.$@ 'create index admins__name on admins (name);'
	mv tmp.$@ $@

riversite_input_data.spatialite: planet-grouped-waterways.spatialite admins.geojsonseq
	rm -f tmp.$@
	cp planet-grouped-waterways.spatialite tmp.$@
	ogr2ogr -f SQLite -dsco SPATIALITE=yes tmp.$@ admins.geojsonseq -select name,"name:en",admin_level -where "name IS NOT NULL AND OGR_GEOMETRY IN ('Polygon','MultiPolygon')" -nlt MULTIPOLYGON -unsetFid -lco SRID=4326 -lco GEOMETRY_NAME=geom -update
	spatialite tmp.$@ '.read riversite_input_data_setup.sql'
	mv tmp.$@ $@

riversite_input_data.pgimported: ne_10m_admin_0_countries_iso.pgimported ne_10m_admin_1_states_provinces.pgimported planet-grouped-waterways.pgimported
	psql -X -f riversite_input_data_setup.sql
	touch $@

rivers_html.db: riversite_input_data.pgimported wwm-river
	rm -rf tmp.$@
	./wwm-river --templates /home/amanda/personal/waterwaymap.org-river/templates/ --static /home/amanda/personal/waterwaymap.org-river/static/ --prefix /river/ -e "data_timestamp=$(shell jq -Mr <upload_to_cloudflare/tilesets.json .data_timestamp)" -o tmp.$@
	mv tmp.$@ $@

ne_10m_admin_0_countries_iso.zip:
	curl -A "waterwaymap.org" -LO https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_admin_0_countries_iso.zip
ne_10m_admin_1_states_provinces.zip:
	curl -A "waterwaymap.org" -LO https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_admin_1_states_provinces.zip
ne_10m_admin_0_countries_iso/ne_10m_admin_0_countries_iso.shp: ne_10m_admin_1_states_provinces.zip
	aunpack $<
	touch $@
ne_10m_admin_1_states_provinces/ne_10m_admin_1_states_provinces.shp: ne_10m_admin_1_states_provinces.zip
	aunpack $<
	touch $@

ne_10m_admin_0_countries_iso.pgimported: ne_10m_admin_0_countries_iso/ne_10m_admin_0_countries_iso.shp
	ogr2ogr -f PostgreSQL PG: $< -sql "select NAME,iso_a2_eh as iso, null as parent_iso, 0 as level from ne_10m_admin_0_countries_iso" -nlt MULTIPOLYGON -unsetFid -t_srs EPSG:4326 -lco GEOMETRY_NAME=geom -nln admins
	touch $@

ne_10m_admin_1_states_provinces.pgimported: ne_10m_admin_1_states_provinces/ne_10m_admin_1_states_provinces.shp ne_10m_admin_0_countries_iso.pgimported
	ogr2ogr -f PostgreSQL PG: $< -sql "select NAME,iso_3166_2 as iso, iso_a2 as parent_iso, 1 as level from ne_10m_admin_1_states_provinces" -nlt MULTIPOLYGON -unsetFid -t_srs EPSG:4326 -nln admins -append
	touch $@

ne_10m_admin_delete:
	psql -X -c "DROP TABLE IF EXISTS admins0 CASCADE;"
	psql -X -c "DROP TABLE IF EXISTS admins1 CASCADE;"
	psql -X -c "DROP TABLE IF EXISTS admins CASCADE;"
	rm -f ne_10m_admin_0_countries_iso.pgimported
	rm -f ne_10m_admin_1_states_provinces.pgimported
