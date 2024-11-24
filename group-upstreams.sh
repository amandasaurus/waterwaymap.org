#! /bin/bash -x

INPUT=${1:-upstreams.geojsons}
PREFIX=${INPUT%%.geojsons}

if [ "$INPUT" -nt "$PREFIX.gpkg" ] ; then
  time ogr2ogr "$PREFIX.gpkg" "$INPUT" -lco SPATIAL_INDEX=no -oo OGR_SQLITE_SYNCHRONOUS=off -oo OGR_SQLITE_CACHE=512 -gt unlimited -select end_nid,from_upstream_m
fi
sqlite3 "$PREFIX.gpkg" "create index if not exists \"${PREFIX}_end_nid\" on \"$PREFIX\" (end_nid);"
sqlite3 "$PREFIX.gpkg" "create index if not exists \"${PREFIX}_from_upstream_m\" on \"$PREFIX\" (from_upstream_m);"

if [ "${PREFIX}.gpkg" -nt "$PREFIX." ] ; then
  ogr2ogr "$PREFIX.fgb" "$INPUT" -select end_nid,from_upstream_m
fi

for N in {3..6} ; do
  ogr2ogr "${PREFIX}_1e${N}.fgb" "$PREFIX.gpkg" -nlt LINESTRING -explodecollections -sql "select end_nid, from_upstream_m - mod(from_upstream_m, 1e${N}) as from_upstream_m_1, ST_linemerge(st_union(geom)) from \"$PREFIX\" where from_upstream_m >= 1e${N} group by end_nid, from_upstream_m_1;" &
done

wait
