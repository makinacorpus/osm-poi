#!/bin/bash

OSM_MIRROR_CONF=/etc/default/openstreetmap-conf


function echo_step () {
    echo -e "\e[92m\e[1m$1\e[0m"
}

function echo_substep () {
    echo -e "\e[94m\e[1m$1\e[0m"
}

function echo_error () {
    echo -e "\e[91m\e[1m$1\e[0m"
}

source databases.conf

#.......................................................................

echo_step "Insert POIs "

sudo -n -u postgres -s -- psql -d ${POI_DB} -c "
    DELETE FROM poi;"

while IFS=, read key value category type
do
    echo_substep "${category} -> ${type}"
    sudo -n -u postgres -s -- psql -d ${POI_DB} -c "
        INSERT INTO poi
        SELECT geom, name, '${category}', '${type}'
        FROM dblink('dbname=${OSM_DB}',
                    'WITH poly AS (
                      SELECT st_collect(way) as geom FROM planet_osm_polygon
                      WHERE ${key}=''${value}''
                    )
                    SELECT way, name FROM planet_osm_point, poly
                    WHERE ${key}=''${value}''
                    AND NOT ST_intersects(way,poly.geom)')
              AS t1(geom geometry,name text);"
    sudo -n -u postgres -s -- psql -d ${POI_DB} -c "
        INSERT INTO poi
        SELECT ST_Centroid(geom), name, '${category}', '${type}'
        FROM dblink('dbname=${OSM_DB}',
                    'SELECT way, name FROM planet_osm_polygon WHERE ${key}=''${value}''')
              AS t1(geom geometry,name text);"
done < features.conf
