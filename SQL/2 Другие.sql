-- "Павловский парк"."ДТС 0" source

CREATE OR REPLACE VIEW "Павловский парк"."ДТС 0"
AS SELECT st_union(a.geom) AS geom,
    a.tags ->> 'name'::text AS "Название"
   FROM "Павловский парк"."OSM ∀" a
  WHERE (a.tags ->> 'highway'::text) IS NOT NULL
  GROUP BY (a.tags ->> 'name'::text);

-- "Павловский парк"."ДТС" source

CREATE OR REPLACE VIEW "Павловский парк"."ДТС"
AS SELECT
        CASE
            WHEN geometrytype("д".geom) = 'POLYGON'::text THEN st_exteriorring("д".geom)
            ELSE "д".geom
        END AS geom,
    "д"."Название",
    round(st_length(
        CASE
            WHEN geometrytype("д".geom) = 'POLYGON'::text THEN st_exteriorring("д".geom)
            ELSE "д".geom
        END::geography)::numeric, 1) AS l,
    st_asgeojson("д".geom) AS "GeoJSON"
   FROM "Павловский парк"."ДТС 0" "д"
  ORDER BY "д"."Название";

-- "Павловский парк"."Дороги" source

CREATE OR REPLACE VIEW "Павловский парк"."Дороги"
AS SELECT a.osm_id,
    a.osm_type,
    a.geom,
    a.tags ->> 'name'::text AS name,
    a.tags ->> 'highway'::text AS highway,
    a.tags ->> 'surface'::text AS surface,
    a.tags ->> 'width'::text AS width,
    a.tags ->> 'note'::text AS "заметки",
    a.tags ->> 'description'::text AS "описание",
    a.tags - 'highway'::text - 'surface'::text - 'width'::text - 'note'::text - 'description'::text AS tags
   FROM "Павловский парк"."OSM ∀" a
  WHERE (a.tags ->> 'highway'::text) IS NOT NULL AND (a.tags ->> 'highway'::text) <> 'street_lamp'::text AND (a.tags ->> 'highway'::text) <> 'steps'::text;


-- "Павловский парк"."Здания" source

CREATE OR REPLACE VIEW "Павловский парк"."Здания"
AS SELECT a.osm_id,
    a.osm_type,
    a.geom,
    a.tags ->> 'name'::text AS name,
    a.tags ->> 'building'::text AS building,
    a.tags ->> 'height'::text AS height,
    st_area(a.geom) AS "площадь",
    a.tags ->> 'note'::text AS "заметки",
    a.tags ->> 'description'::text AS "описание",
    a.tags - 'building'::text - 'name'::text - 'height'::text - 'note'::text - 'description'::text AS tags
   FROM "Павловский парк"."OSM ∀" a
  WHERE (a.tags ->> 'building'::text) IS NOT NULL;


-- "Павловский парк"."Лестницы" source

CREATE OR REPLACE VIEW "Павловский парк"."Лестницы"
AS SELECT a.osm_id,
    a.osm_type,
    a.geom,
    a.tags ->> 'name'::text AS name,
    a.tags ->> 'highway'::text AS highway,
    a.tags ->> 'surface'::text AS surface,
    a.tags ->> 'width'::text AS width,
    a.tags ->> 'note'::text AS "заметки",
    a.tags ->> 'description'::text AS "описание",
    a.tags - 'highway'::text - 'surface'::text - 'width'::text - 'note'::text - 'description'::text AS tags
   FROM "Павловский парк"."OSM ∀" a
  WHERE (a.tags ->> 'highway'::text) IS NOT NULL AND (a.tags ->> 'highway'::text) = 'steps'::text;


-- "Павловский парк"."Мосты" source

CREATE OR REPLACE VIEW "Павловский парк"."Мосты"
AS SELECT a.osm_id,
    a.osm_type,
    a.geom,
    a.tags ->> 'name'::text AS name,
    a.tags ->> 'name:fr'::text AS "Nome francaise",
    st_area(a.geom) AS "площадь",
    a.tags ->> 'note'::text AS "заметки",
    a.tags ->> 'description'::text AS "описание",
    a.tags ->> 'ref:okn'::text AS "ОКН",
    a.tags ->> 'start_date'::text AS "Построено",
    a.tags ->> 'heritage'::text AS "Вс. насл. уровень",
    a.tags ->> 'heritage:website'::text AS "Сайт",
    a.tags ->> 'architect'::text AS "Архитектор",
    a.tags ->> 'bridge:structure'::text AS "Структура",
    a.tags ->> 'addr:housenumber'::text AS "Дом",
    a.tags ->> 'addr:street'::text AS "Улица",
    a.tags ->> 'website'::text AS "URL",
    a.tags - 'name'::text - 'note'::text - 'description'::text - 'man_made'::text - 'name:fr'::text - 'ref:okn'::text - 'start_date'::text - 'heritage'::text - 'heritage:website'::text - 'layer'::text - 'architect'::text - 'bridge:structure'::text - 'addr:housenumber'::text - 'addr:street'::text - 'website'::text AS tags,
    a.tags ->> 'layer'::text AS l
   FROM "Павловский парк"."OSM ∀" a
  WHERE (a.tags ->> 'man_made'::text) = 'bridge'::text;


-- "Павловский парк"."Посадки" source

CREATE OR REPLACE VIEW "Павловский парк"."Посадки"
AS SELECT a.osm_id,
    a.osm_type,
    a.geom,
    (string_to_array(a.tags ->> 'taxon'::text, ';'::text))[1] AS taxon,
    (string_to_array(a.tags ->> 'taxon:ru'::text, ';'::text))[1] AS "вид",
    (string_to_array(a.tags ->> 'genus'::text, ';'::text))[1] AS genus,
    (string_to_array(a.tags ->> 'genus:ru'::text, ';'::text))[1] AS "род",
    (string_to_array(a.tags ->> 'taxon'::text, ';'::text))[2] AS "taxon+",
    (string_to_array(a.tags ->> 'taxon:ru'::text, ';'::text))[2] AS "вид+",
    (string_to_array(a.tags ->> 'genus'::text, ';'::text))[2] AS "genus+",
    (string_to_array(a.tags ->> 'genus:ru'::text, ';'::text))[2] AS "род+",
    a.tags ->> 'natural'::text AS "тип посадки",
    a.tags ->> 'leaf_cycle'::text AS "листопадность",
    a.tags ->> 'leaf_type'::text AS "листва",
    st_area(a.geom) AS "площадь",
    a.tags ->> 'note'::text AS "заметки",
    a.tags ->> 'description'::text AS "описание",
    a.tags - 'taxon'::text - 'taxon:ru'::text - 'genus'::text - 'genus:ru'::text - 'source:taxon'::text - 'natural'::text - 'leaf_cycle'::text - 'leaf_type'::text - 'note'::text - 'description'::text AS tags
   FROM "Павловский парк"."OSM ∀" a
  WHERE (a.tags ->> 'natural'::text) IS NOT NULL AND ((a.tags ->> 'natural'::text) = ANY (ARRAY['wood'::text, 'tree'::text, 'scrub'::text, 'shurb'::text]));
