set client_min_messages = warning;    -- don't NOTICE if an index (etc) already exists.
create index if not exists admins__level on admins (level);
create index if not exists admins__name on admins (name);
delete from admins where level IS NULL OR name IS NULL;

-- merge things with same name & iso
create temp table new_admins as select min(ogc_fid) as ogc_fid, name, iso, min(parent_iso) as parent_iso, min(level) as level, ST_Multi(ST_Union(geom)) as geom from admins group by (name, iso);
truncate table admins cascade;
insert into admins select * from new_admins;
drop table new_admins;
alter table admins add constraint uniq_name_iso UNIQUE(name, iso);

alter table admins add column if not exists url_path varchar(45) unique;
update admins set url_path = iso || '-' || name;

create index if not exists planet_grouped_waterways__length_m on planet_grouped_waterways (length_m);
create index if not exists planet_grouped_waterways__name on planet_grouped_waterways (tag_group_value);
alter table planet_grouped_waterways add constraint uniq_name_min_nid UNIQUE(tag_group_value, min_nid);
alter table planet_grouped_waterways add column url_path text unique;
update planet_grouped_waterways set url_path = coalesce(tag_group_value, 'unnamed') || ' ' || lpad(min_nid::text, 12, '0');

create table IF NOT EXISTS ww_in_admin_ranks (
  a_ogc_fid integer references admins(ogc_fid),
  ww_ogc_fid integer references planet_grouped_waterways(ogc_fid),
  ww_rank_in_a bigint
);
TRUNCATE TABLE ww_in_admin_ranks;
insert into ww_in_admin_ranks
  select
    a.ogc_fid as a_ogc_fid,
    ww.ogc_fid as ww_ogc_fid,
    RANK() OVER (partition by a.ogc_fid order by ww.length_m desc) as ww_rank_in_a
  FROM
    planet_grouped_waterways as ww
    join admins as a
    on ST_Intersects(a.geom, ww.geom)
  ;

create index if not exists ww_rank_in_a__ww_ogc_fid on ww_in_admin_ranks (ww_ogc_fid);
create index if not exists ww_rank_in_a__a_rank on ww_in_admin_ranks (a_ogc_fid, ww_rank_in_a);


drop view if exists ww_a;
-- Columns created with:
-- select string_agg(table_name||'.'||column_name||' as ' ||  case when table_name = 'planet_grouped_waterways' then 'ww_' when table_name = 'admins' then 'a_' else '___' end ||column_name, ', ' order by table_name) from information_schema.columns where table_name IN ('admins', 'planet_grouped_waterways');
create view ww_a AS
  select
  admins.ogc_fid as a_ogc_fid, admins.level as a_level, admins.url_path as a_url_path, admins.name as a_name, admins.iso as a_iso, admins.parent_iso as a_parent_iso, admins.geom as a_geom, planet_grouped_waterways.stream_level as ww_stream_level, planet_grouped_waterways.stream_level_code as ww_stream_level_code, planet_grouped_waterways.internal_groupid as ww_internal_groupid, planet_grouped_waterways.terminal_distributaries as ww_terminal_distributaries, planet_grouped_waterways.tributaries as ww_tributaries, planet_grouped_waterways.geom as ww_geom, planet_grouped_waterways.stream_level_code_str as ww_stream_level_code_str, planet_grouped_waterways.tag_group_value as ww_tag_group_value, planet_grouped_waterways.ogc_fid as ww_ogc_fid, planet_grouped_waterways.url_path as ww_url_path, planet_grouped_waterways.branching_distributaries as ww_branching_distributaries, planet_grouped_waterways.distributaries_sea as ww_distributaries_sea, planet_grouped_waterways.length_m as ww_length_m, planet_grouped_waterways.min_nid as ww_min_nid, planet_grouped_waterways.parent_rivers as ww_parent_rivers, planet_grouped_waterways.side_channels as ww_side_channels,
  ww_in_admin_ranks.ww_rank_in_a
  from planet_grouped_waterways join ww_in_admin_ranks ON (planet_grouped_waterways.ogc_fid = ww_in_admin_ranks.ww_ogc_fid) join admins on (admins.ogc_fid = ww_in_admin_ranks.a_ogc_fid);
  
