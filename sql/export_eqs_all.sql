-- CSV for all.csv (new)
COPY (SELECT name, 
    eqsGetGender("name:etymology:wikidata") AS gender,
    eqsIsHuman("name:etymology:wikidata") AS IsHuman,
    array_to_string("name:etymology:wikidata",',') AS etymology, 
    string_agg(DISTINCT class_name, ', ') AS classification,
    array_to_string(cr.wikidata,',') AS wikidata
FROM clustered_roads AS cr
    LEFT JOIN wikidata_class_links AS wcl ON wcl.wikidataIdEntity=ANY("name:etymology:wikidata")
    LEFT JOIN wikidata_classes AS wdc ON wcl.wikidataIdClass=wdc.wikidataId AND wcl.wikidataProperty=ANY(found_in)
WHERE st_within(geom,(SELECT geometry FROM imposm_admin WHERE osm_id=##RELATION##))
GROUP BY name, gender, etymology, wikidata, IsHuman
ORDER BY name) TO STDOUT CSV header;
