#!/bin/bash

. ./config 
. ./tools/bash_functions.sh

wd_cache=./cache_wikidata

mkdir -p $wd_cache

psql -t -X --quiet --no-align -c "select unnest(wikidata) AS wikidata from clustered_roads WHERE wikidata IS NOT NULL 
 UNION 
 select unnest(\"name:etymology:wikidata\") AS wikidata from clustered_roads WHERE \"name:etymology:wikidata\" IS NOT NULL;" \
 | while read wikidata
 do
    # TODO: regex check Q123456789

    echo_time "Fetch or update $wikidata ..."
    outfile=$wd_cache/${wikidata}.json
    if ! [ -f $outfile ]
    then
        curl -s https://www.wikidata.org/wiki/Special:EntityData/${wikidata}.json -o $outfile
        RET=$?
        if [ $RET -ne 0 ]
        then
            rm -rf $outfile
        else
            # TODO: Import to db
            echo_time "Import to db"
        fi
    fi
 done