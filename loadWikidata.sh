#!/bin/bash

. ./config 
. ./tools/bash_functions.sh

wd_cache=./cache_wikidata

mkdir -p $wd_cache

echo_time "Check tables ..."
psql -f sql/createWikiTables.sql > /dev/null
psql -f sql/classifyWikidata.sql > /dev/null

function db_import() {
    wikidata=$1
    cat $wd_cache/${wikidata}.json | sed 's/\\/\\\\/g' | psql -c 'COPY wikidata_import FROM STDIN;'
}

echo_time "Cleanup tables ..."
psql -c "TRUNCATE TABLE wikidata_import;"

echo_time "Search for missing data ..."
psql -t -X --quiet --no-align -c "select wikidata FROM wikidata_needed_import ORDER BY wikidata" \
| while read wikidata
do
    # regex check
    if ! [[ $wikidata =~ ^Q[0-9]+$ ]]
    then
        echo_time "'${wikidata}' is not a valid wikidata entity! Skipped."
        continue
    fi

    echo_time "Check ${wikidata} ..."
    outfile=$wd_cache/${wikidata}.json
    if ! [ -f $outfile ]
    then
        echo_time "Download ..."
        curl -s https://www.wikidata.org/wiki/Special:EntityData/${wikidata}.json -o $outfile
        # TODO: Check for: Rediects
        # TODO: Check for: 404
        RET=$?
        if [ $RET -ne 0 ]
        then
            rm -rf $outfile
        fi
    fi
    if [ -f $outfile ]
    then
        echo_time "Import to db ..."
        db_import ${wikidata}
    fi
done

echo_time "Finish Import ..."
psql -c "INSERT INTO wikidata (wikidataId, data)
SELECT jsonb_object_keys(data->'entities') AS wikidataId, data->'entities'->jsonb_object_keys(data->'entities') AS data
FROM wikidata_import
ON CONFLICT (wikidataId) DO UPDATE 
SET imported=NOW(), data=excluded.data;"
echo_time "Link entities ..."
psql -f sql/classifyFunction.sql > /dev/null
