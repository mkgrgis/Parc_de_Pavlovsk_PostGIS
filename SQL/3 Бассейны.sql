CREATE TABLE "Павловский парк"."Расчётные стоки" (
    id smallserial NOT NULL,
    osm_id bigint NOT NULL,
    osm_type varchar(16) NOT NULL,
    "Название бассейна" varchar NULL
);
ALTER TABLE "Павловский парк"."Расчётные стоки" ADD CONSTRAINT "Расчётные_стоки_pk" PRIMARY KEY (id);
COMMENT ON TABLE "Павловский парк"."Расчётные стоки" IS 'Конечные точки, для которых расчитывается бассейн водотоков';

-- Заполняем начальные точки
INSERT INTO "Павловский парк"."Расчётные стоки" (id, osm_id, osm_type, "Название бассейна") VALUES(1, 45600782,  'way', 'Славянка все');
INSERT INTO "Павловский парк"."Расчётные стоки" (id, osm_id, osm_type, "Название бассейна") VALUES(2, 860606686, 'way', 'ручей Руинного каскада');
INSERT INTO "Павловский парк"."Расчётные стоки" (id, osm_id, osm_type, "Название бассейна") VALUES(3, 311755122, 'way', 'БЗ Краснодолинный ручей');
INSERT INTO "Павловский парк"."Расчётные стоки" (id, osm_id, osm_type, "Название бассейна") VALUES(4, 315726043, 'way', 'ББ Ручей Белой Берёзы');
INSERT INTO "Павловский парк"."Расчётные стоки" (id, osm_id, osm_type, "Название бассейна") VALUES(5, 137984406, 'way', 'ББ Большой восточный дренаж Белой Берёзы');
INSERT INTO "Павловский парк"."Расчётные стоки" (id, osm_id, osm_type, "Название бассейна") VALUES(6, 93591935,  'way', 'ББ Большой дренаж Волшебного поля');
INSERT INTO "Павловский парк"."Расчётные стоки" (id, osm_id, osm_type, "Название бассейна") VALUES(7, 874567225, 'way', 'Мавзолейный ручей');
INSERT INTO "Павловский парк"."Расчётные стоки" (id, osm_id, osm_type, "Название бассейна") VALUES(8, 875293481, 'way', 'БЗ Южный водоток Долины прудов');

INSERT INTO "Павловский парк"."Расчётные стоки" (id, osm_id, osm_type, "Название бассейна") VALUES(9, 149099013, 'way', 'БЗ ручей Вокзальных прудов');
INSERT INTO "Павловский парк"."Расчётные стоки" (id, osm_id, osm_type, "Название бассейна") VALUES(10, 989802564, 'way', 'БЗ перелив Фонтанного пруда');
INSERT INTO "Павловский парк"."Расчётные стоки" (id, osm_id, osm_type, "Название бассейна") VALUES(11, 311760730, 'way', 'БЗ Большой каскад');
INSERT INTO "Павловский парк"."Расчётные стоки" (id, osm_id, osm_type, "Название бассейна") VALUES(12, 845847454, 'way', 'БЗ Альтернатива Старошалейного или Круглозального');
INSERT INTO "Павловский парк"."Расчётные стоки" (id, osm_id, osm_type, "Название бассейна") VALUES(13, 145893440, 'way', 'ББ Южное Краснодолинное болотце');
INSERT INTO "Павловский парк"."Расчётные стоки" (id, osm_id, osm_type, "Название бассейна") VALUES(14, 1274655355, 'way', 'ББ Овражек у Нововесьинской дороги');
INSERT INTO "Павловский парк"."Расчётные стоки" (id, osm_id, osm_type, "Название бассейна") VALUES(15, 1056508708, 'way', 'ББ Мавзолейный ручей в Белой Берёзе');
INSERT INTO "Павловский парк"."Расчётные стоки" (id, osm_id, osm_type, "Название бассейна") VALUES(16, 407877612, 'way', 'ББ Розовопавильонный дренаж');

drop table "Павловский парк"."Бассейны" cascade;

create table "Павловский парк"."Бассейны" as
select 0::smallint "bas_id", "osm_type", "osm_id", geom "Бассейн", geom "ini", 0::int2 "Шаг"
  from "Павловский парк"."Водотоки линейные"
 where false ;
ALTER TABLE "Павловский парк"."Бассейны" ADD CONSTRAINT "Бассейны_unique" UNIQUE (osm_type,osm_id);
ALTER TABLE "Павловский парк"."Бассейны" ADD CONSTRAINT "Бассейны_pk" PRIMARY KEY (bas_id);
ALTER TABLE "Павловский парк"."Бассейны" ADD CONSTRAINT "Бассейны_Расчётные_стоки_FK" FOREIGN KEY (bas_id) REFERENCES "Павловский парк"."Расчётные стоки"(id);

drop table "Павловский парк"."Бассейны использованы" cascade;

create table "Павловский парк"."Бассейны использованы" (
"bas_id" smallint not null,
"osm_type" varchar(16) not null,
"osm_id" int8 not null,
"Шаг" smallint null
);
ALTER TABLE "Павловский парк"."Бассейны использованы" ADD CONSTRAINT "Бассейны_использованы_pk" PRIMARY KEY (bas_id,osm_type,osm_id);

create view "Павловский парк"."Бассейны geoJSON" as 
 select st_asgeojson(b."Бассейн") "GeoJSON",  r."Название бассейна" || ' ' || '№' || r.id "Название"
   from "Павловский парк"."Бассейны" b
   join "Павловский парк"."Расчётные стоки" r
   using (osm_id, osm_type);

truncate table "Павловский парк"."Бассейны";
truncate table "Павловский парк"."Бассейны использованы";

drop view "Павловский парк"."Бассейны+1" cascade;
create view "Павловский парк"."Бассейны+1" as
with u as
(select st_union(b."Бассейн", o.geom) "Бассейн",
       b.bas_id,       
       o.osm_type,
       o.osm_id,
       o.tags,
       o.geom,
       o.geom_type,
       b."Шаг"
  from "Павловский парк"."Бассейны" b
 inner join "Павловский парк"."OSM ∀" o
    on (
       ( o.geom_type = 'ST_LineString'
   and o.tags ->> 'waterway' is not null
   and o.tags ->> 'bridge' is null
   and o.tags ->> 'tunnel' is null   
   and st_intersects(o.geom, b."Бассейн")
   and not st_intersects(st_startpoint(o.geom), b."Бассейн")
   and not st_intersects(o.geom, b.ini )
       )
    or ( o.geom_type = 'ST_LineString'
   and o.tags ->> 'waterway' is not null
   and (o.tags ->> 'bridge' is not null -- Акведуки
    or o.tags ->> 'tunnel' is not null )-- Подземные водоводы
   and st_intersects(st_endpoint(o.geom), b."Бассейн")
       )
    or ( o.geom_type != 'ST_LineString' -- Водные глади
   and o.tags ->> 'natural' = 'water'
   and st_intersects(o.geom, b."Бассейн")
   and not st_intersects(o.geom, b."ini")       
       )
       )
   and (o.osm_type, o.osm_id) != (b.osm_type, b.osm_id)
   )
  select "Бассейн", u."Шаг", bas_id, osm_type, osm_id, u.tags, u.geom, u.geom_type, i.bas_id "Новый" 
  from u
  left join "Павловский парк"."Бассейны использованы" i
  using (bas_id, osm_type, osm_id)    
/*
  where (b.bas_id, o.osm_id, o.osm_type) not in 
  (select bas_id, osm_type, osm_id from "Павловский парк"."Бассейны использованы"       
  ) */;
                                    
-- Первичное заполнение
insert into "Павловский парк"."Бассейны" ("bas_id", "osm_type", "osm_id", "Бассейн", "ini", "Шаг")
with b as (
select r.id "bas_id",
       "osm_id",
       "osm_type",
       geom "Бассейн",
       (st_dump(geom)).geom "ini",       
       o.geom_type
  from "Павловский парк"."Расчётные стоки" r
  join "Павловский парк"."OSM ∀" o
using ("osm_type", "osm_id") 
),
ini as (
select "bas_id",
       "osm_type",
       "osm_id",       
       "Бассейн",
       case when st_geometrytype("ini") = 'ST_LineString'
            then st_endpoint("ini")
            when st_geometrytype("ini") = 'ST_Point'
            then "ini"
            else st_boundary("ini") 
       end "ini"       
  from b
 )
select "bas_id",
       "osm_type",
       "osm_id",       
       st_union("Бассейн"),
       st_union("ini"),       
       0::smallint "Шаг"
  from ini
  -- where bas_id = 15 
  group by "bas_id", "osm_type", "osm_id", "Шаг"
  ;
                                 
-- Шаговая итерация присоединения к бассейну
  
 MERGE INTO "Павловский парк"."Бассейны" b
 USING ( select ST_Union(geom) "Бассейн+", "bas_id"
           from "Павловский парк"."Бассейны+1"
          -- where "Новый" 
          group by bas_id ) v
    ON v.bas_id = b.bas_id
   and not ST_Equals(b."Бассейн", ST_Union(b."Бассейн", v."Бассейн+"))
  WHEN MATCHED then
UPDATE SET "Бассейн" = ST_Union(b."Бассейн", v."Бассейн+"), "Шаг" = "Шаг" + 1;
                
INSERT INTO "Павловский парк"."Бассейны использованы"
       (bas_id, osm_type, osm_id, "Шаг")
select bas_id, osm_type, osm_id, "Шаг"
  from "Павловский парк"."Бассейны+1" where (bas_id, osm_type, osm_id) not in 
  (select bas_id, osm_type, osm_id from "Павловский парк"."Бассейны использованы")
--returning *
;
