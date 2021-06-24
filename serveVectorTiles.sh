#!/bin/bash

# Serve VectorTiles

. ./config 
. ./tools/bash_functions.sh

psql -f sql/export_eqs.sql
psql -f sql/vectorTilesViews.sql

python3 vectortiles/server.py
