#!/bin/bash
# Обновление данных в PostGIS по блоку скачиваемых данных
cd $(dirname "$0");
bbox="$1";
pwd;
apiadr="https://overpass-api.de/api/interpreter?data=";
apiadr="$apiadr[out:xml];(++node($bbox);<;);(._;>;);out+meta;";
echo "$apiadr";
s=$(date '+%s');
f="$2 $s";
#wget "$apiadr" -O - -o /dev/null > "$f.osm";
wget "$apiadr" -O "$f.osm";
osmium export --no-progress --config='osmium.conf' -f pg "$f.osm" -o "$f.pg" && echo "osmium ✔";
echo -n "PostGIS geom: "$(wc -l "$f.pg")" ";
echo "truncate table \"$2\".\"∀ osmium\";" | psql -e -d "$3" -U "$4";
echo "\\copy \"$2\".\"∀ osmium\" FROM '$f.pg';" | psql -e -d "$3" -U "$4";
r=$?;
echo " refresh materialized view \"$2\".\"OSM ∀\";" | psql -e -d "$3" -U "$4";
if [ $r == 0 ]; then
  echo "postgis ✔";
  xz -z -9 "$f.osm";
  [ -f "$f.osm" ] && rm -v "$f.osm";
  rm -v "$f.pg";
  echo "osm.xz ✔";
fi;
