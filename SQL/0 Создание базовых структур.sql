-- Все объекты будут размещены в специальной схеме
CREATE SCHEMA "Павловский парк";

CREATE TABLE "Павловский парк"."∀ osmium" (
	geom geometry NULL,
	osm_type varchar(8) NULL,
	osm_id int8 NULL,
	"version" int4 NULL,
	changeset int4 NULL,
	uid int4 NULL,
	"user" varchar(256) NULL,
	"timestamp" timestamptz(0) NULL,
	way_nodes _int8 NULL,
	tags jsonb NULL
);
COMMENT ON TABLE "Павловский парк"."∀ osmium" IS 'Таблица для Osmium импорта данных, покрывающих Павловский парк. Данные впоследствии фильтруюется по границам парка.';

CREATE OR REPLACE VIEW "Павловский парк"."Основная граница"
AS SELECT "oпп".tags ->> 'name'::text AS "Название",
    "oпп".tags ->> 'operator'::text AS "Оператор",
    "oпп".osm_id,
    "oпп".geom
   FROM "Павловский парк"."∀ osmium" "oпп"
  WHERE ("oпп".tags ->> 'leisure'::text) = 'park'::text AND ("oпп".tags ->> 'name'::text) = 'Павловский парк'::text AND ("oпп".tags ->> 'heritage'::text) = '2'::text AND ("oпп".tags ->> 'protection_title'::text) = 'Государственный музей-заповедник'::text;

COMMENT ON VIEW "Павловский парк"."Основная граница" IS 'Фильтр, выделяющий из данных, содержащих Павловский парк его границу.';


CREATE MATERIALIZED VIEW "Павловский парк"."OSM ∀"
TABLESPACE pg_default
AS SELECT "oпп".osm_id,
    "oпп".osm_type,
    "oпп".tags,
    st_intersection("ог".geom, "oпп".geom) AS geom,
    st_geometrytype(st_intersection("ог".geom, "oпп".geom)) geom_type
   FROM "Павловский парк"."∀ osmium" "oпп"
     JOIN "Павловский парк"."Основная граница" "ог" ON st_intersects("ог".geom, "oпп".geom)
WITH DATA;

COMMENT ON MATERIALIZED VIEW "Павловский парк"."OSM ∀" IS 'Все данные, относящиеся к Павловскому парку включая данные на его границах.';

CREATE OR REPLACE VIEW "Павловский парк"."Районы"
AS SELECT "∀".osm_id,
    "∀".osm_type,
    "∀".tags ->> 'name'::text AS name,
    "∀".tags ->> 'ref'::text AS ref,
    "∀".tags ->> 'int_name'::text AS int_name,
    "∀".geom,
    "∀".tags ->> 'wikidata'::text AS wikidata,
    "∀".tags ->> 'name:fr'::text AS "name:fr",
    "∀".tags ->> 'alt_name:fr'::text AS "alt_name:fr",
    "∀".tags ->> 'name:hy'::text AS "name:hy",
    "∀".tags ->> 'name:az'::text AS "name:az",
    "∀".tags ->> 'name:uk'::text AS "name:uk",
    "∀".tags ->> 'name:zh'::text AS "name:zh",
    "∀".tags - 'ref'::text - 'place'::text - 'name'::text - 'name:fr'::text - 'name:hy'::text - 'name:az'::text - 'name:uk'::text - 'name:zh'::text - 'int_name'::text - 'boundary'::text - 'wikidata'::text - 'alt_name:fr'::text AS tags
   FROM "Павловский парк"."OSM ∀" "∀"
  WHERE "∀".osm_type::text = 'relation'::text AND ("∀".tags ->> 'boundary'::text) = 'protected_area'::text AND ("∀".tags ->> 'ref'::text) IS NOT NULL;

COMMENT ON VIEW "Павловский парк"."Районы ∀" IS 'Традиционно выделяемые парковые районы. Общая граница исключена из выборки.';

CREATE TABLE "Павловский парк"."∀ WikiMap" (
	r jsonb NOT NULL,
	t timestamptz(0) NOT NULL DEFAULT now(),
	CONSTRAINT "WikiMap_Павловский_парк_pk" PRIMARY KEY (t)
);
COMMENT ON TABLE "Павловский парк"."∀ WikiMap" IS 'Данные импорта JSON из карты изображений ВикиСклада в единственную строку.';

CREATE MATERIALIZED VIEW "Павловский парк"."WikiMap ∀"
TABLESPACE pg_default
AS WITH json_table AS (
         SELECT jsonb_array_elements("wmпп".r) AS json
           FROM "Павловский парк"."∀ WikiMap" "wmпп"
        ), geobaze AS (
         SELECT json_table.json ->> 'pageid'::text AS pageid,
            json_table.json ->> 'title'::text AS title,
            st_setsrid(st_point((((json_table.json -> 'coordinates'::text) -> 0) ->> 'lon'::text)::double precision, (((json_table.json -> 'coordinates'::text) -> 0) ->> 'lat'::text)::double precision), 4326) AS "φλ₀",
            (((json_table.json -> 'coordinates'::text) -> 0) ->> 'bearing'::text)::double precision AS "α₀",
            (((json_table.json -> 'coordinates'::text) -> 0) ->> 'primary'::text)::boolean AS "f₀",
            (((json_table.json -> 'coordinates'::text) -> 0) ->> 'cam'::text) IS NOT NULL AS c,
            st_setsrid(st_point((((json_table.json -> 'coordinates'::text) -> 1) ->> 'lon'::text)::double precision, (((json_table.json -> 'coordinates'::text) -> 1) ->> 'lat'::text)::double precision), 4326) AS "φλ₁",
            (((json_table.json -> 'coordinates'::text) -> 1) ->> 'bearing'::text)::double precision AS "α₁",
            (((json_table.json -> 'coordinates'::text) -> 1) ->> 'primary'::text)::boolean AS "f₁",
            json_table.json ->> 'tag'::text AS tag,
            json_table.json ->> 'ns'::text AS ns,
            json_table.json -> 'coordinates'::text AS u,
            json_table.json -> 'imagedata'::text AS img,
            'https://commons.wikimedia.org/wiki/' || (json_table.json ->> 'title'::text) AS "URL"
           FROM json_table
        )
 SELECT geobaze.*,    
        st_collect(st_makeline(geobaze."φλ₀", geobaze."φλ₁"),
        CASE
            WHEN geobaze."f₀" THEN geobaze."φλ₀"
            ELSE NULL::geometry
        END) AS "Vue"
   FROM geobaze
WITH DATA;

COMMENT ON MATERIALIZED VIEW "Павловский парк"."WikiMap ∀" IS 'Все данные по точкам с ВикиСклада';

CREATE TABLE "Павловский парк"."∀ PastVu" (
	r jsonb NOT NULL,
	t timestamptz(0) NOT NULL DEFAULT now(),
	"isPainting" bool NOT NULL,
	CONSTRAINT "PastVu_Павловский_парк_pk" PRIMARY KEY (t)
);

CREATE MATERIALIZED VIEW "Павловский парк"."PastVu ∀"
TABLESPACE pg_default
AS
WITH json_table AS (
         SELECT jsonb_array_elements(p.r -> 'result' ->'photos') AS json,
                p."isPainting"
           FROM "Павловский парк"."∀ PastVu" p
        ), geobaze AS (
        select json_table.json ->> 'cid' "№",
               json_table.json ->> 'title' "Название",
        	   json_table.json ->> 'dir' "dir",
        	   st_setsrid(
        	   	st_point(((json_table.json -> 'geo') ->> 1)::double precision,
        	   	        ((json_table.json -> 'geo') ->> 0)::double precision), 4326) "φλ₀",
        	   --json_table.json ->> 'geo' "",
        	   'https://pastvu.com/_p/a/' || (json_table.json ->> 'file') "URL",
        	   json_table.json ->> '__v' "v",
        	   json_table.json ->> 'year' "от",
        	   json_table.json ->> 'year2' "до",
        	   "isPainting",
        	   json_table.json - 'year2' - 'year' - '__v' - 'file' - 'geo' - 'dir' - 'title' - 'cid'  "json"
          FROM json_table
          )
select * from geobaze
WITH DATA;

CREATE MATERIALIZED VIEW "Павловский парк"."PastVu парк ∀"
TABLESPACE pg_default
as
SELECT p.*,
       st_intersection("ог".geom, p."φλ₀") AS geom,
       st_geometrytype(st_intersection("ог".geom, p."φλ₀")) AS geom_type
  FROM "Павловский парк"."PastVu ∀" p
  JOIN "Павловский парк"."Основная граница" "ог"
    ON st_intersects("ог".geom, p."φλ₀")     
  WITH DATA;
