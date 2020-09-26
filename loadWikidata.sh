#!/bin/bash

. ./config 
. ./tools/bash_functions.sh

wd_cache=./cache_wikidata

invalid_items=./log/invalid_wikidata.log
missing_items=./log/missing_wikidata.log
redirect_items=./log/redirect_wikidata.log

mkdir -p $wd_cache

echo_time "Check tables ..."
psql -f sql/createWikiTables.sql > /dev/null
psql -f sql/classifyWikidata.sql > /dev/null

function db_import() {
    wikidata=$1
    cat $wd_cache/${wikidata}.json | sed 's/\\/\\\\/g' | psql -c 'COPY wikidata_import FROM STDIN;'
}

function import_run() {
    echo_time "Cleanup tables ..."
    psql -c "TRUNCATE TABLE wikidata_import;"

    # clean missing / redirect
    > ${invalid_items}
    > ${missing_items}
    > ${redirect_items}

    echo_time "Search for missing data ..."
    psql -t -X --quiet --no-align -c "select wikidata FROM wikidata_needed_import ORDER BY wikidata" \
    | while read wikidata
    do
        # regex check
        if ! [[ $wikidata =~ ^Q[0-9]+$ ]]
        then
            echo_time "'${wikidata}' is not a valid wikidata entity! Skipped."
            echo "${wikidata}" >> ${invalid_items}
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
                rm -f $outfile
            fi
        fi
        if [ -f $outfile ]
        then
            # Check for: Rediects
            file_id=`jq -r '.entities | keys[0]' $outfile 2> /dev/null`
            file_id_ret=$?
            if [ $file_id_ret -ne 0 ]
            then
                if grep -q "Not Found" $outfile
                then
                    echo_time "Entity $wikidata not found, maybe deleted or invalid"
                    echo "$wikidata" >> ${missing_items}
                fi
                echo_time "Reset cache"
                rm -f $outfile
                continue
            fi
            if [ "$file_id" != "$wikidata" ]
            then
                echo_time "Found Redirect $wikidata => $file_id"
                echo "$wikidata => $file_id" >> ${redirect_items}
                rm -f $outfile
                continue
            fi
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

    results=`psql -t -X --quiet --no-align -c "SELECT count(*) FROM wikidata_import"`
    return $results
}

RET=1
while [ "$RET" -ne 0 ]
do
    import_run
    RET=$?
    if [ "$RET" -ne 0 ]
    then
        echo_time "Rerun for dependencies"
    fi
done

echo_time "Link entities ..."
psql -f sql/classifyFunction.sql > /dev/null
