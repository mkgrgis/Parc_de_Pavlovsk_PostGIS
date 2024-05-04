#!/bin/bash
res=$(echo "SELECT \"GeoJSON\", b.\"Название\" from \"Павловский парк\".\"Бассейны geoJSON\" b" | psql -A -t -q );
echo "$res" | while read c; do
	f=$(echo "$c" | cut -f 2 -d '|');
	g=$(echo "$c" | cut -f 1 -d '|');
	echo "$g" > "Басс $f.geojson";
done;
	

