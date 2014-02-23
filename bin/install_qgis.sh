#!/bin/sh
# Copyright (c) 2009 The Open Source Geospatial Foundation.
# Licensed under the GNU LGPL version >= 2.1.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation, either version 2.1 of the License,
# or any later version.  This library is distributed in the hope that
# it will be useful, but WITHOUT ANY WARRANTY, without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU Lesser General Public License for more details, either
# in the "LICENSE.LGPL.txt" file distributed with this software or at
# web page "http://www.fsf.org/licenses/lgpl.html".
#
# About:
# =====
# This script will install Quantum GIS including python and GRASS support,
#  assumes script is run with sudo priveleges.

./diskspace_probe.sh "`basename $0`" begin
BUILD_DIR=`pwd`
####


if [ -z "$USER_NAME" ] ; then
   USER_NAME="user"
fi
USER_HOME="/home/$USER_NAME"

TMP_DIR=/tmp/build_qgis

#CAUTION: UbuntuGIS should be enabled only through setup.sh
#Add repositories
#cp ../sources.list.d/ubuntugis.list /etc/apt/sources.list.d/

#Add signed key for repositorys LTS and non-LTS
#apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 68436DDF
#apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 314DF160

apt-get -q update

#Install packages
## 23feb14 fix for QGis "can't make bookmarks"
apt-get --assume-yes install qgis \
   libqt4-sql-sqlite \
   qgis-common python-qgis python-qgis-common \
   gpsbabel python-rpy2 python-qt4-phonon \
   qgis-plugin-grass qgis-plugin-grass-common grass-doc


if [ $? -ne 0 ] ; then
   echo 'ERROR: Package install failed! Aborting.'
   exit 1
fi


# add pykml needed by qgis-plugin 'geopaparazzi'
wget -c --progress=dot:mega \
   "http://download.osgeo.org/livedvd/data/ossim/pykml_0.1.1-1_all.deb"
dpkg -i pykml_0.1.1-1_all.deb
#rm -rf pykml_0.1.1-1_all.deb

#Install optional packages that some plugins use
apt-get --assume-yes install python-psycopg2 \
   python-gdal python-matplotlib python-qt4-sql \
   libqt4-sql-psql python-qwt5-qt4 python-tk \
   python-sqlalchemy python-owslib python-Shapely

# Install plugins
wget -c --progress=dot:mega \
   "http://aiolos.survey.ntua.gr/gisvm/dev/qgis-osgeolive-plugins_7.9-3_all.deb"
dpkg -i qgis-osgeolive-plugins_7.9-3_all.deb
#rm -rf qgis-osgeolive-plugins_7.9-2_all.deb

#Make sure old qt uim isn't installed
apt-get --assume-yes remove uim-qt uim-qt3

#TODO: Remove this
#apt-get --assume-yes install python-setuptools
#easy_install owslib

#### install desktop icon ####
INSTALLED_VERSION=`dpkg -s qgis | grep '^Version:' | awk '{print $2}' | cut -f1 -d~`
if [ ! -e /usr/share/applications/qgis.desktop ] ; then
   cat << EOF > /usr/share/applications/qgis.desktop
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=Quantum GIS
Comment=QGIS $INSTALLED_VERSION
Categories=Application;Education;Geography;
Exec=/usr/bin/qgis %F
Icon=/usr/share/icons/qgis-icon.xpm
Terminal=false
StartupNotify=false
Categories=Education;Geography;Qt;
MimeType=application/x-qgis-project;image/tiff;image/jpeg;image/jp2;application/x-raster-aig;application/x-mapinfo-mif;application/x-esri-shape;
EOF
else
   sed -i -e 's/^Name=Quantum GIS Desktop/Name=Quantum GIS/' \
      /usr/share/applications/qgis.desktop
fi

cp /usr/share/applications/qgis.desktop "$USER_HOME/Desktop/"
cp /usr/share/applications/qbrowser.desktop "$USER_HOME/Desktop/"
chown -R $USER_NAME.$USER_NAME "$USER_HOME/Desktop/qgis.desktop"
chown -R $USER_NAME.$USER_NAME "$USER_HOME/Desktop/qbrowser.desktop"


# add menu item
if [ ! -e /usr/share/menu/qgis ] ; then
   cat << EOF > /usr/share/menu/qgis
?package(qgis):needs="X11"\
  section="Applications/Science/Geoscience"\
  title="Quantum GIS"\
  command="/usr/bin/qgis"\
  icon="/usr/share/icons/qgis-icon.xpm"
EOF
  update-menus
fi


#Install the Manual and Intro guide locally and link them to the description.html
mkdir /usr/local/share/qgis
wget -c --progress=dot:mega \
        "http://download.osgeo.org/qgis/doc/manual/qgis-1.0.0_a-gentle-gis-introduction_en.pdf" \
	--output-document=/usr/local/share/qgis/qgis-1.0.0_a-gentle-gis-introduction_en.pdf
#TODO: Consider including translations
wget -c --progress=dot:mega \
        "http://docs.qgis.org/2.0/pdf/QGIS-2.0-UserGuide-en.pdf" \
	--output-document=/usr/local/share/qgis/QGIS-2.0-UserGuide-en.pdf

chmod 644 /usr/local/share/qgis/*.pdf


if [ ! -d "$TMP_DIR" ] ; then
   mkdir "$TMP_DIR"
fi
cd "$TMP_DIR"

#Install tutorials
wget --progress=dot:mega \
    "https://github.com/qgis/osgeo-live-qgis-tutorials/tarball/master" \
     --output-document="$TMP_DIR"/tutorials.tgz

tar xzf "$TMP_DIR"/tutorials.tgz -C "$TMP_DIR"

cd "$TMP_DIR"/*osgeo-live-qgis-tutorials*

apt-get --assume-yes install python-sphinx
make html
cp -R _build/html /usr/local/share/qgis/tutorials

# FIXME
# # Install some popular python plugins
# 
# # be careful with 'wget -c', if the file changes on the server the local
# # copy will get corrupted. Wget only knows about filesize, not file 
# # contents, timestamps, or md5sums!
# 
# DATAURL="http://download.osgeo.org/livedvd/data/qgis/qgis-plugins-7.0.tar.gz"
# 
# #TODO use a python script and the QGIS API to pull these within QGIS from online repo
# mkdir -p "$TMP_DIR"/plugins
# 
# wget --progress=dot:mega "$DATAURL" \
#      --output-document="$TMP_DIR"/qgis_plugin.tar.gz
# 
# tar xzf "$TMP_DIR"/qgis_plugin.tar.gz  -C "$TMP_DIR/plugins"
# #cp -R  "$TMP_DIR"/.qgis/python/plugins/ /usr/share/qgis/python/
# cp -R  "$TMP_DIR"/plugins/ /usr/share/qgis/python/
# chmod -R 755 /usr/share/qgis/python


#TODO Include some sample projects using already installed example data
#post a sample somewhere on qgis website or launchpad to pull
cp "$BUILD_DIR/../app-data/qgis/QGIS-Itasca-Example.qgs" /usr/local/share/qgis/
#borked: cp "$BUILD_DIR/../app-data/qgis/QGIS-Grass-Example.qgs" /usr/local/share/qgis/
cp "$BUILD_DIR/../app-data/qgis/QGIS-NaturalEarth-Example.qgs" /usr/local/share/qgis/

chmod 644 /usr/local/share/qgis/*.qgs
#  oi! don't do this:
#chown $USER_NAME.$USER_NAME /usr/local/share/qgis/*.qgs
#Link example to the home directory
ln -s /usr/local/share/qgis "$USER_HOME"/qgis-examples
ln -s /usr/local/share/qgis /etc/skel/qgis-examples


#add a connection for postgis if it's installed
QGIS_CONFIG_PATH="$USER_HOME/.config/QuantumGIS/"

mkdir -p $QGIS_CONFIG_PATH
cp "$BUILD_DIR/../app-conf/qgis/QGIS.conf" "$QGIS_CONFIG_PATH"

chmod 644 "$USER_HOME/.config/QuantumGIS/QGIS.conf"
chown $USER_NAME.$USER_NAME "$USER_HOME/.config/QuantumGIS/QGIS.conf"
# todo: ~/.qgis/ is now unused by us, so can be removed after the freeze
mkdir -p "$USER_HOME/.qgis"
chown -R $USER_NAME.$USER_NAME "$USER_HOME/.qgis"


# set up some extra PostGIS and Spatialite DBs
CONFFILE="$USER_HOME/.config/QuantumGIS/QGIS.conf"
TMPFILE=`tempfile`
USR=user
PSWD=user

DBS="
52nSOS
cartaro
eoxserver_demo
pgrouting
v2.2_mapfishsample"
#disabled: osm_local_smerc

cat << EOF > "$TMPFILE"
[SpatiaLite]
connections\\selected=trento.sqlite
connections\\trento.sqlite\\sqlitepath=/usr/local/share/data/spatialite/trento.sqlite

EOF

cat << EOF >> "$TMPFILE"
[PostgreSQL]
connections\selected=OpenStreetMap
EOF


for DBNAME in $DBS ; do
   cat << EOF >> "$TMPFILE"
connections\\$DBNAME\\service=
connections\\$DBNAME\\host=localhost
connections\\$DBNAME\\database=$DBNAME
connections\\$DBNAME\\port=5432
connections\\$DBNAME\\username=$USR
connections\\$DBNAME\\password=$PSWD
connections\\$DBNAME\\publicOnly=false
connections\\$DBNAME\\allowGeometrylessTables=false
connections\\$DBNAME\\sslmode=1
connections\\$DBNAME\\saveUsername=true
connections\\$DBNAME\\savePassword=true
connections\\$DBNAME\\estimatedMetadata=false
EOF
done

tail -n +3 "$CONFFILE" > "$TMPFILE".b
cat "$TMPFILE" "$TMPFILE".b > "$CONFFILE"
rm -f "$TMPFILE" "$TMPFILE".b

#Apply patch for trac ticket #1208
cp "$BUILD_DIR"/../app-conf/qgis/fix_gdaltools_version.patch /usr/share/qgis/
cd /usr/share/qgis/
patch -p1 < fix_gdaltools_version.patch
rm -f /usr/share/qgis/fix_gdaltools_version.patch
cd "$BUILD_DIR"

####
"$BUILD_DIR"/diskspace_probe.sh "`basename $0`" end
