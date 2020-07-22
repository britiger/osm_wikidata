#!/bin/bash

. ./config 
. ./tools/bash_functions.sh

wd_cache=./cache_wikidata

mkdir -p $wd_cache

psql -f sql/createWikiTables.sql > /dev/null

function db_import() {
    wikidata=$1
    cat $wd_cache/${wikidata}.json | sed 's/\\/\\\\/g' | psql -c 'COPY wikidata_import FROM STDIN;'
}

psql -c "TRUNCATE TABLE wikidata_import;"

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
