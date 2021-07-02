#!/bin/bash

. ./config 
. ./tools/bash_functions.sh

echo_time "Calculate needed Tiles ..."
psql -f sql/calculateTiles.sql > /dev/null

echo_time "Start Export ..."
python3 vectortiles/export.py

echo_time "Export Completed."
