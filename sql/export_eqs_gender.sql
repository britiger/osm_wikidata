SET client_min_messages TO WARNING;

-- CSV for gender.csv
COPY (SELECT name, eqsGetGender("name:etymology:wikidata") AS gender, array_to_string("name:etymology:wikidata",',') AS wikidata, 'way' AS "type"
FROM clustered_roads 
WHERE st_within(geom,(SELECT geometry FROM imposm_admin WHERE osm_id=##RELATION##))
    AND eqsGetGender("name:etymology:wikidata") IS NOT NULL
    AND eqsIsHuman("name:etymology:wikidata")
ORDER BY name) TO STDOUT CSV header;
