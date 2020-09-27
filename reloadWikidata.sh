#!/bin/bash

# Reloads wikidata with redirects errors
# TODO: reload more

. ./config 
. ./tools/bash_functions.sh

invalid_items=./log/invalid_wikidata.log
missing_items=./log/missing_wikidata.log
redirect_items=./log/redirect_wikidata.log

function reload_wd() {
    echo_time "Delete $1 from database"
    # delete item
    psql -c "delete from wikidata where wikidataid = '$1'"
    # delete links
    psql -c "delete from wikidata_class_links where wikidataIdClass = '$1' OR wikidataIdEntity = '$1'"
    # delete cache
    rm cache_wikidata/$1.json
}

needLoad=0

echo_time "Start deleting entites which have redirects in wikidata"

while read line
do
    from=`echo ${line} | cut -f1 -d" "`
    to=`echo ${line} | cut -f3 -d" "`

    psql -t -X --quiet --no-align -c "SELECT wikidataSource, wikidataSourceName FROM wikidata_depenencies WHERE wikidataId='${from}'" \
    | while read line
    do
        wikidataId=${line%\|*}
        name=${line#*\|}
        
        echo_time "${wikidataId} has redirect from ${from} to ${to}"
        
        reload_wd ${wikidataId}
        needLoad=1
    done
    echo -n "."
done < ${redirect_items}
echo 

if [ ${needLoad} -eq 1 ]
then
    echo_time "start loading missing wikidata ..."
    ./loadWikidata.sh
fi
