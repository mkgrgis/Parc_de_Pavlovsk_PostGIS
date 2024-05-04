-- БАЗОВОЕ ПРЕДСТАВЛЕНИЕ

CREATE OR REPLACE VIEW "Павловский парк"."Водотоки ∀"
AS SELECT osm_id,
    osm_type,
    tags,
    tags ->> 'source:direction'::text AS dir,
    tags ->> 'bridge'::text AS bridge,
    tags ->> 'intermittent'::text AS intermittent,
    tags ->> 'layer'::text AS layer,
    tags ->> 'water'::text AS water,
    tags ->> 'waterway'::text AS waterway,
    tags ->> 'tunnel'::text AS tunnel,
    tags ->> 'width'::text AS width,
    tags ->> 'natural'::text AS "natural",
    tags ->> 'name'::text AS "name",
    geom,
    geom_type
   FROM "Павловский парк"."OSM ∀" ∀ 
  WHERE (tags ->> 'waterway'::text) IS NOT NULL AND (tags ->> 'waterway'::text) <> 'dam'::text OR (tags ->> 'water'::text) IS NOT NULL OR (tags ->> 'natural'::text) = 'water'::text OR (tags ->> 'natural'::text) = 'wetland'::text;

COMMENT ON VIEW "Павловский парк"."Водотоки ∀" IS 'Все данные по водотокам в Павловском парке';

-- "Павловский парк"."Водотоки линейные" source

CREATE OR REPLACE VIEW "Павловский парк"."Водотоки линейные"
AS SELECT "∀".osm_id,
    "∀".osm_type,
    "∀".tags,
    "∀".dir,
    "∀".bridge,
    "∀".intermittent,
    "∀".layer,
    "∀".water,
    "∀".waterway,
    "∀".tunnel,
    "∀".width,
    "∀"."natural",
    "∀".geom,
    "∀".geom_type
   FROM "Павловский парк"."Водотоки ∀" "∀"
  WHERE st_geometrytype("∀".geom) = 'ST_LineString'::text;


-- "Павловский парк"."Водотоки ↦" source

CREATE OR REPLACE VIEW "Павловский парк"."Водотоки ↦"
AS SELECT st_startpoint("в".geom) AS "исток",
    "в".osm_id,
    "в".osm_type,
    "в".tags,
    "в".dir,
    "в".bridge,
    "в".intermittent,
    "в".layer,
    "в".water,
    "в".waterway,
    "в".tunnel,
    "в".width,
    "в"."natural",
    "в".geom
   FROM "Павловский парк"."Водотоки линейные" "в"
  WHERE geometrytype("в".geom) = 'LINESTRING'::text AND (("в"."natural" <> ALL (ARRAY['water'::text, 'wetland'::text])) OR "в"."natural" IS NULL);
COMMENT ON VIEW "Павловский парк"."Водотоки ↦" IS 'Точки истока всех линейных водотоков';
  
-- "Павловский парк"."Водотоки ⇥" source

CREATE OR REPLACE VIEW "Павловский парк"."Водотоки ⇥"
AS SELECT st_endpoint("в".geom) AS "⇒",
    "∀".tags,
    "в".geom,
    "в".tags AS "w tags",
    "в".osm_id,
    "в".osm_type,
    "в".dir,
    "в".bridge,
    "в".intermittent,
    "в".layer,
    "в".water,
    "в".waterway,
    "в".tunnel,
    "в".width,
    "в"."natural"
   FROM "Павловский парк"."Водотоки линейные" "в"
     LEFT JOIN "Павловский парк"."OSM ∀" "∀" ON "∀".geom = st_endpoint("в".geom) AND "∀".osm_type::text = 'node'::text
  WHERE geometrytype("в".geom) = 'LINESTRING'::text AND (("в"."natural" <> ALL (ARRAY['water'::text, 'wetland'::text])) OR "в"."natural" IS NULL);

COMMENT ON VIEW "Павловский парк"."Водотоки ⇥" IS 'Точки стока всех линейных водотоков';
  


-- "Павловский парк"."Водотоки ⇒×2" source

CREATE OR REPLACE VIEW "Павловский парк"."Водотоки ⇒×2"
AS SELECT st_intersection("т1"."⇒", "т2"."⇒") AS "2⇒",
    st_union("т1".geom, "т2".geom) AS st_union,
    "т1".tags AS t1,
    "т2".tags AS t2,
    "в".geom AS "∑"
   FROM "Павловский парк"."Водотоки ⇥" "т1"
     JOIN "Павловский парк"."Водотоки ⇥" "т2" ON st_covers("т1"."⇒", "т2"."⇒") AND "т1".osm_id > "т2".osm_id
     LEFT JOIN "Павловский парк"."Водотоки ∀" "в" ON NOT st_covers(st_endpoint("в".geom), st_intersection("т1"."⇒", "т2"."⇒")) AND st_intersects("в".geom, "т1"."⇒") AND st_intersects("в".geom, "т2"."⇒") AND "в".osm_id <> "т2".osm_id AND "в".osm_id <> "т1".osm_id
  ORDER BY "в".geom NULLS FIRST;

COMMENT ON VIEW "Павловский парк"."Водотоки ⇒×2" IS 'Точки слияния двух (и более) водотоков';


-- "Павловский парк"."Водотоки ⇒×2 ⇔ geoJSON" source

CREATE OR REPLACE VIEW "Павловский парк"."Водотоки ⇒×2 ⇔ geoJSON"
AS WITH features AS (
         SELECT json_build_object('type', 'Feature', 'geometry', st_asgeojson(r."2⇒")::json) AS feature
           FROM "Павловский парк"."Водотоки ⇒×2" r
        )
 SELECT json_build_object('type', 'FeatureCollection', 'features', json_agg(features.feature)) AS "GeoJSON"
   FROM features;

COMMENT ON VIEW "Павловский парк"."Водотоки ⇒×2 ⇔ geoJSON" IS 'Формирование файла для проверки бифуркаций';


-- "Павловский парк"."Водотоки ⇔" source

CREATE OR REPLACE VIEW "Павловский парк"."Водотоки ⇔"
AS SELECT st_intersection("и1".geom, "и2".geom) AS "∩",
    st_intersection("и1"."исток", "и2"."исток") AS "бифуркация",
    "и1".geom AS "водоток1",
    "и2".geom AS "водоток2"
   FROM "Павловский парк"."Водотоки ↦" "и1"
     JOIN "Павловский парк"."Водотоки ↦" "и2" ON st_intersects("и1"."исток", "и2"."исток") AND "и1".osm_id < "и2".osm_id;

COMMENT ON VIEW "Павловский парк"."Водотоки ⇔" IS 'Бифуркации';


-- "Павловский парк"."Водотоки ⇔ geoJSON" source

CREATE OR REPLACE VIEW "Павловский парк"."Водотоки ⇔ geoJSON"
AS WITH features AS (
         SELECT json_build_object('type', 'Feature', 'geometry', st_asgeojson(r."бифуркация")::json) AS feature
           FROM "Павловский парк"."Водотоки ⇔" r
        )
 SELECT json_build_object('type', 'FeatureCollection', 'features', json_agg(features.feature)) AS "GeoJSON"
   FROM features;

COMMENT ON VIEW "Павловский парк"."Водотоки ⇔ geoJSON" IS 'Формирование файла для проверки бифуркаций';

-- "Павловский парк"."Водотоки ∩" source

CREATE OR REPLACE VIEW "Павловский парк"."Водотоки ∩"
AS WITH "∀∩" AS (
         SELECT DISTINCT st_intersection("в0".geom, "в1".geom) AS "∩"
           FROM "Павловский парк"."Водотоки ∀" "в0"
             JOIN "Павловский парк"."Водотоки ∀" "в1" ON "в1".osm_id > "в0".osm_id AND st_intersects("в0".geom, "в1".geom) AND st_geometrytype(st_intersection("в0".geom, "в1".geom)) = 'ST_Point'::text
        )
 SELECT "∀∩"."∩",
    ( SELECT count(*) AS count
           FROM "Павловский парк"."Водотоки ↦" i
          WHERE st_intersects("∀∩"."∩", i."исток")) AS "Истоки",
    ( SELECT count(*) AS count
           FROM "Павловский парк"."Водотоки ⇥" "с"
          WHERE st_intersects("∀∩"."∩", "с"."⇒")) AS "Стоки",
    ( SELECT count(*) AS count
           FROM "Павловский парк"."Водотоки ∀" "в"
          WHERE st_intersects("∀∩"."∩", "в".geom) AND NOT st_intersects("∀∩"."∩", st_endpoint("в".geom)) AND NOT st_intersects("∀∩"."∩", st_startpoint("в".geom))) AS "Примыкания"
   FROM "∀∩"
  ORDER BY "∀∩"."∩";

COMMENT ON VIEW "Павловский парк"."Водотоки ∩" IS 'Все пересечения водотоков';

-- "Павловский парк"."Водотоки вникуда" исходный текст

CREATE OR REPLACE VIEW "Павловский парк"."Водотоки вникуда"
AS SELECT "⇒" "⇏",
    tags ->> 'drain'::text AS drain,
    tags - 'drain'::text AS tags,
    geom,
    "w tags",
    osm_id,
    osm_type,
    dir,
    intermittent::boolean AS intermittent,
    layer,
    waterway,
    tunnel
   FROM "Павловский парк"."Водотоки ⇥"
  WHERE (tags -> 'drain'::text) IS NOT NULL;

COMMENT ON VIEW "Павловский парк"."Водотоки вникуда" IS 'Линейные водотоки, завершение которых помечено как конец течения или растекание по поверхности';

-- "Павловский парк"."Водотоки слияния вникуда" исходный текст

CREATE OR REPLACE VIEW "Павловский парк"."Водотоки слияния вникуда"
AS WITH "ОбластиСтока" AS (
         SELECT st_union("в".geom) AS geom
           FROM "Павловский парк"."Водотоки ∀" "в"
          WHERE "в".geom_type = 'ST_Polygon'::text
        ), "СтокиВникуда" AS (
         SELECT st_union("Водотоки вникуда"."⇏") AS geom
           FROM "Павловский парк"."Водотоки вникуда"
        )
 SELECT b."∩",
    b."Истоки",
    b."Стоки",
    b."Примыкания",
    b."Истоки" + b."Примыкания" AS "∑Истоки",
    b."Стоки" + b."Примыкания" AS "∑Стоки",
    b."Истоки" + b."Стоки" + b."Примыкания" * 2 AS "∑"
   FROM "Павловский парк"."Водотоки ∩" b,
    "ОбластиСтока" o,
    "СтокиВникуда" "св"
  WHERE NOT (b."Истоки" = 1 AND b."Стоки" = 1 AND b."Примыкания" = 0) AND (b."Истоки" + b."Примыкания") = 0 AND NOT st_intersects(b."∩", o.geom) AND NOT (b."Истоки" + b."Стоки" + b."Примыкания" * 2) = 0 AND NOT st_intersects(b."∩", "св".geom);

COMMENT ON VIEW "Павловский парк"."Водотоки слияния вникуда" IS 'Точки где линейные водотоки сливаются и завершаются без пометки о том, что в этой точки конец области стока.';

-- "Павловский парк"."Водотоки слияния вникуда ⇔ geoJSON" исходный текст

CREATE OR REPLACE VIEW "Павловский парк"."Водотоки слияния вникуда ⇔ geoJSON"
AS WITH features AS (
         SELECT json_build_object('type', 'Feature', 'geometry', st_asgeojson(r."∩")::json) AS feature
           FROM "Павловский парк"."Водотоки слияния вникуда" r
        )
 SELECT json_build_object('type', 'FeatureCollection', 'features', json_agg(feature)) AS "GeoJSON"
   FROM features;

COMMENT ON VIEW "Павловский парк"."Водотоки слияния вникуда ⇔ geoJSON" IS 'Формирование файла точек где линейные водотоки водотоки сливаются и завершаются без пометки о том, что в этой точки конец области стока.';

-- "Павловский парк"."Водотоки ∩ не транзит" source

CREATE OR REPLACE VIEW "Павловский парк"."Водотоки ∩ не транзит"
AS SELECT b."∩",
    b."Истоки",
    b."Стоки",
    b."Примыкания",
    b."Истоки" + b."Примыкания" AS "∑Истоки",
    b."Стоки" + b."Примыкания" AS "∑Стоки",
    b."Истоки" + b."Стоки" + b."Примыкания" * 2 AS "∑"
   FROM "Павловский парк"."Водотоки ∩" b
  WHERE NOT (b."Истоки" = 1 AND b."Стоки" = 1 AND b."Примыкания" = 0);


-- "Павловский парк"."Водотоки линейные неподтверждённые" исходный текст

CREATE OR REPLACE VIEW "Павловский парк"."Водотоки линейные неподтверждённые"
AS SELECT osm_id,
    osm_type,
    tags,
    bridge,
    intermittent,
    layer,
    water,
    waterway,
    tunnel,
    geom,
    geom_type,
    name
   FROM "Павловский парк"."Водотоки ∀"
  WHERE (waterway <> ALL (ARRAY['weir'::text, 'stream'::text, 'river'::text])) AND ((tunnel <> ALL (ARRAY['culvert'::text, 'flooded'::text])) OR tunnel IS NULL) AND dir IS NULL;

COMMENT ON VIEW "Павловский парк"."Водотоки линейные неподтверждённые" IS 'Линейные водотоки, у которых не указано подтверждение направления течения. Ручьи и реки не рассматриваются как очевидные.';

-- ПРОБЛЕМА: БЕССТОКОВЫЕ ТОЧКИ

CREATE OR REPLACE VIEW "Павловский парк"."Водотоки ⇏ ✔"
AS SELECT *
   FROM "Павловский парк"."Водотоки ⇥" "т"
   WHERE "т".tags->>'drain' in ('no', 'disperse');
   
COMMENT ON VIEW "Павловский парк"."Водотоки ⇏ ✔" IS 'Размеченные бесстоковые точки (drain=no)';

/*

CREATE OR REPLACE VIEW "Павловский парк"."Водотоки ⇏ ✘"
AS SELECT "т"."⇒" AS "⇏",
    "т".geom,
    "т".tags,
    "п".geom AS "т",
    "п".osm_type,
    "п".osm_id,
    "п".tags AS "⇏ tag"
   FROM "Павловский парк"."Водотоки ⇒" "т"
     LEFT JOIN "Павловский парк"."Водотоки ∀" "в" ON (st_intersects("т"."⇒", "в".geom) OR st_covers("т"."⇒", "в".geom)) AND "т".osm_id <> "в".osm_id
     LEFT JOIN "Павловский парк"."OSM ∀" "п" ON st_covers("т".geom, "п".geom) AND "п".osm_type::text = 'node'::text
  WHERE "в".geom IS NULL AND (("п".tags ->> 'nodrain'::text) <> 'yes'::text OR "п".tags IS NULL);

COMMENT ON VIEW "Павловский парк"."Водотоки ⇏ ✘" IS 'Бесстоковые точки без пометок nodrain=yes.';
*/
