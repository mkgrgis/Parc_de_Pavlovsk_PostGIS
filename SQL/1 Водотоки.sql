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
    geom
   FROM "Павловский парк"."OSM ∀" ∀ 
  WHERE (tags ->> 'waterway'::text) IS NOT NULL AND (tags ->> 'waterway'::text) <> 'dam'::text OR (tags ->> 'water'::text) IS NOT NULL OR (tags ->> 'natural'::text) = 'water'::text OR (tags ->> 'natural'::text) = 'wetland'::text;

COMMENT ON VIEW "Павловский парк"."Водотоки ∀" IS 'Все данные по водотокам в Павловском парке';

-- ПРОБЛЕМА: БЕССТОКОВЫЕ ТОЧКИ

CREATE OR REPLACE VIEW "Павловский парк"."Водотоки ⇏ ✔"
AS SELECT "т"."⇒" AS "⇏",
    "т".geom,
    "т".tags,
    "п".geom AS "т",
    "п".osm_type,
    "п".osm_id,
    "п".tags AS "✔⇏ tag"
   FROM "Павловский парк"."Водотоки ⇒" "т"
     LEFT JOIN "Павловский парк"."Водотоки ∀" "в" ON (st_intersects("т"."⇒", "в".geom) OR st_covers("т"."⇒", "в".geom)) AND "т".osm_id <> "в".osm_id
     JOIN "Павловский парк"."OSM ∀" "п" ON st_covers("т".geom, "п".geom) AND "п".osm_type::text = 'node'::text AND ("п".tags ->> 'nodrain'::text) = 'yes'::text
  WHERE "в".geom IS NULL;

COMMENT ON VIEW "Павловский парк"."Водотоки ⇏ ✔" IS 'Размеченные бесстоковые точки (nodrain=yes)';

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

-- Экспорт неразмеченных водотоков
CREATE OR REPLACE VIEW "Павловский парк"."Водотоки ⇏ ✘ geoJSON" AS
WITH features AS (
         SELECT json_build_object('type', 'Feature', 'geometry', st_asgeojson(r."⇏")::json) feature
           FROM "Павловский парк"."Водотоки ⇏ ✘" r
        )
 SELECT json_build_object('type', 'FeatureCollection', 'features', json_agg(feature)) "GeoJSON"
   FROM features;
   
-- ПРОБЛЕМА: БИФУРКАЦИИ

CREATE OR REPLACE VIEW "Павловский парк"."Водотоки бифуркации"
AS SELECT st_intersection("и1".geom, "и2".geom) AS "∩",
    st_intersection("и1"."исток", "и2"."исток") AS "бифуркация",
    "и1".geom AS "водоток1",
    "и2".geom AS "водоток2"
   FROM "Павловский парк"."Водотоки истоки" "и1"
     JOIN "Павловский парк"."Водотоки истоки" "и2" ON st_intersects("и1"."исток", "и2"."исток") AND "и1".osm_id < "и2".osm_id;

CREATE OR REPLACE VIEW "Павловский парк"."Бифуркации geoJSON"
AS WITH features AS (
         SELECT json_build_object('type', 'Feature', 'geometry', st_asgeojson(r."бифуркация")::json) AS feature
           FROM "Павловский парк"."Водотоки бифуркации" r
        )
 SELECT json_build_object('type', 'FeatureCollection', 'features', json_agg(features.feature)) AS "GeoJSON"
   FROM features;

-- ОБЗОР: СЛИЯНИЯ ВОДОТОКОВ

CREATE OR REPLACE VIEW "Павловский парк"."Водотоки ⇒"
AS SELECT st_endpoint("в".geom) AS "⇒",
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
   FROM "Павловский парк"."Водотоки ∀" "в"
  WHERE geometrytype("в".geom) = 'LINESTRING'::text AND (("в"."natural" <> ALL (ARRAY['water'::text, 'wetland'::text])) OR "в"."natural" IS NULL);

COMMENT ON VIEW "Павловский парк"."Водотоки ⇒" IS 'Точки стока всех водотоков';

CREATE OR REPLACE VIEW "Павловский парк"."Водотоки ⇒×2"
AS SELECT st_intersection("т1"."⇒", "т2"."⇒") AS "2⇒",
    st_union("т1".geom, "т2".geom) AS st_union,
    "т1".tags AS t1,
    "т2".tags AS t2,
    "в".geom AS "∑"
   FROM "Павловский парк"."Водотоки ⇒" "т1"
   JOIN "Павловский парк"."Водотоки ⇒" "т2"
     ON st_covers("т1"."⇒", "т2"."⇒") AND "т1".osm_id > "т2".osm_id
   LEFT JOIN "Павловский парк"."Водотоки ∀" "в"
     ON NOT st_covers(st_endpoint("в".geom), st_intersection("т1"."⇒", "т2"."⇒"))
    AND st_intersects("в".geom, "т1"."⇒")
    AND st_intersects("в".geom, "т2"."⇒")
    AND "в".osm_id <> "т2".osm_id
    AND "в".osm_id <> "т1".osm_id
  ORDER BY "в".geom NULLS FIRST;

COMMENT ON VIEW "Павловский парк"."Водотоки ⇒×2" IS 'Точки слияния двух (и более) водотоков';

-- ОБЗОР: ПЕРЕСЕЧЕНИЯ ВОДОТОКОВ

CREATE OR REPLACE VIEW "Павловский парк"."Водотоки ∩×2"
AS SELECT st_intersection(w0.geom, "∀".geom) AS "∩×2",
    st_union(w0.geom, "∀".geom) AS "∪×2",
    w0.tags AS w0t,
    "∀".tags AS w1t,
    w0.dir AS w0d,
    "∀".dir AS w1d,
    w0.osm_id AS w0id,
    "∀".osm_id AS w1id,
    w0.geom AS w0g,
    "∀".geom AS w1g
   FROM "Павловский парк"."Водотоки ∀" w0
   JOIN "Павловский парк"."Водотоки ∀" "∀" ON w0.osm_id < "∀".osm_id AND st_intersects("∀".geom, w0.geom);
   
   CREATE OR REPLACE VIEW "Павловский парк"."Водотоки ∩×3"
AS SELECT st_intersection(w0."∩×2", "∀".geom) AS "∩×3",
    st_union(w0."∪×2", "∀".geom) AS "∪×3",
    w0.w0t,
    w0.w1t,
    "∀".tags AS w2t,
    w0.w0d,
    w0.w1d,
    "∀".dir AS w2d,
    w0.w0id,
    w0.w1id,
    "∀".osm_id AS w2id,
    w0.w0g,
    w0.w1g,
    "∀".geom AS w2g
   FROM "Павловский парк"."Водотоки ∩×2" w0
     JOIN "Павловский парк"."Водотоки ∀" "∀" ON w0.w0id < "∀".osm_id AND w0.w1id < "∀".osm_id AND st_touches(w0."∩×2", "∀".geom);
     
CREATE OR REPLACE VIEW "Павловский парк"."Водотоки ∩×4"
AS SELECT st_intersection(w0."∩×3", "∀".geom) AS "∩×4",
    st_union(w0."∪×3", "∀".geom) AS "∪×4",
    w0.w0t,
    w0.w1t,
    w0.w2t,
    "∀".tags AS w3t,
    w0.w0d,
    w0.w1d,
    w0.w2d,
    "∀".dir AS w3d,
    w0.w0id,
    w0.w1id,
    w0.w2id,
    "∀".osm_id AS w3id,
    w0.w0g,
    w0.w1g,
    w0.w2g,
    "∀".geom AS w3g
   FROM "Павловский парк"."Водотоки ∩×3" w0
     JOIN "Павловский парк"."Водотоки ∀" "∀" ON w0.w0id < "∀".osm_id AND w0.w1id < "∀".osm_id AND w0.w2id < "∀".osm_id AND st_touches(w0."∩×3", "∀".geom);

COMMENT ON VIEW "Павловский парк"."Водотоки ∩×4" IS 'Точки четверного (и большего) схождения водотоков';
