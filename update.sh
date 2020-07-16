#!/bin/bash

. ./config
. ./tools/bash_functions.sh

# define logfile name
logfile_name=update_`date '+%Y-%m-%d_%H-%M-%S'`_$1.log

# Check already running
if [ "$(pidof -x $(basename $0))" != $$ ]
then
        echo_time "Update is already running"
        exit
fi

# find osmupdate
export PATH=`pwd`/tools/:$PATH
oupdate=`which osmupdate 2> /dev/null`
oconvert=`which osmconvert 2> /dev/null` # needed by osmupdate

# Creating tmp-directory for updates
mkdir -p tmp

# if not find compile
if [ -z "$oupdate" ]
then
	echo_time "Try to complie osmupdate ..."
	wget -O - http://m.m.i24.cc/osmupdate.c | cc -x c - -o tools/osmupdate
	if [ ! -f tools/osmupdate ]
	then
		echo_time "Unable to compile osmupdate, please install osmupdate into \$PATH or in tools/ directory."
		exit
	fi
fi
if [ -z "$oconvert" ]
then
	echo_time "Try to complie osmconvert ..."
	wget -O - http://m.m.i24.cc/osmconvert.c | cc -x c - -lz -O3 -o tools/osmconvert
	if [ ! -f tools/osmconvert ]
	then
		echo_time "Unable to compile osmconvert, please install osmconvert into \$PATH or tools/ directory."
		exit
	fi
fi

if [ -f tmp/old_update.osc.gz ]
then
	# 2nd Update
	osmupdate -v $osmupdate_parameter tmp/old_update.osc.gz tmp/update.osc.gz
else
	# 1st Update using dump
	osmupdate -v $osmupdate_parameter $IMPORT_PBF tmp/update.osc.gz
fi

# catch exit code of osmupdate
RESULT=$?
if [ $RESULT -ne 0 ]
then
	echo_time "osmupdate exits with error code $RESULT."
	exit 1
fi

imposm diff -config config.json -connection "postgis://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}?prefix=imposm_" \
           -cachedir $cache_dir -diffdir $diff_dir tmp/update.osc.gz
RESULT=$?
if [ $RESULT -ne 0 ]
then
	echo_time "imposm3 exits with error code $RESULT."
	exit 1
fi
mv tmp/update.osc.gz tmp/old_update.osc.gz

echo_time "Update table with clustered roads"
psql -f sql/updateClusteredRoads.sql > /dev/null

echo_time "Update completed."
