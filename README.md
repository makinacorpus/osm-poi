Extract POIs from an OSM databse imported with osm2pgsql using the default schema.

Edit databases.conf

postgis and dblink extensions must be enabled on your POI database.

chmod +x install.sh
sudo ./install.sh
chmod +x update_poi.sh
sudo ./update_poi.sh
