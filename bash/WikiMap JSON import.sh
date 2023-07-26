#!/bin/bash
# Обновление данных в PostGIS
[ ! -f 'postgres.url' ] && echo "pg url?" && exit;
pgurl=$(cat 'postgres.url');
apiadr="https://wikimap.toolforge.org/api.php?cat=$1&subcats&subcatdepth=8&camera=true&locator=true&allco=true";
echo "$apiadr";
s=$(date '+%s');
f="$2 $s";
wget "$apiadr" -O "$f.json"
if [ "$json" != "[]" ]; then
  json=$(cat "$f.json" | sed "s/'/''/g");
  echo "truncate table \"$2\".\"∀ WikiMap\";" | psql -e "$pgurl";
  echo "insert into \"$2\".\"∀ WikiMap\" (\"r\") values ('$json');" | psql "$pgurl";
  r=$?;
  echo " refresh materialized view \"$2\".\"WikiMap ∀\";" | psql -e "$pgurl";
  if [ $r == 0 ]; then
    echo "postgis ✔";
    xz -z -9 "$f.json";  
#    rm -v "$f.json";
  fi;
else
  echo "postgis x";
fi;
