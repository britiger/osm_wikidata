#!/bin/bash

. ./config 
. ./tools/bash_functions.sh

# delete old cache and diff
rm -rf $cache_dir $diff_dir

# Creating nessesary directories
mkdir -p tmp # for storing last update files
mkdir -p log # logging

# define logfile name
logfile_name=import_`date '+%Y-%m-%d_%H-%M-%S'`.log

# set tool path fot custom osm2pgsql
export PATH=`pwd`/tools/:$PATH

# delete old data
echo_time "Delete old data ..."
rm -f tmp/*

# import data into database
echo_time "Import data from $IMPORT_PBF ..."
imposm import -config config.json -read $IMPORT_PBF -write -connection "postgis://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}?prefix=imposm_" \
  -diff -cachedir $cache_dir -diffdir $diff_dir -dbschema-import imposm3 -deployproduction
# catch exit code of osm2pgsql
RESULT=$?
if [ $RESULT -ne 0 ]
then
	echo_time "imposm3 exits with error code $RESULT."
	exit 1
fi

echo_time "Create basic tables and update triggers"
psql -f sql/createBasicTables.sql > /dev/null
echo_time "Fill table with clustered roads"
psql -f sql/updateClusteredRoads.sql > /dev/null

echo_time "Initial import finished."
