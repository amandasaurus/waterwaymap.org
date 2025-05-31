set client_min_messages = warning;    -- don't NOTICE if an index (etc) already exists.
create index if not exists admins__level on admins (level);
create index if not exists admins__name on admins (name);
delete from admins where level IS NULL OR name IS NULL;
create index if not exists admins__name on admins (name);

-- merge things with same name & iso
create temp table new_admins as select min(ogc_fid) as ogc_fid, name, iso, min(parent_iso) as parent_iso, level, ST_Union(geom) as geom from admins group by (name, iso, level);
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

drop table if exists ww_in_admin_ranks;
create table ww_in_admin_ranks (
  a_ogc_fid integer references admins(ogc_fid),
  ww_ogc_fid integer references planet_grouped_waterways(ogc_fid),
  ww_rank_in_a bigint
);
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

create index if not exists ww_rank_in_a__a_ogc_fid on ww_in_admin_ranks (a_ogc_fid);
create index if not exists ww_rank_in_a__ww_ogc_fid on ww_in_admin_ranks (ww_ogc_fid);
