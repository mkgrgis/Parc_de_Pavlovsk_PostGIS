CREATE TABLE public."OSM Павловский парк" (
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
COMMENT ON TABLE public."OSM Павловский парк" IS 'Таблица для Osmium импорта данных, покрывающих Павловский парк. Данные впоследствии фильтруюется по границам парка.';

CREATE TABLE public."WikiMap Павловский парк" (
	r jsonb NOT NULL,
	t timestamptz(0) NOT NULL DEFAULT now(),
	CONSTRAINT "WikiMap_Павловский_парк_pk" PRIMARY KEY (t)
);
COMMENT ON TABLE public."WikiMap Павловский парк" IS 'Данные импорта JSON из карты изображений ВикиСклада в единственную строку.';

-- Специальная схема для производных таблиц и представлений
CREATE SCHEMA "Павловский парк";

CREATE OR REPLACE VIEW "Павловский парк"."Основная граница"
AS SELECT "oпп".tags ->> 'name'::text AS "Название",
    "oпп".tags ->> 'operator'::text AS "Оператор",
    "oпп".osm_id,
    "oпп".geom
   FROM "OSM Павловский парк" "oпп"
  WHERE ("oпп".tags ->> 'leisure'::text) = 'park'::text AND ("oпп".tags ->> 'name'::text) = 'Павловский парк'::text AND ("oпп".tags ->> 'heritage'::text) = '2'::text AND ("oпп".tags ->> 'protection_title'::text) = 'Государственный музей-заповедник'::text;

COMMENT ON VIEW "Павловский парк"."Основная граница" IS 'Фильтр, выделяющий из данных, содержащих Павлвоский парк его границу.';

CREATE MATERIALIZED VIEW "Павловский парк"."OSM ∀"
TABLESPACE pg_default
AS SELECT "oпп".osm_id,
    "oпп".osm_type,
    "oпп".tags,
    st_intersection("ог".geom, "oпп".geom) AS geom
   FROM "OSM Павловский парк" "oпп"
     JOIN "Павловский парк"."Основная граница" "ог" ON st_intersects("ог".geom, "oпп".geom)
WITH DATA;

COMMENT ON MATERIALIZED VIEW "Павловский парк"."OSM ∀" IS 'Все данные, относящиеся к Павловскому парку включая данные на его границах.';

CREATE MATERIALIZED VIEW "Павловский парк"."WikiMap ∀"
TABLESPACE pg_default
AS WITH json_table AS (
         SELECT jsonb_array_elements("wmпп".r) AS json
           FROM "WikiMap Павловский парк" "wmпп"
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
            json_table.json -> 'imahedata'::text AS img
           FROM json_table
        )
 SELECT geobaze.pageid,
    geobaze.title,
    geobaze."φλ₀",
    geobaze."α₀",
    geobaze."f₀",
    geobaze.c,
    geobaze."φλ₁",
    geobaze."α₁",
    geobaze."f₁",
    geobaze.tag,
    geobaze.ns,
    geobaze.u,
    geobaze.img,
    st_collect(st_makeline(geobaze."φλ₀", geobaze."φλ₁"),
        CASE
            WHEN geobaze."f₀" THEN geobaze."φλ₀"
            ELSE NULL::geometry
        END) AS "Vue"
   FROM geobaze
WITH DATA;

COMMENT ON MATERIALIZED VIEW "Павловский парк"."WikiMap ∀" IS 'Все данные по точкам с ВикиСклада';
