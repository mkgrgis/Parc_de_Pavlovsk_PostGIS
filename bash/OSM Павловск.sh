#!/bin/bash
# Обновление данных в PostGIS по всей территории Павловского парка и Мариенталя
$(dirname "$0")'/OSM Osmium import.sh' '59.676538598055224,30.431184768676758,59.70876380776066,30.49152374267578' 'Павловский парк' 'master' 'master';
