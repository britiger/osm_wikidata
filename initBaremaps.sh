#!/bin/bash

. ./config 
. ./tools/bash_functions.sh

# SQL
echo_time "Create Tables and Views for baremaps"
psql -f sql/baremaps/init.sql > /dev/null

echo_time "Create Tables and Views for wikidata"
psql -f sql/classifyWikidata.sql > /dev/null
psql -f sql/createWikiTables.sql > /dev/null
psql -f sql/export_eqs.sql > /dev/null

echo_time "Create Views for baremaps tiles with wikidata and replace openstreetmap-vecto views"
psql -f sql/baremaps/newOsmTableViews.sql > /dev/null
psql -f sql/baremaps/replaceViews.sql > /dev/null