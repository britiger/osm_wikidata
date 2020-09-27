#!/bin/bash

# Use logs from loadWikidata.sh and generate html with errors

. ./config 
. ./tools/bash_functions.sh

invalid_items=./log/invalid_wikidata.log
missing_items=./log/missing_wikidata.log
redirect_items=./log/redirect_wikidata.log

outfile=./log/errors.html

cnt_invalid=`cat $invalid_items | wc -l`
cnt_missing=`cat $missing_items | wc -l`
cnt_redirect=`cat $redirect_items | wc -l`

function write_header() {
    cat > ${outfile} << EOL
<html>
    <head>
        <title>Wikidata Errors in OSM</title>
    </head>
<body>
<h1>Wikidata Errors in OpenStreetMap</h1>
<ul>
    <li>Report generated: $(date)</li>
    <li>Invalid values: ${cnt_invalid}</li>
    <li>Missing Items: ${cnt_missing}</li>
    <li>Redirects: ${cnt_redirect}</li>
</ul>
EOL
}

function write_footer() {
        cat >> ${outfile} << EOL
</body>
</html>
EOL
}

function get_osm() {
    psql -t -X --quiet --no-align -c "select array_to_string(osm_ids,','),name FROM clustered_roads WHERE '$1'=any(wikidata) OR '$1'=any(\"name:etymology:wikidata\")" \
    | while read line
    do
        elements=${line%\|*}
        name=${line#*\|}
        
        echo "<h4>${name}</h4><ul>" >> ${outfile}
        josm_list=
        IFS=',' read -ra elemA <<< $elements
        for elem in "${elemA[@]}"
        do
            if [ ${elem} -lt 0 ]
            then
                josm_list="${josm_list},r${elem:1}"
                echo "<li><a href=\"https://www.openstreetmap.org/relation/${elem:1}\">Relation ${elem:1}</a></li>" >> ${outfile}
            else
                josm_list="${josm_list},w${elem}"
                echo "<li><a href=\"https://www.openstreetmap.org/way/${elem}\">Way ${elem}</a></li>" >> ${outfile}
            fi
        done

        echo "</ul>" >> ${outfile}
        echo "<a href=\"http://localhost:8111/load_object?objects=${josm_list:1}&relation_members=true\">Edit in JOSM</a>" >> ${outfile}
    done
}

function invalid_report() {
    if [ "${cnt_invalid}" -lt 1 ]
    then
        echo_time "Skip Invalid"
        return
    fi

    echo_time "Report Invalid"

    echo "<h2>Invalid Values</h2>" >> ${outfile}

    while read line
    do
        echo "<h3>Value: $line</h3>" >> ${outfile}
        get_osm ${line}
        # to show a process
        echo -n "."
    done < ${invalid_items}
    # to show process
    echo 
}

function redirect_report() {
    if [ "${cnt_redirect}" -lt 1 ]
    then
        echo_time "Skip Redirects"
        return
    fi

    echo_time "Report Redirects"

    echo "<h2>Redirected Values</h2>" >> ${outfile}

    while read line
    do
        from=`echo ${line} | cut -f1 -d" "`
        to=`echo ${line} | cut -f3 -d" "`
        echo "<h3>Value: <a href=\"https://wikidata.org/wiki/$from\">$from</a> (redirects to <a href=\"https://wikidata.org/wiki/$to\">$to</a>)</h3>" >> ${outfile}
        get_osm ${from}
        # to show a process
        echo -n "."
    done < ${redirect_items}
    # to show process
    echo 
}

function missing_report() {
    if [ "${cnt_missing}" -lt 1 ]
    then
        echo_time "Skip Missing"
        return
    fi

    echo_time "Report Missing"

    echo "<h2>Missing Values</h2>" >> ${outfile}

    while read line
    do
        echo "<h3>Value: <a href=\"https://wikidata.org/wiki/$line\">$line</a></h3>" >> ${outfile}
        get_osm ${line}
        # to show a process
        echo -n "."
    done < ${missing_items}
    # to show process
    echo 
}

echo_time "Start generating report with errors"

write_header

invalid_report
redirect_report
missing_report

write_footer

echo_time "Finished"

echo_time "Open $outfile"
