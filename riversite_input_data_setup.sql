create index if not exists admins__level on admins (level);
create index if not exists admins__name on admins (name);
delete from admins where level IS NULL OR name IS NULL;

create index if not exists planet_grouped_waterways__length_m on planet_grouped_waterways (length_m);
create index if not exists planet_grouped_waterways__name on planet_grouped_waterways (tag_group_value);

drop table if exists ww_rank_in_a;
create table ww_in_admin_ranks AS 
  select a.ogc_fid as a_ogc_fid, ww.ogc_fid as ww_ogc_fid, RANK() OVER (partition by a.ogc_fid order by ww.length_m desc) as ww_rank_in_a from planet_grouped_waterways as ww join admins as a on ST_Intersects(a.geom, ww.geom);

create index if not exists ww_rank_in_a__a_ogc_fid on ww_in_admin_ranks (a_ogc_fid);
create index if not exists ww_rank_in_a__ww_ogc_fid on ww_in_admin_ranks (ww_ogc_fid);
