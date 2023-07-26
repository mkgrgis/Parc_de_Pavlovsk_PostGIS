#!/bin/bash
# Обновление данных в PostGIS
[ ! -f 'postgres.url' ] && echo "pg url?" && exit;
pgurl=$(cat 'postgres.url');

lat_min=$(echo "$1" | cut -d ',' -f 1);
lon_min=$(echo "$1" | cut -d ',' -f 2);
lat_max=$(echo "$1" | cut -d ',' -f 3);
lon_max=$(echo "$1" | cut -d ',' -f 4);

echo "$lon_min - $lon_max"
echo "$lat_min - $lat_max"
paint='false';
apiadr="https://pastvu.com/api2?method=photo.getByBounds&params={\"z\":18,\"localWork\":true,\"isPainting\":$paint,\"geometry\":{\"type\":\"Polygon\",\"coordinates\":[[[$lon_min,$lat_min],[$lon_max,$lat_min],[$lon_max,$lat_max],[$lon_min,$lat_max],[$lon_min,$lat_min]]]}}";
echo "$apiadr";
s=$(date '+%s');
f="$2 $s";
wget "$apiadr" -O "PastVu $f.json"
if [ "$json" != "[]" ]; then
  json=$(cat "PastVu $f.json" | sed "s/'/''/g");
  echo "truncate table \"$2\".\"∀ PastVu\";" | psql -e "$pgurl";
  echo "insert into \"$2\".\"∀ PastVu\" (\"r\", \"isPainting\") values ('$json', $paint);" | psql "$pgurl";
  r=$?;
  echo " refresh materialized view \"$2\".\"PastVu ∀\";" | psql -e "$pgurl";
  if [ $r == 0 ]; then
    echo "postgis ✔";
    xz -z -9 "PastVu $f.json";  
#    rm -v "PastVu $f.json";
  fi;
else
  echo "postgis x";
fi;

paint='true';
apiadr="https://pastvu.com/api2?method=photo.getByBounds&params={\"z\":18,\"localWork\":true,\"isPainting\":$paint,\"geometry\":{\"type\":\"Polygon\",\"coordinates\":[[[$lon_min,$lat_min],[$lon_max,$lat_min],[$lon_max,$lat_max],[$lon_min,$lat_max],[$lon_min,$lat_min]]]}}";
echo "$apiadr";
s=$(date '+%s');
f="$2 $s";
wget "$apiadr" -O "PastVu $f.json"
if [ "$json" != "[]" ]; then
  json=$(cat "PastVu $f.json" | sed "s/'/''/g");
  echo "insert into \"$2\".\"∀ PastVu\" (\"r\", \"isPainting\") values ('$json', $paint);" | psql "$pgurl";
  r=$?;
  echo " refresh materialized view \"$2\".\"PastVu ∀\";" | psql -e "$pgurl";
  echo " refresh materialized view \"$2\".\"PastVu парк ∀\";" | psql -e "$pgurl";
  if [ $r == 0 ]; then
    echo "postgis ✔";
    xz -z -9 "PastVu $f.json";  
#    rm -v "PastVu $f.json";
  fi;
else
  echo "postgis x";
fi;
