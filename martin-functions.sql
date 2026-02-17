CREATE INDEX IF NOT EXISTS planet_grouped_waterways__max_upstream_m ON planet_grouped_waterways (max_upstream_m);

ALTER TABLE planet_grouped_waterways ADD COLUMN IF NOT EXISTS geom_3857 geometry(MultiLineString, 3857) GENERATED ALWAYS AS (ST_Transform(geom, 3857)) STORED;

CREATE INDEX IF NOT EXISTS planet_grouped_waterways__geom_3857 ON planet_grouped_waterways USING GIST (geom_3857) WHERE tag_group_value IS NOT NULL;


CREATE OR REPLACE
    FUNCTION water_lines_labels(z integer, x integer, y integer)
    RETURNS bytea AS $$
DECLARE
  mvt bytea;
BEGIN
  SELECT INTO mvt ST_AsMVT(tile, name=> 'water_lines_labels', extent=> 4096, geom_name => 'geom', feature_id_name => 'id') FROM (
    with t1 AS (
      SELECT
        ST_AsMVTGeom(
            ST_Simplify(geom_3857, 8),
            ST_TileEnvelope(z, x, y),
            extendt => 4096, buffer => 256, clip_geom => true) AS geom,
        ogc_fid as id,
        max_upstream_m,
        'river' as kind,
        tag_group_value as name,
        NULL as name_en,
        NULL as name_de,
        NULL as bridge,
        NULL as tunnel
      FROM planet_grouped_waterways
      WHERE geom_3857 && ST_TileEnvelope(z, x, y)
        AND tag_group_value IS NOT NULL
        AND max_upstream_m > 200
      ORDER by max_upstream_m DESC
    )
    SELECT * from t1 where geom is not null limit 200
  ) as tile;

  RETURN mvt;
END
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

DO $do$ BEGIN
    EXECUTE 'COMMENT ON FUNCTION water_lines_labels  IS $tj$' || $$
      {
        "description":"Waterway lines",
        "vector_layers": [
          {
            "id": "water_lines_labels",
            "fields":{
              "max_upstream_m":"int4",
              "kind":"text",
              "name":"text",
              "name_en":"text",
              "name_de":"text",
              "bridge":"text",
              "tunnel":"text"
            }
          }
        ]
      }
      $$::json || '$tj$';
END $do$;


