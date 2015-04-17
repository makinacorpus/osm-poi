#!/bin/bash

OSM_MIRROR_CONF=/etc/default/openstreetmap-conf


function echo_step () {
    echo -e "\e[92m\e[1m$1\e[0m"
}

function echo_error () {
    echo -e "\e[91m\e[1m$1\e[0m"
}

source databases.conf

#.......................................................................

echo_step "Creating POI table"
sudo -n -u postgres -s -- psql -d ${POI_DB} -c "CREATE EXTENSION IF NOT EXISTS postgis;"
sudo -n -u postgres -s -- psql -d ${POI_DB} -c "CREATE EXTENSION IF NOT EXISTS dblink;"
sudo -n -u postgres -s -- psql -d ${POI_DB} -c "CREATE TABLE poi (osm_id bigint, geom geometry, name text, category text, type text);"