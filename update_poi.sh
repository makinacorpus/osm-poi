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
\set VERBOSITY verbose

while IFS=, read category type key value key_exclude value_exclude
do
    echo_substep "${category} -> ${type}    ${key} -> ${value}"
    if [ ! -z "$key_exclude" ]
    then
        if [ ! -z "$value_exclude" ]
        then
            # No polygon may be returned with some tags, e.g. public_transport_stop_position.
            # In this case, the intersection should not be performed to avoid getting empty results.
            sudo -n -u postgres -s -- psql -d ${POI_DB} -c "
                INSERT INTO poi
                SELECT osm_id, geom, name, '${category}', '${type}', '${key}', '${value}'
                FROM dblink('dbname=${OSM_DB}',
                            'WITH simplefeatures AS (
                              SELECT ST_MakePolygon(ST_exteriorring((ST_Dump(way)).geom)) as geom FROM planet_osm_polygon
                              WHERE \"${key}\"=''${value}''
                                AND (\"${key_exclude}\" IS NULL OR \"${key_exclude}\" != ''${value_exclude}'')
                            ), poly AS (
                              SELECT st_collect(geom) as geom, count(geom) FROM simplefeatures
                            )
                            SELECT osm_id, way, name FROM planet_osm_point, poly
                            WHERE \"${key}\"=''${value}''
                            AND (\"${key_exclude}\" IS NULL OR \"${key_exclude}\" != ''${value_exclude}'')
                            AND CASE WHEN count = 0 THEN true ELSE NOT ST_intersects(way,poly.geom) END;')
                      AS t1(osm_id bigint, geom geometry,name text);"
            sudo -n -u postgres -s -- psql -d ${POI_DB} -c "
                INSERT INTO poi
                SELECT osm_id, ST_Centroid(geom), name, '${category}', '${type}', '${key}', '${value}'
                FROM dblink('dbname=${OSM_DB}',
                            'SELECT osm_id, way, name
                            FROM planet_osm_polygon
                            WHERE \"${key}\"=''${value}''
                            AND (\"${key_exclude}\" IS NULL OR \"${key_exclude}\" != ''${value_exclude}'')')
                      AS t1(osm_id bigint, geom geometry,name text);"
        else 
            # No polygon may be returned with some tags, e.g. public_transport_stop_position.
            # In this case, the intersection should not be performed to avoid getting empty results.
            sudo -n -u postgres -s -- psql -d ${POI_DB} -c "
                INSERT INTO poi
                SELECT osm_id, geom, name, '${category}', '${type}', '${key}', '${value}'
                FROM dblink('dbname=${OSM_DB}',
                            'WITH simplefeatures AS (
                              SELECT ST_MakePolygon(ST_exteriorring((ST_Dump(way)).geom)) as geom FROM planet_osm_polygon
                              WHERE \"${key}\"=''${value}''
                                AND (\"${key_exclude}\" IS NULL)
                            ), poly AS (
                              SELECT st_collect(geom) as geom, count(geom) FROM simplefeatures
                            )
                            SELECT osm_id, way, name FROM planet_osm_point, poly
                            WHERE \"${key}\"=''${value}''
                            AND (\"${key_exclude}\" IS NULL)
                            AND CASE WHEN count = 0 THEN true ELSE NOT ST_intersects(way,poly.geom) END;')
                      AS t1(osm_id bigint, geom geometry,name text);"
            sudo -n -u postgres -s -- psql -d ${POI_DB} -c "
                INSERT INTO poi
                SELECT osm_id, ST_Centroid(geom), name, '${category}', '${type}', '${key}', '${value}'
                FROM dblink('dbname=${OSM_DB}',
                            'SELECT osm_id, way, name
                            FROM planet_osm_polygon
                            WHERE \"${key}\"=''${value}''
                            AND (\"${key_exclude}\" IS NULL)')
                      AS t1(osm_id bigint, geom geometry,name text);"
        fi
    else
        # No polygon may be returned with some tags, e.g. public_transport_stop_position.
        # In this case, the intersection should not be performed to avoid getting empty results.
        sudo -n -u postgres -s -- psql -d ${POI_DB} -c "
            INSERT INTO poi
            SELECT osm_id, geom, name, '${category}', '${type}', '${key}', '${value}'
            FROM dblink('dbname=${OSM_DB}',
                        'WITH simplefeatures AS (
                          SELECT ST_MakePolygon(ST_exteriorring((ST_Dump(way)).geom)) as geom FROM planet_osm_polygon
                          WHERE \"${key}\"=''${value}''
                        ), poly AS (
                          SELECT st_collect(geom) as geom, count(geom) FROM simplefeatures
                        )
                        SELECT osm_id, way, name FROM planet_osm_point, poly
                        WHERE \"${key}\"=''${value}''
                        AND CASE WHEN count = 0 THEN true ELSE NOT ST_intersects(way,poly.geom) END;')
                  AS t1(osm_id bigint, geom geometry,name text);"
        sudo -n -u postgres -s -- psql -d ${POI_DB} -c "
            INSERT INTO poi
            SELECT osm_id, ST_Centroid(geom), name, '${category}', '${type}', '${key}', '${value}'
            FROM dblink('dbname=${OSM_DB}',
                        'SELECT osm_id, way, name
                        FROM planet_osm_polygon
                        WHERE \"${key}\"=''${value}''')
                  AS t1(osm_id bigint, geom geometry,name text);"
    fi
done < features.conf
