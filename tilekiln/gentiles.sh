#! /bin/sh
set -o errexit
cd "$(dirname "$0")" || exit 1
psql -c "drop table if exists loops;"
ogr2ogr -f PostgreSQL PG:"" ~/osm/waterwaymap.org/global/planet-loops.geojsons -lco OVERWRITE=YES -s_srs epsg:4326 -t_srs epsg:3857 -lco GEOMETRY_NAME=way -nln loops -select num_nodes,root_nid -unsetFid
psql -c "alter table loops drop column ogc_fid;"
psql -c "alter table loops add column length_m float8;"
psql -c "update loops set length_m = round(st_length(st_transform(way, 4326)::geography)::real)::float8;"
rm -f loops.mbtiles loops.pmtiles
./venv/bin/tilekiln mbtilesdump --config config.yaml --output loops.mbtiles  --maxzoom 10
pmtiles convert loops.mbtiles loops.pmtiles
du -hs ./loops.mbtiles loops.pmtiles
cp ./loops.pmtiles  ~/osm/waterwaymap.org/docs/data/planet-loops.pmtiles
