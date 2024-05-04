create table "Павловский парк"."Бассейны" as
select "osm_id", "osm_type", geometry "Бассейн"
  from "Павловский парк"."Водотоки линейные";
  
create table "Павловский парк"."Бассейны буфер использования"
("0_osm_id" int8, "0_osm_type" varchar(16), "osm_id" int8, "osm_type" varchar(16));

truncate table "Павловский парк"."Бассейны буфер использования";
truncate table "Павловский парк"."Бассейны";

create or replace view "Павловский парк"."Бассейны iter" as
select st_union(b."Бассейн", r.geom) "Бассейн",
       b.osm_id "0_osm_id",
       b.osm_type "0_osm_type",
       r.*
  from "Павловский парк"."Бассейны" b
 inner join "Павловский парк"."OSM ∀" r
    on (
       ( r.geom_type = 'ST_LineString'
   and r.tags ->> 'waterway' is not null
   and r.tags ->> 'bridge' is null
   and st_intersects(r.geom, b."Бассейн")
   and not st_intersects(st_startpoint(r.geom), b."Бассейн")
   and not st_intersects(r.geom, b.ini )
       )
    or ( r.geom_type = 'ST_LineString'
   and r.tags ->> 'waterway' is not null
   and r.tags ->> 'bridge' is not null
   and st_intersects(st_endpoint(r.geom), b."Бассейн")
       )
    or ( r.geom_type != 'ST_LineString'
   and r.tags ->> 'natural' = 'water'
   and st_intersects(r.geom, b."Бассейн")
   and not st_intersects(r.geom, b."ini")       
       )
       )
   and (r.osm_id, r.osm_type) != (b.osm_id, b.osm_type)
   and (r.osm_id, r.osm_type ) not in (select osm_id, osm_type
                                         from "Павловский парк"."Бассейны буфер использования" bi
                                        where (bi."0_osm_id", bi."0_osm_type") != (b.osm_id, b.osm_type) );

insert into "Павловский парк"."Бассейны"
-- create table "Павловский парк"."Бассейны" as 
with b as (
select "osm_id",
       "osm_type",
       geom "Бассейн",
       (st_dump(geom)).geom "ini",
       l.tags ->> 'name' "Название",
       0::smallint "Шаг",
       l.geom_type
  from "Павловский парк"."OSM ∀" l
 where l.osm_id in (
    311755122,
    989802564,
    149099013,
    93591935,
    311760730,
    860606686,
    874567225,
    315726043,
    93591935,
    845847454,
    137984406,
    1274655355,
    145893440)
),
b1 as (
select "osm_id",
       "osm_type",
       "Бассейн",
       case when st_geometrytype("ini") = 'ST_LineString'
            then st_endpoint("ini")
            when st_geometrytype("ini") = 'ST_Point'
            then "ini"
            else st_boundary("ini") 
       end "ini",
       "Название",
       "Шаг"
  from b
 )
select "osm_id",
       "osm_type",
       st_union("Бассейн"),
       st_union("ini"),
       "Название",
       "Шаг"
  from b1
  group by "osm_id", "osm_type", "Название", "Шаг"
  ;
                                 
 MERGE INTO "Павловский парк"."Бассейны" b
 USING ( select ST_Union("Бассейн") "Бассейн", "0_osm_id", "0_osm_type"
           from "Павловский парк"."Бассейны iter"
          group by "0_osm_id", "0_osm_type" ) v
    ON (v."0_osm_id", v."0_osm_type" ) = (b.osm_id, b.osm_type)
   and not ST_Equals(b."Бассейн", v."Бассейн")
  WHEN MATCHED then
UPDATE SET "Бассейн" = ST_Union(b."Бассейн", v."Бассейн"), "Шаг" = "Шаг" + 1;
                
INSERT INTO "Павловский парк"."Бассейны буфер использования"
       ("0_osm_id", "0_osm_type", osm_id, osm_type)
select distinct "0_osm_id", "0_osm_type", osm_id, osm_type
  from "Павловский парк"."Бассейны iter"
  where ("0_osm_id", "0_osm_type", osm_id, osm_type) not in 
  (select "0_osm_id", "0_osm_type", osm_id, osm_type 
     from "Павловский парк"."Бассейны буфер использования")
--returning * ;

create view "Бассейны geoJSON" as 
 select st_asgeojson(b."Бассейн") "GeoJSON", b.*
   from "Павловский парк"."Бассейны" b;
