Extract POIs from an OSM databse imported with osm2pgsql using the default schema.

Edit the osm2pgsql stylesheet to add these two lines:

```
node,way   school:FR    text         polygon
node,way   station      text         polygon
```

```sh
sudo -n -u postgres -s -- osm2pgsql -d gis -S default.style --extra-attributes mp.osm.bz2 
```

Edit databases.conf with your settings.

```sh
chmod +x install.sh
sudo ./install.sh
chmod +x update_poi.sh
sudo ./update_poi.sh
```
