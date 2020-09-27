#!/bin/bash

# Export data geojosn and csv for project equalstreetnames

. ./config 
. ./tools/bash_functions.sh

export_dir=./export_data/equalstreetnames

mkdir -p $export_dir

if [ $# -ne 1 ]
then
    echo_time "Please add an Relation id of as city for export data"
    exit 1
fi

relation_id=$1

if [ ${relation_id:0:1} != '-' ]
then
    relation_id="-${relation_id}"
fi

relation_name=`psql -t -A -c "SELECT name FROM imposm_admin WHERE osm_id=${relation_id}" 2>/dev/null`
if [ -z "${relation_name}" ]
then
    echo_time "Relation Id ${relation_id} not available."
    exit 2
fi

echo_time "Create database functions ..."
psql -f sql/export_eqs.sql > /dev/null
psql -f sql/buildGeojson.sql > /dev/null
echo_time "Export $export_dir/${relation_name}_gender.csv ..."
cat sql/export_eqs_gender.sql | sed -e "s/##RELATION##/${relation_id}/g" | psql -q > $export_dir/${relation_name}_gender.csv
echo_time "Export $export_dir/${relation_name}_all.csv ..."
cat sql/export_eqs_all.sql | sed -e "s/##RELATION##/${relation_id}/g" | psql -q > $export_dir/${relation_name}_all.csv
echo_time "Export $export_dir/${relation_name}_other.csv ..."
cat sql/export_eqs_other.sql | sed -e "s/##RELATION##/${relation_id}/g" | psql -q > $export_dir/${relation_name}_other.csv

echo_time "Export $export_dir/${relation_name}_export.geojson ..."
cat sql/export_eqs_geojson.sql | sed -e "s/##RELATION##/${relation_id}/g" | psql -q | sed 's/\\\\/\\/g' > $export_dir/${relation_name}_export.geojson
