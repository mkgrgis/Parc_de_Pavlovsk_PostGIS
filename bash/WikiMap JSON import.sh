#!/bin/bash
# Обновление данных в PostGIS
apiadr="https://wikimap.toolforge.org/api.php?cat=$1&subcats&subcatdepth=8&camera=true&locator=true&allco=true";
echo "$apiadr";
s=$(date '+%s');
f="$2 $s";
wget "$apiadr" -O "$f.json"
if [ "$json" != "[]" ]; then
  json=$(cat "$f.json" | sed "s/'/''/g");
  echo "truncate table \"public\".\"WikiMap $2\";" | psql -e -d "$3";
  echo "insert into \"public\".\"WikiMap $2\" (\"r\") values ('$json');" | psql -d "$3";
  r=$?;
  echo " refresh materialized view \"$2\".\"WikiMap ∀\";" | psql -e -d "$3";
  if [ $r == 0 ]; then
    echo "postgis ✔";
    xz -z -9 "$f.json";  
#    rm -v "$f.json";
  fi;
else
  echo "postgis x";
fi;
